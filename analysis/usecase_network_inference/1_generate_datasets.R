library(tidyverse)
library(dyngen)
library(dyngen.manuscript)

exp <- start_analysis("usecase_network_inference")

# setup dataset design
design_datasets <- exp$result("design_datasets.rds") %cache% {
  crossing(
    seed = 1,
    backbone_name = names(list_backbones())
  ) %>%
    mutate(id = paste0(backbone_name, "_", seed))
}

#' @examples
#' design_datasets %>% dynutils::extract_row_to_list(1) %>% list2env(.GlobalEnv)

pwalk(design_datasets, function(id, seed, backbone_name) {
  if (!file.exists(exp$dataset_file(id))) {

    cat("## Generating ", id, "\n", sep = "")
    set.seed(seed)

    backbone <- list_backbones()[[backbone_name]]()
    wanted_genes <- 200

    num_tfs <- nrow(backbone$module_info) * 3
    num_targets <- round((wanted_genes - num_tfs) / 2)

    model <-
      initialise_model(
        id = id,
        num_tfs = num_tfs,
        num_targets = num_targets,
        num_hks = wanted_genes - num_tfs - num_targets,
        backbone = backbone,
        num_cells = 1000,
        simulation_params = simulation_default(
          census_interval = 2.5,
          experiment_params = bind_rows(
            simulation_type_wild_type(num_simulations = 50),
            simulation_type_knockdown(num_simulations = 100, num_genes = sample(1:10, 100, replace = TRUE))
          ),
          compute_cellwise_grn = TRUE,
          compute_dimred = TRUE
        ),
        num_cores = 6,
        download_cache_dir = "~/.cache/dyngen",
        verbose = TRUE
      )
    generate_dataset(
      model,
      output_dir = exp$dataset_folder(id),
      make_plots = TRUE,
      store_propensity_ratios = TRUE
    )

    gc()
  }
})
