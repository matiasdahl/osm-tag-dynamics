#
#  Return number of unique elements in a vector
#
uniques <- function(v) length(unique(v))

#
#  Return number of NAs in a vector
#
NAs <- function(v) sum(is.nan(v))

#
#  Convert 'sec1970' column into date object
#
from_epoch <- function(sec1970) {
    return(as.Date(as.POSIXct(sec1970, origin = "1970-01-01")))
}

#
#  Load one output file from the extract-amenities.js script
#
load_amenity_file <- function(fname) {

    #
    #  The sed command removes escaped control characters before reading
    #  the file into R according to:
    #
    #    '\t' -> ' ',      '\r' -> ' ',      '\n' -> ' '
    #
    #  The 'allowEscape=TRUE' parameter will correctly parse escaped
    #  quotes. Real tabs (sep = "\t") are used to separate columns.
    #  All columns are kept as characters and converted manually.
    #
    reg_exp <- "'s/\\\\t/ /g;s/\\\\n/ /g;s/\\\\r/ /g'"
    df <- read.csv(
        pipe(paste0('cat ', fname, ' | sed -e ', reg_exp)),
        header = TRUE,
        sep = "\t",
        quote = "",
        #nrow = 100000,     # limit rows when debugging
        colClasses = 'character',
        allowEscapes = TRUE)

    #
    #  Before converting columns into suitable column types, the below
    #  performs some assertions. These should give some assurance that
    #  the 'read.csv' command read all columns into their correct place.
    #
    stopifnot(NAs(as.numeric(df$id)) == 0)
    stopifnot(NAs(as.integer(df$version)) == 0)
    stopifnot(NAs(as.integer(df$sec1970)) == 0)
    stopifnot(uniques(df$visible) == 2) # = 'true' and 'false'

    df$version = as.integer(df$version)
    df$sec1970 = as.integer(df$sec1970)
    df$visible = as.logical(df$visible)

    return(df)
}

#
#  Load all amenities from the output directory of the
#  'extract-amenities' script.
#
load_amenities <- function(output_dir) {
    location_of <- function(fn) return(paste0(output_dir, fn))

    nodes <- load_amenity_file(location_of("amenities-nodes.txt"))
    nodes$type <- rep('node', nrow(nodes))

    ways <- load_amenity_file(location_of("amenities-ways.txt"))
    ways$type <- rep('way', nrow(ways))

    relations <- load_amenity_file(location_of("amenities-relations.txt"))
    relations$type <- rep('relation', nrow(relations))

    amenities <- rbind(nodes, ways, relations)
    amenities$type <- as.factor(amenities$type)

    return(amenities)
}

#
#  Helper function to cache results from computationally expensive
#  operations.
#
cache_op <- function(cache_filename, f) {
    if (file.exists(cache_filename)) {
        return(readRDS(cache_filename))
    }
    result <- f()
    saveRDS(result, cache_filename, compress = FALSE)
    return(result)
}

#
#  Load all amenities with caching
#
load_amenities_cached <- function(output_dir) {
    cache_filename <- paste0(output_dir, 'amenities.cache')
    return(cache_op(cache_filename, function() {
        return(load_amenities(output_dir))
    }))
}

