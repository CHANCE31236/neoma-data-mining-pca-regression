# =====================================================================
# 2. Ordinary multiple linear regression + VIF test
# 3. Discussion: conditional associations and collinearity
#
#   speed ~ displace + power + weight + length + width
#
# The model fits well (R2 = 0.915) but the variance inflation factors
# indicate strong multicollinearity and inflated standard errors.
# Conditional associations can differ from marginal slopes.
# =====================================================================

library(tidyverse)
library(car)

dir.create("figures", showWarnings = FALSE)

df     <- read_csv("data/cars.csv", show_col_types = FALSE)
df_num <- df %>% select(where(is.numeric))

predictors <- c("displace", "power", "weight", "length", "width")

# --- 2.1 Fit the full model ------------------------------------------
lm_full <- lm(speed ~ displace + power + weight + length + width, data = df_num)

summary(lm_full)
#   R2      = 0.9148   Adjusted R2 = 0.8911
#   F(5,18) = 38.66    p = 5.17e-09   Residual SE = 8.32 km/h

# --- 2.2 Coefficient table -------------------------------------------
coef_table <- as.data.frame(summary(lm_full)$coefficients)
names(coef_table) <- c("estimate", "std_error", "t_value", "p_value")
coef_table$term <- rownames(coef_table)
coef_table <- coef_table %>%
  select(term, everything())
coef_table

#   term        estimate   std_error   t_value   p_value
#   (Intercept) 137.2260     52.9134     2.593    0.0184
#   displace      0.0042      0.0107     0.396    0.6965  (not significant)
#   power         0.7353      0.0901     8.160    1.8e-07 (significant)
#   weight       -0.0939      0.0229    -4.096    0.0007  (NEGATIVE!)
#   length        0.3779      0.1335     2.830    0.0111
#   width        -0.5972      0.4569    -1.307    0.2077  (not significant)

# --- 2.3 VIF test -----------------------------------------------------
vif_values <- round(vif(lm_full), 3)
vif_values
#   displace 10.516 | power 4.058 | weight 9.255 | length 10.126 | width 4.063
#   Rule of thumb: VIF > 5 is worrying, VIF > 10 is severe.
#   -> displace and length are above 10, weight is just below (9.26):
#      multicollinearity is severe and confirmed quantitatively.

sqrt(vif_values)   # SEs inflated by a factor > 3 for displace and length

# --- 3.1 Interpreting conditional associations with collinearity ------
# * displace correlates +0.69 with speed, yet its coefficient is ~0 and
#   not statistically significant after adjustment for the other predictors.
# * weight correlates +0.49 with speed, yet its coefficient is NEGATIVE
#   (-0.094 km/h per kg). This conditional association can differ from
#   the marginal slope. A sign reversal alone does not prove instability
#   or make the conditional comparison meaningless.
# * High VIF inflates standard errors. These observational coefficients
#   describe associations and do not establish causal effects. Predictive
#   performance requires evaluation on observations excluded from fitting.

# --- 3.2 Collinearity-free reference: one predictor at a time ---------
simple_slopes <- sapply(predictors, function(v) {
  f <- as.formula(paste("speed ~", v))
  coef(lm(f, data = df_num))[2]
})
tibble(variable = predictors,
       simple_slope = round(as.numeric(simple_slopes), 4),
       multiple_model_slope = unname(coef(lm_full)[predictors]))
# Every simple slope is positive: the negative weight coefficient only
# appears once all five predictors enter the model together.

# --- 3.3 Diagnostic plots ---------------------------------------------
png("figures/03_diagnostics_full_model.png", width = 900, height = 700, res = 120)
par(mfrow = c(2, 2))
plot(lm_full)
dev.off()
par(mfrow = c(1, 1))

# --- 3.4 Save the key numbers ----------------------------------------
dir.create("results", showWarnings = FALSE)
write_csv(coef_table, "results/03_ols_coefficients.csv")
write_csv(tibble(term = names(vif_values),
                 vif  = as.numeric(vif_values)),
          "results/03_vif.csv")
