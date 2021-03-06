#' @importFrom rlang %|%
#'
#' @export
cni_auc <- function(dataset, model) {
  regulators <- dataset$regulators
  targets <- dataset$targets
  cell_ids <- dataset$cell_ids

  # evaluate static NI
  regulatory_network <-
    dataset$regulatory_network %>%
    mutate(gold = 1L) %>%
    rename(gold_strength = strength, gold_effect = effect)

  eval_static_static <- with(
    model$regulatory_network %>%
      left_join(regulatory_network, by = c("regulator", "target")) %>%
      mutate(gold = gold %|% 0L, gold_strength = gold_strength %|% 0, gold_effect = gold_effect %|% 0L) %>%
      as_tibble(),
    {
      GENIE3bis::evaluate_ranking_direct(
        values = strength,
        are_true = gold,
        num_positive_interactions = nrow(regulatory_network),
        num_possible_interactions = length(regulators) * length(targets)
      )
    }
  )
  static_static_auc <- eval_static_static$area_under[c("auroc", "aupr")]

  # evaluate casewise NI
  regulatory_network_sc <-
    dataset$regulatory_network_sc %>%
    mutate(gold = 1L) %>%
    rename(gold_strength = strength)

  casewise_casewise_auc <- map_df(
    cell_ids,
    function(cell_id) {
      gold_sc <- regulatory_network_sc %>%
        filter(cell_id == !!cell_id)
      reg_sc <-
        model$regulatory_network_sc %>%
        filter(cell_id == !!cell_id) %>%
        mutate(strength = strength + runif(n(), 0, 1e-8))

      eval_sc <- with(
        reg_sc %>%
          left_join(gold_sc, by = c("cell_id", "regulator", "target")) %>%
          mutate(gold = gold %|% 0L, gold_strength = gold_strength %|% 0) %>%
          as_tibble(),
        {
          GENIE3bis::evaluate_ranking_direct(
            values = strength,
            are_true = gold,
            num_positive_interactions = nrow(gold_sc),
            num_possible_interactions = length(regulators) * length(targets)
          )
        }
      )
      eval_sc$area_under %>% mutate(cell_id) %>% select(cell_id, everything())
    }
  )
  static_casewise_auc <- map_df(
    cell_ids,
    function(cell_id) {
      gold_sc <- regulatory_network_sc %>%
        filter(cell_id == !!cell_id)
      reg_sc <-
        model$regulatory_network

      eval_sc <- with(
        reg_sc %>%
          left_join(gold_sc, by = c("regulator", "target")) %>%
          mutate(gold = gold %|% 0L, gold_strength = gold_strength %|% 0) %>%
          as_tibble(),
        {
          GENIE3bis::evaluate_ranking_direct(
            values = strength,
            are_true = gold,
            num_positive_interactions = nrow(gold_sc),
            num_possible_interactions = length(regulators) * length(targets)
          )
        }
      )

      eval_sc$area_under %>% mutate(cell_id) %>% select(cell_id, everything())
    }
  )

  eval <- bind_rows(
    static_casewise_auc %>% mutate(method = "static_casewise"),
    static_static_auc %>% mutate(method = "static_static"),
    casewise_casewise_auc %>% mutate(method = "casewise_casewise")
  )

  # ggplot(eval) + geom_point(aes(auroc, aupr, colour = method))

  list(
    cc_auroc = mean(casewise_casewise_auc$auroc),
    cc_aupr = mean(casewise_casewise_auc$aupr),
    sc_auroc = mean(static_casewise_auc$auroc),
    sc_aupr = mean(static_casewise_auc$aupr),
    evals = list(eval)
  )
}
