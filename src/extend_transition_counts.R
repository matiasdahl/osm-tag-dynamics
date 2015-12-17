#
#   The `e_tr$transition_counts` has three columns:
#
#       ------------------------------------------------
#       |  from      |  to        |  transition_count  |
#       |  (string)  |  (string)  |  (int)             |
#       ------------------------------------------------
#
#   Extend this with columns:
#
#     from_tot_count:  Total number of map elements that have ever
#                      been tagged with the `from` tag.
#
#     from_live_count: Total number of map elements on the current
#                      map that are tagged with the `from` tag. Is
#                      zero if `from`-tag is not currently live.
#
#     from_outflux:    Total number of distinct map elements that
#                      have transitioned from the `from` field at
#                      some point in the OSM history.
#
#     leave_ratio:     = transition_count/from_outflux.
#                      See the write-up.
#
#   The result has one row for each (from, to)-pair.
#
extend_transition_counts <- function(e_am, e_live, e_tr) {

    # Add `from_tot_count` column
    #
    # Recall: e_am$total_am_table has columns `amenity_type`, `count`.
    # For example `bench`, 123 indicates that there are 123 map elements
    # that have *ever* used the `bench` tag.
    #
    res <- e_tr$transition_counts %>%
        inner_join(y = e_am$total_am_table %>%
                       rename(from_tot_count = count),
                   by = c('from' = 'amenity_type'))

    res$from_live_count <- as.vector(sapply(res$from, e_live$count_for))

    # Create outflux data frame with columns: `from` and `out_flux`.
    outflux <- e_tr$transitions %>%
        group_by(from) %>%
        summarize(from_outflux = n_distinct(unique_id)) %>%
        ungroup()
    assert(setequal(outflux$from, res$from))
    res <- res %>% inner_join(y = outflux, by = c('from'))

    res <- res %>%
        mutate(leave_ratio = transition_count/from_outflux) %>%
        mutate(abs_leave_ratio = transition_count/from_tot_count) %>%
        select(from, from_tot_count, from_live_count, from_outflux,
               to, transition_count, leave_ratio, abs_leave_ratio)

    ##
    ##  Tests
    ##
    assert(nrow(res) == nrow(e_tr$transition_counts))
    assert(setequal(res$from, e_tr$transition_counts$from))
    assert(setequal(res$to, e_tr$transition_counts$to))
    assert(setequal(res$transition_count, e_tr$transition_counts$transition_count))
    assert(all(res$leave_ratio <= 1.0))
    assert(all(res$leave_ratio >= 0.0))
    ##  -----

    return(res)
}
