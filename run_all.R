# =====================================================================
# Run the full pipeline: cleaning -> correlation -> OLS + VIF -> PCA
# -> principal component regression -> model comparison.
#
# From the repository root:
#   Rscript run_all.R        (or source("run_all.R") in RStudio)
#
# Figures are written to figures/, tables to results/.
# =====================================================================

local({
original_wd <- getwd()
on.exit(setwd(original_wd), add = TRUE)
source_paths <- vapply(sys.frames(), function(frame) {
  if (is.null(frame$ofile)) "" else frame$ofile
}, character(1))
source_paths <- source_paths[basename(source_paths) == "run_all.R"]
if (length(source_paths)) {
  script_path <- tail(source_paths, 1)
} else {
  file_args <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  script_path <- if (length(file_args)) sub("^--file=", "", file_args[1]) else "run_all.R"
}
setwd(dirname(normalizePath(script_path, mustWork = TRUE)))

packages <- c("tidyverse", "ggplot2", "corrplot", "car")
missing_packages <- packages[!vapply(packages, requireNamespace,
                                   quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing_packages)) {
  stop("Install required packages first: install.packages(c(",
       paste(sprintf('"%s"', missing_packages), collapse = ", "), "))")
}

scripts <- c(
  "scripts/01_data_cleaning_eda.R",
  "scripts/02_correlation_heatmap.R",
  "scripts/03_ols_regression_vif.R",
  "scripts/04_pca.R",
  "scripts/05_principal_component_regression.R",
  "scripts/06_model_comparison.R",
  "scripts/07_leave_one_out_validation.R"
)

for (s in scripts) {
  message("\n===== ", s, " =====\n")
  source(s)
}

writeLines(capture.output(sessionInfo()), "results/session-info.txt")
message("\nDone. Check figures/ and results/.")
})
