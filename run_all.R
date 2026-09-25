# =====================================================================
# Run the full pipeline: cleaning -> correlation -> OLS + VIF -> PCA
# -> principal component regression -> model comparison.
#
# From the repository root:
#   Rscript run_all.R        (or source("run_all.R") in RStudio)
#
# Figures are written to figures/, tables to results/.
# =====================================================================

scripts <- c(
  "scripts/01_data_cleaning_eda.R",
  "scripts/02_correlation_heatmap.R",
  "scripts/03_ols_regression_vif.R",
  "scripts/04_pca.R",
  "scripts/05_principal_component_regression.R",
  "scripts/06_model_comparison.R"
)

for (s in scripts) {
  message("\n===== ", s, " =====\n")
  source(s)
}

message("\nDone. Check figures/ and results/.")
