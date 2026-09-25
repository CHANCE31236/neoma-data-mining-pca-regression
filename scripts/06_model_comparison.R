# =====================================================================
# 6. Compare the two models and discuss pros & cons
#    Model A: ordinary OLS on the 5 raw predictors
#    Model B: PCR on PC1 + PC2
# =====================================================================

library(tidyverse)
library(car)
library(ggplot2)

dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

df     <- read_csv("data/cars.csv", show_col_types = FALSE)
df_num <- df %>% select(where(is.numeric))

# --- 6.1 Refit both models -------------------------------------------
lm_full <- lm(speed ~ displace + power + weight + length + width, data = df_num)

pca_car <- prcomp(df_num %>% select(displace, power, weight, length, width),
                  scale. = TRUE)
df_pca  <- as_tibble(pca_car$x) %>% mutate(speed = df_num$speed)
lm_pca  <- lm(speed ~ PC1 + PC2, data = df_pca)

# --- 6.2 Predictions --------------------------------------------------
pred_df <- tibble(
  Cars       = df$Cars,
  real_speed = df_num$speed,
  pred_full  = predict(lm_full),
  pred_pca   = predict(lm_pca)
) %>%
  mutate(resid_full = real_speed - pred_full,
         resid_pca  = real_speed - pred_pca)
pred_df

# --- 6.3 Metrics ------------------------------------------------------
metrics <- function(real, pred) {
  tibble(
    r_squared     = round(summary(lm(real ~ pred))$r.squared, 4),
    rmse          = round(sqrt(mean((real - pred)^2)), 4),
    mae           = round(mean(abs(real - pred)), 4),
    max_abs_error = round(max(abs(real - pred)), 4)
  )
}

comparison <- bind_rows(
  metrics(pred_df$real_speed, pred_df$pred_full) %>% mutate(model = "OLS (5 predictors)"),
  metrics(pred_df$real_speed, pred_df$pred_pca)  %>% mutate(model = "PCR (PC1 + PC2)")
) %>%
  select(model, everything())
comparison
#   OLS : R2 0.9148 | RMSE  7.21 km/h | MAE  5.59 | max error 18.41
#   PCR : R2 0.7406 | RMSE 12.57 km/h | MAE 10.85 | max error 31.15
#   (worst PCR errors: nissan vanette +31.2, vw caravelle +20.4)

comparison_ext <- tibble(
  model        = c("OLS (5 predictors)", "PCR (PC1 + PC2)"),
  r_squared    = c(0.9148, 0.7406),
  adj_r2       = c(0.8911, 0.7159),
  sigma        = c(8.3196, 13.4408),
  rmse         = c(7.2050, 12.5727),
  max_vif      = c(10.516, 1.000),
  n_parameters = c(6, 3)
)
comparison_ext

# --- 6.4 Predicted vs. real ------------------------------------------
p_pred <- ggplot(pred_df) +
  geom_point(aes(x = real_speed, y = pred_full, colour = "OLS"), size = 2.5) +
  geom_point(aes(x = real_speed, y = pred_pca,  colour = "PCR"), size = 2.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_colour_manual(values = c("OLS" = "firebrick", "PCR" = "#2166AC")) +
  labs(title = "Real vs. predicted top speed",
       x = "Real speed (km/h)", y = "Predicted speed (km/h)", colour = "Model") +
  coord_equal(xlim = c(130, 240), ylim = c(130, 240)) +
  theme_bw()

p_pred
ggsave("figures/06_predicted_vs_real.png", p_pred, width = 6, height = 5, dpi = 150)

# --- 6.5 Residuals ----------------------------------------------------
p_res <- pred_df %>%
  pivot_longer(cols = c(resid_full, resid_pca),
               names_to = "model", values_to = "residual") %>%
  ggplot(aes(x = model, y = residual)) +
  geom_boxplot(fill = "#B0E0E6") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Residuals: OLS vs PCR", x = NULL, y = "Residual (km/h)") +
  theme_bw()

p_res
ggsave("figures/06_residuals_boxplot.png", p_res, width = 5.5, height = 4, dpi = 150)

# --- 6.6 Discussion ---------------------------------------------------
# OLS
#   + best in-sample accuracy (RMSE 7.2 km/h), keeps all raw information
#   + familiar output in the original units
#   - VIF up to 10.5: coefficients unstable, signs can be reversed
#     (weight negative although it correlates positively with speed)
#   - coefficients not interpretable, sensitive to adding/removing a car
#   - 6 parameters for 24 observations
# PCR
#   + predictors orthogonal (VIF = 1): stable, numerically clean estimates
#   + 3 parameters instead of 6: less variance, easier to generalise
#   + components have a meaning (PC1 = global size/power, PC2 = power/width)
#   - lower in-sample fit: PC1 + PC2 keep 93.8% of the predictor variance
#     but only 74% of the speed variance (the discarded 6% of predictor
#     variance mattered for the target)
#   - coefficients live in PC space, not directly in km/h per kg or per cc
# Practical conclusion: for pure prediction on this tiny sample, keep OLS
# (or PCR with 3-5 components); for interpretation and stability, prefer
# PCR or a penalised alternative (ridge / lasso).

write_csv(pred_df,       "results/06_predictions.csv")
write_csv(comparison_ext,"results/06_model_comparison.csv")
