# Exploratory leave-one-out comparison of fixed OLS/PCR specifications.
# Every fold estimates centering, scaling and PCA using its training cars.
library(tidyverse)

df <- read_csv("data/cars.csv", show_col_types = FALSE)
predictors <- c("displace", "power", "weight", "length", "width")

loo_predictions <- map_dfr(seq_len(nrow(df)), function(i) {
  train <- df[-i, ]
  test <- df[i, ]
  ols <- lm(speed ~ displace + power + weight + length + width, data = train)
  fold_pca <- prcomp(train[predictors], center = TRUE, scale. = TRUE)
  training_scores <- as.data.frame(fold_pca$x)
  training_scores$speed <- train$speed
  held_out_scores <- as.data.frame(predict(fold_pca, newdata = test[predictors]))

  pcr_predictions <- map_dfr(seq_along(predictors), function(k) {
    formula <- reformulate(paste0("PC", seq_len(k)), response = "speed")
    pcr <- lm(formula, data = training_scores)
    tibble(model = paste0("PCR (", k, " PCs)"),
           predicted_speed = unname(predict(pcr, newdata = held_out_scores)))
  })
  bind_rows(
    tibble(model = "OLS (5 predictors)",
           predicted_speed = unname(predict(ols, newdata = test))),
    pcr_predictions
  ) %>%
    mutate(Cars = test$Cars, real_speed = test$speed, .before = 1)
})

loo_metrics <- loo_predictions %>%
  group_by(model) %>%
  summarise(
    n = n(),
    rmse = sqrt(mean((real_speed - predicted_speed)^2)),
    mae = mean(abs(real_speed - predicted_speed)),
    predictive_r_squared = 1 - sum((real_speed - predicted_speed)^2) /
      sum((real_speed - mean(real_speed))^2),
    .groups = "drop"
  )

# With every component retained, PCR and OLS span the same linear model.
ols_predictions <- filter(loo_predictions, model == "OLS (5 predictors)")$predicted_speed
full_pcr_predictions <- filter(loo_predictions, model == "PCR (5 PCs)")$predicted_speed
stopifnot(max(abs(ols_predictions - full_pcr_predictions)) < 1e-8)
stopifnot(all(is.finite(loo_predictions$predicted_speed)))

dir.create("results", showWarnings = FALSE)
write_csv(loo_predictions, "results/07_loo_predictions.csv")
write_csv(loo_metrics, "results/07_loo_comparison.csv")
print(loo_metrics)
# Selecting the lowest-error specification here and reporting that same
# error as an unbiased tuned-model estimate would require nested validation.
