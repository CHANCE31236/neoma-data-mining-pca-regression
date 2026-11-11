# =====================================================================
# 0. Data cleaning and exploratory analysis
# NEOMA Business School - Data Mining for Business
# Dataset: 24 cars, 6 numeric variables (speed is the target)
# Run from the repository root:  source("scripts/01_data_cleaning_eda.R")
# =====================================================================

library(tidyverse)
library(ggplot2)

dir.create("figures", showWarnings = FALSE)

# --- 0.1 Load ---------------------------------------------------------
df <- read_csv("data/cars.csv", show_col_types = FALSE)

required_columns <- c("Cars", "displace", "power", "speed", "weight", "length", "width")
if (!all(required_columns %in% names(df))) {
  stop("cars.csv must contain: ", paste(required_columns, collapse = ", "))
}
df <- df %>% mutate(Cars = str_squish(Cars))
if (anyNA(df$Cars) || any(!nzchar(df$Cars)) || anyDuplicated(df$Cars)) {
  stop("Car names must be present and unique after trimming whitespace.")
}
measurements <- df[setdiff(required_columns, "Cars")]
if (!all(vapply(measurements, is.numeric, logical(1))) ||
    anyNA(measurements) || !all(is.finite(as.matrix(measurements))) ||
    !all(as.matrix(measurements) > 0)) {
  stop("All six measurements must be finite, positive numeric values without missing data.")
}
if (nrow(df) <= 7L || any(vapply(measurements, sd, numeric(1)) == 0)) {
  stop("The analysis needs more than seven rows and nonconstant measurements.")
}

glimpse(df)

# --- 0.2 Cleaning checks ---------------------------------------------
# The dataset is small and complete, but the checks are kept so the
# pipeline stays valid if new rows are added later.
colSums(is.na(df))            # missing values   -> 0 everywhere
sum(duplicated(df$Cars))      # duplicated cars  -> 0
nrow(df)                      # 24 observations

# All measurements must be strictly positive
df_num <- df %>% select(where(is.numeric))
stopifnot(all(df_num > 0))

# --- 0.3 Univariate description --------------------------------------
summary(df_num)
sapply(df_num, sd)            # spread: displace/width are on very different scales

# --- 0.4 Boxplots (raw scales differ a lot) ---------------------------
df_long <- df_num %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "value")

p_box <- ggplot(df_long, aes(x = variable, y = value)) +
  geom_boxplot(fill = "#87CEEB", outlier.colour = "firebrick") +
  labs(title = "Boxplots of the raw variables",
       subtitle = "Different units and scales -> standardisation required before PCA",
       x = NULL, y = NULL) +
  theme_bw()

p_box
ggsave("figures/01_boxplots_raw.png", p_box, width = 7, height = 4, dpi = 150)

# --- 0.5 Same view after standardisation ------------------------------
df_long_sc <- df_num %>%
  scale() %>%
  as_tibble() %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "value")

p_box_sc <- ggplot(df_long_sc, aes(x = variable, y = value)) +
  geom_boxplot(fill = "#B0E0E6", outlier.colour = "firebrick") +
  labs(title = "Boxplots of the standardised variables",
       x = NULL, y = "z-score") +
  theme_bw()

p_box_sc
ggsave("figures/01_boxplots_scaled.png", p_box_sc, width = 7, height = 4, dpi = 150)

# --- 0.6 Target variable ---------------------------------------------
summary(df$speed)             # min 135, median 181.5, max 226 km/h

p_speed <- ggplot(df, aes(x = speed)) +
  geom_histogram(bins = 8, fill = "#4682B4", colour = "white") +
  labs(title = "Distribution of top speed (km/h)", x = "speed", y = "count") +
  theme_bw()

p_speed
ggsave("figures/01_speed_histogram.png", p_speed, width = 6, height = 4, dpi = 150)
