# =====================================================================
# 1. Correlation heatmap
# Goal: show that the 5 predictors carry largely redundant information
#       (a warning sign before fitting any multiple regression).
# =====================================================================

library(tidyverse)
library(ggplot2)
library(corrplot)

dir.create("figures", showWarnings = FALSE)

df      <- read_csv("data/cars.csv", show_col_types = FALSE)
df_num  <- df %>% select(where(is.numeric))

# --- 1.1 Correlation matrix ------------------------------------------
cor_matrix <- cor(df_num)
round(cor_matrix, 3)

# --- 1.2 corrplot -----------------------------------------------------
png("figures/02_corrplot.png", width = 900, height = 800, res = 130)
corrplot(cor_matrix,
         method      = "color",
         addCoef.col = "black",
         type        = "lower",
         tl.srt      = 45,
         title       = "Correlation matrix (Pearson)",
         mar         = c(0, 0, 2, 0))
dev.off()

# --- 1.3 Same matrix with ggplot (export-friendly) --------------------
cor_long <- cor_matrix %>%
  as_tibble(rownames = "var1") %>%
  pivot_longer(-var1, names_to = "var2", values_to = "r")

p_cor <- ggplot(cor_long, aes(x = var1, y = var2, fill = r)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = round(r, 2)), size = 3) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Correlation heatmap", x = NULL, y = NULL, fill = "r") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

p_cor
ggsave("figures/02_correlation_heatmap.png", p_cor, width = 6, height = 5, dpi = 150)

# --- 1.4 Correlation of each predictor with the target ----------------
cor_with_speed <- cor_matrix[, "speed"] %>%
  sort(decreasing = TRUE) %>%
  round(3)
cor_with_speed
# power 0.894 | displace 0.693 | length 0.532 | weight 0.491 | width 0.363

# --- 1.5 Read-out -----------------------------------------------------
# Every pair of predictors is positively correlated (0.55 to 0.92):
# the predictors are NOT independent pieces of information, they are
# five different ways of measuring "how big and how powerful the car is".
