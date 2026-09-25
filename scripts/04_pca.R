# =====================================================================
# 4. PCA: compress 5 highly correlated predictors into a few
#    uncorrelated principal components.
#
# prcomp(..., scale. = TRUE) is mandatory here: displace is measured in
# cubic centimetres (sd = 528) and width in centimetres (sd = 7.7), so an
# unscaled PCA would simply be a PCA of displacement.
# =====================================================================

library(tidyverse)
library(ggplot2)

dir.create("figures", showWarnings = FALSE)

df     <- read_csv("data/cars.csv", show_col_types = FALSE)
df_num <- df %>% select(where(is.numeric))

var <- df_num %>% select(displace, power, weight, length, width)

# --- 4.1 Run PCA on the standardised predictors -----------------------
pca_car <- prcomp(var, scale. = TRUE)
pca_car

summary(pca_car)
#   Importance of components
#                          PC1    PC2    PC3    PC4    PC5
#   Standard deviation   2.043  0.721  0.419  0.261  0.254
#   Proportion of Var    0.834  0.104  0.035  0.014  0.013
#   Cumulative Proportion 0.834 0.938  0.973  0.987  1.000

# --- 4.2 Scree plot ---------------------------------------------------
scree_df <- tibble(
  pc          = paste0("PC", 1:5),
  sd          = pca_car$sdev,
  variance    = pca_car$sdev^2 / sum(pca_car$sdev^2),
  cumulative  = cumsum(variance)
)

p_scree <- ggplot(scree_df, aes(x = pc, y = sd, group = 1)) +
  geom_col(fill = "#87CEEB") +
  geom_line() +
  geom_point(size = 2) +
  labs(title = "Scree plot",
       subtitle = "One dominant component: the 5 predictors share a single latent dimension",
       x = "Principal component", y = "Standard deviation") +
  theme_bw()

p_scree
ggsave("figures/04_scree_plot.png", p_scree, width = 6, height = 4, dpi = 150)

p_cum <- ggplot(scree_df, aes(x = pc, y = cumulative, group = 1)) +
  geom_col(fill = "#4682B4") +
  geom_line() + geom_point(size = 2) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(title = "Cumulative variance explained",
       x = "Principal component", y = "Cumulative share of variance") +
  theme_bw()

p_cum
ggsave("figures/04_cumulative_variance.png", p_cum, width = 6, height = 4, dpi = 150)

# --- 4.3 Loadings (how each PC is built) ------------------------------
loadings <- as.data.frame(round(pca_car$rotation, 3)) %>%
  rownames_to_column("variable")
loadings
#            PC1    PC2    PC3    PC4    PC5
# displace 0.466  0.281 -0.245 -0.034 -0.802
# power    0.411  0.683  0.507 -0.034  0.325
# weight   0.469 -0.057 -0.508  0.610  0.382
# length   0.466 -0.275 -0.237 -0.757  0.279
# width    0.420 -0.613  0.607  0.230 -0.165
#
# PC1 = "overall size / engine"   : all loadings positive and similar (~0.42-0.47)
# PC2 = "power vs. width" contrast: power (+0.68) against width (-0.61)
# NOTE: the sign of a component is arbitrary (LAPACK dependent); only the
#       relative signs inside a component carry meaning.

# --- 4.4 Correlation circle / biplot ----------------------------------
p_biplot <- ggplot() +
  geom_point(aes(x = pca_car$x[, 1], y = pca_car$x[, 2]),
             colour = "#2166AC", size = 2) +
  geom_text(aes(x = pca_car$x[, 1], y = pca_car$x[, 2], label = df$Cars),
            size = 2.5, vjust = -0.7, colour = "grey30") +
  geom_segment(aes(x = 0, y = 0,
                   xend = pca_car$rotation[, 1] * 3.5,
                   yend = pca_car$rotation[, 2] * 3.5),
               arrow = arrow(length = unit(0.2, "cm")), colour = "#B2182B") +
  geom_text(aes(x = pca_car$rotation[, 1] * 3.9,
                y = pca_car$rotation[, 2] * 3.9,
                label = rownames(pca_car$rotation)),
            colour = "#B2182B", size = 4) +
  labs(title = "PCA biplot (PC1 / PC2)", x = "PC1 (83.4%)", y = "PC2 (10.4%)") +
  theme_bw()

p_biplot
ggsave("figures/04_biplot.png", p_biplot, width = 7, height = 5, dpi = 150)

# --- 4.5 Components are uncorrelated by construction ------------------
round(cor(pca_car$x), 6)   # identity matrix -> multicollinearity is gone

dir.create("results", showWarnings = FALSE)
write_csv(loadings, "results/04_pca_loadings.csv")
write_csv(scree_df, "results/04_pca_variance.csv")
