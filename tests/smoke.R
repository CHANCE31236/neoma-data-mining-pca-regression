# Run from the repository root: Rscript --vanilla tests/smoke.R
check_pipeline <- function() {
  repo <- normalizePath(".", winslash = "/")
  scratch <- tempfile("neoma-smoke-")
  dir.create(scratch)
  stopifnot(file.copy(file.path(repo, "run_all.R"), scratch),
            file.copy(file.path(repo, "scripts"), scratch, recursive = TRUE),
            file.copy(file.path(repo, "data"), scratch, recursive = TRUE))
  original_wd <- getwd()
  setwd(tempdir())
  on.exit(setwd(original_wd), add = TRUE)
  caller_wd <- getwd()
  source(file.path(scratch, "run_all.R"))
  stopifnot(identical(getwd(), caller_wd))
  predictions <- read.csv(file.path(scratch, "results/07_loo_predictions.csv"))
  metrics <- read.csv(file.path(scratch, "results/07_loo_comparison.csv"))
  stopifnot(nrow(predictions) == 144L, nrow(metrics) == 6L,
            all(metrics$n == 24L), all(is.finite(predictions$predicted_speed)),
            all(is.finite(metrics$rmse)), all(metrics$rmse > 0))
  ols <- subset(predictions, model == "OLS (5 predictors)")
  pcr <- subset(predictions, model == "PCR (5 PCs)")
  stopifnot(identical(ols$Cars, pcr$Cars),
            max(abs(ols$predicted_speed - pcr$predicted_speed)) < 1e-8)
  model_comparison <- read.csv(file.path(scratch, "results/06_model_comparison.csv"))
  stopifnot(nrow(model_comparison) == 2L,
            abs(model_comparison$rmse[1] - 7.205) < 0.01,
            all(file.info(list.files(file.path(scratch, "figures"), full.names = TRUE))$size > 0))
  cat("Car analysis and leave-one-out checks passed.\n")
}
check_pipeline()
