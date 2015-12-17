#
#  Return data frame with columns:
#
#         ----------------------------
#         |  amenity_type  |  count  |
#         |  (string)      |  (int)  |
#         ----------------------------
#
#  The values in the `amenity_type` column are guaranteed to be unique,
#  and they list all the `amenity=..`-tag values that have *ever* been
#  in use. For each amenity_type, the `count` column records the total
#  number of map elements that have *ever* had the tag. Rows are ordered
#  in descending order wrt. to `count`.
#
#  The result does not include a row for `amenity_type` = "". This tag
#  value appears in the input data for deleted map elements and for
#  elements where the amenity-tag has been removed. This may be the case
#  if an `amenity=..`-tag is retagged into another class, say, into a
#  `building=..`.
#
total_amenity_counts <- function(amenities) {
    return(amenities %>%
               select(unique_id, amenity_type) %>%
               filter(amenity_type != '') %>%
               group_by(amenity_type) %>%
               summarize(count = n_distinct(unique_id)) %>%
               ungroup() %>%
               arrange(desc(count)) %>%
               select(amenity_type, count))
}

#
#  Read amenity data, remove unneeded columns and return an environment
#  with data for tag transition analysis
#
load_amenity_data <- function(am_data_directory) {

    res <- new.env()

    #
    #   Data frame `df`:
    #
    #    - Load the exported amenity data outputted from the
    #      osm-export-amenities script. See:
    #         https://github.com/matiasdahl/osm-extract-amenities
    #    - add `unique_id` column that uniquely identifies a map element
    #    - retain the below columns. These are the only ones needed in the
    #      tag-transition analysis:
    #
    # --------------------------------------------------------------------
    # |  unique_id  |  version  |  sec1970  |  amenity_type  |  visible  |
    # |  (string)   |  (int)    |  (int)    |  (string)      |  (bool)   |
    # --------------------------------------------------------------------
    #
    res$df <- (function(data_dir) {
        amenities <- load_amenities_cached(am_data_directory)
        amenities$unique_id <- paste0(substr(as.character(amenities$type), 1, 1),
                                      amenities$id)
        return(amenities %>%
                   select(unique_id, version, sec1970, amenity_type, visible))
    })(am_data_directory)

    #
    #  Summary of amenity data:
    #
    #  .. total number of unique map elements (n123, w123, n1000, ...)
    #     that have ever had an `amenity=..` tag.
    #
    res$total_nr_amenity_elements <- length(unique(res$df$unique_id))


    #  .. total number of unique amenity types (`bench`, `park_bench`,
    #     `Parkbench`, ...)
    #
    res$total_nr_amenity_tags <- length(unique(res$df$amenity_type))

    #  .. see the above function
    #
    res$total_am_table <- total_amenity_counts(res$df)

    #
    #  Return the total number of map elements that have ever been tagged
    #  with `am_type`. Aborts if `am_name` has never been used.
    #
    res$total_count_for <- function(am_name) {
        tb <- filter(res$total_am_table, amenity_type == am_name)
        assert(nrow(tb) == 1)
        assert(tb$count>0)
        return(tb$count)
    }

    ###
    ###  ----- do some consistency tests -----
    ###
    assert(nrow(res$df) > 0)
    am_0 <- res$total_am_table$amenity_type
    assert(length(am_0) > 0)
    assert(length(am_0) == length(unique(am_0)))
    ###
    ###  -----------------------------
    ###

    return(res)
}
