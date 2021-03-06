library(tidyverse)
library(dyngen.manuscript)

exp <- start_analysis("usecase_rna_velocity_b2b")

design_datasets <- read_rds(exp$result("design_datasets.rds"))
design_velocity <- read_rds(exp$result("design_velocity.rds"))

#' @examples
#' design_velocity %>% dynutils::extract_row_to_list(16) %>% list2env(.GlobalEnv)
# file.remove(exp$result("scores_individual.rds"))
# file.remove(exp$result("scores_aggregated.rds"))

# Calculate scores -----
scores <- exp$result("scores_individual.rds") %cache% {
  pmap_dfr(
    design_velocity,
    function(method_id, params_id, dataset_id, ...) {
      if (!file.exists(exp$dataset_file(dataset_id))) return(NULL)
      dataset <- read_rds(exp$dataset_file(dataset_id))
      groundtruth_velocity <- dataset$rna_velocity
      # groundtruth_velocity[groundtruth_velocity == 0] <- runif(sum(groundtruth_velocity == 0), -1e-10, 1e-10)

      velocity_file <- exp$velocity_file(dataset_id, method_id, params_id)
      if (!file.exists(velocity_file)) return(NULL)
      velocity <- read_rds(velocity_file)

      predicted_velocity <- velocity$velocity_vector
      # predicted_velocity[predicted_velocity == 0] <- NA
      # predicted_velocity[is.na(predicted_velocity)] <- runif(sum(is.na(predicted_velocity)), -1e-10, 1e-10)

      cor(as.vector(predicted_velocity), as.vector(groundtruth_velocity))

      paired_simil(
        predicted_velocity,
        groundtruth_velocity,
        method = "spearman",
        margin = 2
      ) %>%
        enframe("feature_id", "score") %>%
        mutate(method_id, params_id, dataset_id)
    }
  ) %>% left_join(design_datasets, c("dataset_id" = "id"))
}

mean_scores <- exp$result("scores_aggregated.rds") %cache% {
  scores %>%
    group_by(dataset_id, method_id, params_id) %>%
    summarise(score = mean(score)) %>%
    left_join(design_datasets, c("dataset_id" = "id"))
}

