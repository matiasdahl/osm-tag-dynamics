output_graphviz_file <- function(filename, e_am, e_live, df, copyright=T) {

    q0 <- function(str) paste0('"', str, '"')

    copyright_text <- ifelse(copyright, paste0(
        '\\n\\n\\n\\n',
        'For further details: http://matiasdahl.iki.fi/2015/finding-related-amenity-tags-on-the-openstreetmap',
        '\\n\\n',
        'Contains information from the OpenStreetMap project (http://openstreetmap.org), © OpenStreetMap contributors.\n',
        'The OpenStreetMap data is available under the Open Database License (http://www.openstreetmap.org/copyright).\\n\\n'),
        '')

    red_threshold <- 0.50
    red_color <- '"#D73732"'
    top_nr_to_circle <- 50

    total_ratio <- function(am_name) {
        tot_out <- sum(filter(df, from == am_name)$transition_count)
        tot_entries <- e_am$total_count_for(am_name)
        return(tot_out/tot_entries)
    }

    #  List of amenity tag names that will appear on the graph
    amenities_to_draw <- unique(c(df$from, df$to))

    #
    #  Find those top n amenities (with their counts and rank) that should
    #  be circled. Find counts and normalize to 0..1. These
    #  will be needed for determining the sizes of circles/fonts.
    #
    circle_data <- e_live$live_am_table %>%
        select(amenity_type, count, rank) %>%
        filter(rank <= top_nr_to_circle) %>%
        filter(amenity_type %in% amenities_to_draw) %>%
        select(amenity_type, count)

    if (nrow(circle_data) > 0) {
        circle_data$norm_count <- sqrt(circle_data$count)
        circle_data$norm_count <- circle_data$norm_count - min(circle_data$norm_count)
        circle_data$norm_count <- circle_data$norm_count / max(circle_data$norm_count)
    }

    normalized_count <- function(am_name) {
        tb <- filter(circle_data, amenity_type == am_name)
        stopifnot(nrow(tb) == 1)
        return(tb$norm_count)
    }

    circle_radius <- function(am_name) (6.5 * normalized_count(am_name) + 1.5)

    circle_fontsize <- function(am_name) (30 + 9.75 * normalized_count(am_name))

    #  --- end of circle code ---

    sink(filename)

    cat('digraph OSM_tags { \n',
        '	 rankdir = LR; repulsiveforce = 0; \n',
        '    labelloc = "b"; \n',
        '    splines=true; esep=1; sep=1; nodesep=0.4;\n',
        '    label = ', q0(copyright_text), ';\n',
        '    fontsize = 30; fontname=Helvetica; \n',
        '	 autosize = true; \n\n\n')

    #
    #  Define characteristics for nodes (=the amenity tags) in graph
    #
    for (am in amenities_to_draw) {

        write_label <- function(am_name, label_text, more_options) {
            cat(q0(am_name),
                ' [label = ', label_text,
                ' fontname=Helvetica ',
                paste(more_options, collapse = ' '),
                ']\n'
            )
        }

        if (am %in% circle_data$amenity_type) {
            # amenity name should be circled
            write_label(am,
                        q0(paste0(e_live$rank_for(am), ".\\n\\n ",
                                  am, "\\n\\n ",
                                  human_number(e_live$count_for(am)))),
                        c('fontsize=', circle_fontsize(am),
                          'shape=circle',
                          'style=filled',
                          paste0('fontcolor=',
                                 ifelse(total_ratio(am) > red_threshold,
                                        red_color,
                                        '"#444444"')),
                          'penwidth=0',
                          paste0('width=', circle_radius(am)),
                          paste0('fillcolor="#eeeeee"')))
        } else {
            # ordinary label will do:
            text_color <- ifelse(total_ratio(am) > red_threshold,
                                 red_color,
                                 '"#444444"')
            am_live_counts <- e_live$count_for(am)
            am_live_rank <- ifelse(am_live_counts == 0,
                                   "",
                                   paste0(e_live$rank_for(am), ". "))
            write_label(am,
                        q0(paste0(am_live_rank, am,
                                  "\\n \\n(",
                                  human_number(e_am$total_count_for(am)),
                                  '→',
                                  human_number(am_live_counts),
                                  ")")),
                        c('fontsize=30',
                          paste0('fontcolor=', text_color),
                          'shape=plaintext'))
        }
    }

    #  arrows between nodes
    for (r in 1:nrow(df)) {
        from_amenity <- df[[r, "from"]]
        to_amenity <- df[[r, "to"]]
        tcr <- df[[r, "leave_ratio"]]

        cat(q0(from_amenity),
            ' -> ',
            q0(to_amenity),
            ' [fontname=Helvetica fontsize=30 label=',
            q0(percent0(tcr)),
            ifelse(tcr > red_threshold,
                   paste0('color=', red_color, 'fontcolor=', red_color, ' penwidth=1.5'),
                   'color="#444444" fontcolor="#444444" penwidth=1.5'
            ),
            '] \n ')
    }

    cat('}\n')
    sink()
}
