#
# Without the below, dplyr's `inner_join` will treat
# 'string1' and '\177string1' as the same string.
#
Sys.setlocale("LC_ALL", 'C')

assert <- function(b) return(stopifnot(b))

source('load_amenities.R')
source('number_formatting.R')

require('knitr')
require('ggplot2')
require('scales')
require('lubridate')
require('dplyr')

#  Determine input and output directories. The input directory should
#  contain the files:
#
#     amenities-nodes.txt
#     amenities-ways.txt
#     amenities-relations.txt
#
args <- commandArgs(TRUE)
if (length(args) == 0) {
  input_directory <- "~/temp-data/"
  output_directory <- "../web-site/"
} else if (length(args) == 2) {
  input_directory <- args[1]
  output_directory <- args[2]
} else {
  cat('Wrong number of arguments!\n')
  quit()
}
cat('Reading OSM data from', input_directory, '\n')
cat('Writing web-site data to', output_directory, '\n')

cat(' - Loading e_am ...\n')
#
#  Load amenity data and compute total amenity counts per `amenity_type`
#
source('amenity_counts.R')
e_am <- cache_op(paste0(input_directory, 'all_amenity_data.rds'),
                 function() {
                    load_amenity_data(input_directory)
                })

#
#  Find amenity map elements on the current map
#
cat(' - Loading e_live ...\n')
source('live_count.R')
e_live <- cache_op(paste0(input_directory, 'amenities_live.rds'),
                 function() { get_live_amenities(e_am) })

#
#  Compute tag transitions from amenity data
#
cat(' - Loading e_tr ...\n')
source('tag_transitions.R')
e_tr <- cache_op(paste0(input_directory, 'transition_data.rds'),
                 function() { compute_tag_transitions(e_am) })

cat(' - Extending e_tr ...\n')

source('extend_transition_counts.R')
e_tr$extend_transition_counts <- extend_transition_counts(e_am, e_live, e_tr)

e_tr$leave_ratio_for <- function(a_tag, b_tag) {
   tmp <- e_tr$extend_transition_counts %>%
       filter(from == a_tag, to == b_tag)
   assert(nrow(tmp) == 1)
   return(tmp$leave_ratio)
}

### ------

cat(' - Select tags to export ... \n')
df <- e_live$live_am_table %>% filter(rank <= 100)

cat(' - Writing ', output_directory, 'am_data.txt ...\n')
sink(paste0(output_directory, 'am_data.txt'))
for (i in 1:nrow(df)) {
   am_row <- df[i, "amenity_type"]
   am_count <- human_number(df[i, "count"])
   am_rank <- df[i, "rank"]
   cat(paste0(am_row, '|', am_count, '|', am_rank, '\n'))
}
sink()

#
#  The below corresponds to the code for generating Graph 4 in
#
#     http://matiasdahl.iki.fi/2015/finding-related-amenity-tags-on-the-openstreetmap
#
extract_one <- function(e_am, e_live, e_tr, am_name, n_tre, leaveratio_treshold) {
   df1 <- e_tr$extend_transition_counts %>%
       filter(from == am_name) %>%
       filter(transition_count >= n_tre) %>%
       filter(leave_ratio > leaveratio_treshold)
   df2 <- e_tr$extend_transition_counts %>%
       filter(to == am_name) %>%
       filter(transition_count >= n_tre) %>%
       filter(leave_ratio > leaveratio_treshold)
   rbind(df1, df2)
}

source('graphviz_output.R')
cat(' - Creating images in ', output_directory, ' ...\n')

write_svg <- function(am_name, tmp_df) {
  am_filename_svg <- paste0('osm-', am_name, '.svg')
  am_filename_svg <- sub(';', '\\;', am_filename_svg, fixed=T)
  cat('    ', output_directory, am_filename_svg, '\n', sep = '')
  output_graphviz_file('temp.gv', e_am, e_live, tmp_df, copyright=F)
  system(paste0('dot -Tsvg temp.gv > ', output_directory, 'images/', am_filename_svg))
  system(paste0('rm temp.gv'))
}


for (i in as.numeric(rownames(df))) {
   am_name <- df$amenity_type[i]

   n_threshold = 5
   lr_threshold = ifelse(e_live$count_for(am_name) > 500000, 5.0/100, 1.0/100)

   tmp <- extract_one(e_am, e_live, e_tr, am_name, n_threshold, lr_threshold)

   if (e_live$count_for(am_name) > 500000) {
      while(nrow(tmp) > 60) {
        n_threshold <- n_threshold + 1
        tmp <- extract_one(e_am, e_live, e_tr, am_name, n_threshold, lr_threshold)
      }
   }
   #cat ('    Reduced to ', n_threshold, '  rows:', nrow(tmp), '\n')
   write_svg(am_name, tmp)
}

cat(' - Done.\n')
