# =====================================================================
# 5. Principal component regression (PCR)
# Regress speed on the uncorrelated components instead of the raw,
# collinear predictors.
# =====================================================================

library(tidyverse)
library(car)
library(ggplot2)

dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

df     <- read_csv("data/cars.csv", show_col_types = FALSE)
df_num <- df %>% select(where(is.numeric))

var      <- df_num %>% select(displace, power, weight, length, width)
pca_car  <- prcomp(var, scale. = TRUE)

# --- 5.1 Scores + target ----------------------------------------------
df_pca <- as_tibble(pca_car$x) %>% mutate(speed = df_num$speed)

# --- 5.2 PCR with the first two components ----------------------------
# PC1 + PC2 already carry 93.8% of the predictor variance.
lm_pca <- lm(speed ~ PC1 + PC2, data = df_pca)

summary(lm_pca)
#   R2      = 0.7406   Adjusted R2 = 0.7159
#   F(2,21) = 29.97    p = 7.03e-07   Residual SE = 13.44 km/h
#
#   term        estimate   std.error   t value   Pr(>|t|)
#   (Intercept)  183.083      2.744     66.73    < 2e-16
#   PC1            7.989      1.372      5.82    9.0e-06
#   PC2           19.841      3.887      5.10    4.7e-05

vif(lm_pca)      # = 1 for both components (orthogonal by construction)

# --- 5.3 How many components should be kept? -------------------------
pcr_grid <- map_dfr(1:5, function(k) {
  f    <- as.formula(paste("speed ~", paste0("PC", 1:k, collapse = " + ")))
  m    <- lm(f, data = df_pca)
  pred <- predict(m)
  tibble(
    n_components   = k,
    r_squared      = round(summary(m)$r.squared, 4),
    adj_r_squared  = round(summary(m)$adj.r.squared, 4),
    rmse           = round(sqrt(mean((df_num$speed - pred)^2)), 4),
    sigma          = round(summary(m)$sigma, 4)
  )
})
pcr_grid
#   1 component : R2 0.4188, RMSE 18.82
#   2 components: R2 0.7406, RMSE 12.57   <-- parsimonious choice
#   3 components: R2 0.8341, RMSE 10.05
#   5 components: R2 0.9148, RMSE  7.21   <-- identical to the OLS model
# (with all 5 components PCR reproduces OLS exactly: no information is
#  lost, but nothing is gained either)

p_grid <- ggplot(pcr_grid, aes(x = n_components)) +
  geom_line(aes(y = r_squared, colour = "R squared"), linewidth = 1) +
  geom_point(aes(y = r_squared, colour = "R squared"), size = 2) +
  geom_line(aes(y = rmse / 30, colour = "RMSE (scaled /30)"), linewidth = 1,
            linetype = "dashed") +
  geom_point(aes(y = rmse / 30, colour = "RMSE (scaled /30)"), size = 2) +
  scale_y_continuous(sec.axis = sec_axis(~ . * 30, name = "RMSE (km/h)")) +
  scale_colour_manual(values = c("R squared" = "#2166AC",
                                 "RMSE (scaled /30)" = "#B2182B")) +
  labs(title = "PCR: fit vs. number of components",
       x = "Number of principal components", y = "R squared",
       colour = NULL) +
  theme_bw()

p_grid
ggsave("figures/05_pcr_component_grid.png", p_grid, width = 6.5, height = 4, dpi = 150)

# --- 5.4 Correlations between components and the target ---------------
round(cor(df_pca[, 1:5], df_pca$speed), 3)
# PC1 0.647 | PC2 0.567 | PC3 0.306 | PC4 -0.281 | PC5 0.044
# PC2 is worth keeping even though it explains only 10.4% of the
# predictor variance: it is relatively more informative about speed.

write_csv(pcr_grid, "results/05_pcr_grid.csv")
