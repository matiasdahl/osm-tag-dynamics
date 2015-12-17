compute_tag_transitions <- function(e_am) {

    res <- new.env()

    #
    #  Return a data frame of the form:
    #
    #      -----------------------------------------
    #      |  unique_id  |  from      |  to        |
    #      |  (string)   |  (string)  |  (string)  |
    #      -----------------------------------------
    #
    #  with columns listing all tag transitions per map element.
    #  Delete actions are not included. Similarly, transitions
    #  to/from the ''-amenity tag are neither included.
    #
    res$transitions <- (function(e_am) {
        e_am$df %>%
            select(unique_id, amenity_type, version, visible) %>%
            filter(amenity_type != "") %>%
            # The next line should be redundant; visible=FALSE
            # entries usually have no tags.
            filter(visible == TRUE) %>%
            group_by(unique_id) %>%
            arrange(version) %>%
            mutate(next_type = lead(amenity_type)) %>%
            filter(row_number() < n()) %>%
            filter(amenity_type != next_type) %>%
            ungroup() %>%
            select(unique_id,
                   from = amenity_type,
                   to = next_type)
    })(e_am)

    #
    #  Total number of retag actions
    #
    res$total_nr_retag_actions <- nrow(res$transitions)

    #
    #  Total number of elements that have at some point been retagged
    #
    res$nr_elements_that_have_changed_tag <-
        length(unique(res$transitions$unique_id))

    #
    #  Compute the distribution of tag edits per map element. The result has
    #  the format:
    #
    #      ----------------------------------------------------
    #      |  'Number of tag edits'  |  `Unique map elements` |
    #      |  (int)                  |  (int)                 |
    #      ----------------------------------------------------
    #
    #   For the full data (as of 8/2015), the first row reads: 1, 178038.
    #   This indicates that 178038 map elements have changed tag precisely
    #   once. (The distribution is not normalized.)
    #
    res$retag_table <- (function() {
        retags_per_element <- res$transitions %>%
            group_by(unique_id) %>%
            summarize(retags = n()) %>%
            ungroup()
        retag_table <- as.data.frame(table(retags_per_element$retags)) %>%
            select(`Number of tag edits` = Var1,
                   `Unique map elements` = Freq)
        ### tests:
        assert(sum(retag_table$`Unique map elements`)
               == res$nr_elements_that_have_changed_tag)
        #
        return(retag_table)
    })()

    #
    #  Return data frame of type:
    #
    #      ------------------------------------------------
    #      |  from      |  to        |  transition_count  |
    #      |  (string)  |  (string)  |  (int)             |
    #      ------------------------------------------------
    #
    #  For each pair (`from`, `to`), the `transition_count` column
    #  contains the number of *unique* map elements that have been
    #  retagged from `amenity=(from value)` to `amenity=(to value)`.
    #
    #  Values in the `transition_count` column are guaranteed to be >= 1.
    #
    res$transition_counts <- (function(transitions) {
        transitions %>%
            select(from, to, unique_id) %>%
            group_by(from, to) %>%
            summarize(transition_count = n_distinct(unique_id)) %>%
            ungroup() %>%
            arrange(desc(transition_count)) %>%
            select(from, to, transition_count)
    })(res$transitions)

    # ###
    assert(nrow(res$transitions) > 0)
    assert(all(res$transition_count > 0))

    # Elements may move back and forth between two tags. Therefore we do
    # not need to have equality in the below test.
    assert(sum(res$transition_count$transition_count) <= nrow(res$transitions))
    # ---

    return(res)
}
