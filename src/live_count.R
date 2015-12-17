#
#  Find the latest versions from a data frame with amenity data.
#  Map elements that are currently deleted are not returned.
#
#  Input should have columns:
#
#          --------------------------------------------------------
#          |  unique_id  |  version  |  amenity_type  |  visible  |
#          |  (string)   |  (int)    |  (string)      |  (bool)   |
#          --------------------------------------------------------
#
#  Output data frame:
#
#          -------------------------------------------------
#          |  unique_id  |  amenity_type  |  last_visible  |
#          |  (string)   |  (string)      |  (bool=TRUE)   |
#          -------------------------------------------------
#
#  Note: In the output data frame, the `amenity_type` string may
#  be an empty string.
#
#  Also used in diff_plot.R
#
live_amenities <- function(amenities) {
    return(amenities %>%
               select(unique_id, version, amenity_type, visible) %>%
               group_by(unique_id) %>%
               arrange(version) %>%
               summarize(last_visible = last(visible),
                         last_amenity = last(amenity_type)) %>%
               ungroup() %>%
               filter(last_visible == TRUE) %>%
               select(unique_id,
                      amenity_type = last_amenity,
                      last_visible))
}

get_live_amenities <- function(e_am) {

    res <- new.env()

    res$df <- live_amenities(e_am$df)

    #
    #  Return data frame with columns:
    #
    #         --------------------------------------
    #         |  amenity_type  |  count  |  rank   |
    #         |  (string)      |  (int)  |  (int)  |
    #         --------------------------------------
    #
    #  This is the similar as e_am$total_am_table.
    #  However, it only considers the latest versions of entries that
    #  are currently visible (= that are not deleted). In addition,
    #  the `rank` column gives the rank of each (live) amenity.
    #
    res$live_am_table <- total_amenity_counts(res$df) %>%
        mutate(rank = dense_rank(desc(count))) %>%
        select(amenity_type, count, rank)

    #
    #  Get the live rank of an amenity. Aborts if the amenity is
    #  not live.
    #
    res$rank_for <- function(am_name) {
        tb <- filter(res$live_am_table,
                     amenity_type == am_name)
        assert(nrow(tb) == 1)
        return(tb$rank)
    }

    #
    #  Returns the total number of map elements that are currently
    #  tagged with an amenity-tag. Returns 0 if no element uses the
    #  tag.
    #
    res$count_for <- function(am_name) {
        tb <- filter(res$live_am_table,
                     amenity_type == am_name)
        assert(nrow(tb) <= 1)
        return(ifelse(nrow(tb) == 0,
                      0,
                      tb$count))
    }

    #
    #  Get the top `max_rank` amenities on the current map
    #
    #  Note that the length of the return value (a vector) need
    #  not be `max_rank`. This can happen if two tags have the
    #  same rank.
    #
    res$top_live_amenity_types <- function(max_rank) {
        tmp <- res$live_am_table %>%
            filter(rank <= max_rank)
        return(tmp$amenity_type)
    }

    #
    #  Count the unique map elements (n123, w123, n1000, ...)
    #  on the current map
    #
    res$nr_of_unique_map_elements <- length(unique(res$df$unique_id))

    #
    #  Count the number of amenity-tags used by at least `n` map
    #  elements on the current map
    #
    res$nr_of_amenity_tags <- function(used_by_at_least = 1) {
        tmp <- res$live_am_table %>%
            filter(count >= used_by_at_least)
        return(nrow(tmp))
    }

    ###
    assert(nrow(res$live_am_table) > 0)

    return(res)
}
