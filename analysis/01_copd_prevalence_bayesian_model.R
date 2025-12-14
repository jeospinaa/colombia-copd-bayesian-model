# ==============================================================================
# COPD Prevalence Bayesian Model Analysis
# ==============================================================================
# Project: Bayesian Epidemiological Study on COPD Prevalence in Colombia
# Authors: Ospina J, García-Morales OM, Gaviria MC.
# Date: December of 2025
# 
# Description: This script performs Bayesian GAM modeling to estimate COPD
#              prevalence in Colombia using multiple predictors.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. LIBRARY IMPORTS
# ------------------------------------------------------------------------------

library(tidyverse)
library(brms)
library(bayesplot)
library(loo)

# ------------------------------------------------------------------------------
# 2. DATA LOADING
# ------------------------------------------------------------------------------
# NOTE: Data has already been preprocessed by analysis/00_data_preprocessing.R
# All variables are in English and adjustment_factor is already calculated
# ------------------------------------------------------------------------------

# Ensure output directories exist
if (!dir.exists("outputs/tables")) {
  dir.create("outputs/tables", recursive = TRUE)
}
if (!dir.exists("outputs/figures")) {
  dir.create("outputs/figures", recursive = TRUE)
}
if (!dir.exists("models")) {
  dir.create("models", recursive = TRUE)
}

# Load clean preprocessed data
# NOTE: Run analysis/00_data_preprocessing.R first to generate the processed dataset
cat("Loading preprocessed data from: data/processed/copd_analysis_ready_data.csv\n")
if (!file.exists("data/processed/copd_analysis_ready_data.csv")) {
  stop("ERROR: Preprocessed data file not found. Please run analysis/00_data_preprocessing.R first.")
}

copd_data <- read_csv("data/processed/copd_analysis_ready_data.csv", show_col_types = FALSE)

# Display data structure
cat("\n=== LOADED DATA STRUCTURE ===\n")
cat("Rows: ", nrow(copd_data), ", Columns: ", ncol(copd_data), "\n")
cat("\n=== KEY VARIABLES VERIFICATION ===\n")
required_vars <- c("adjustment_factor", "spirometry_rate", "lethality_rate", 
                   "patients_rate", "biomass_stove_usage", 
                   "multidimensional_poverty_index", "pop_over_40_percent", 
                   "total_prevalence")
missing_vars <- setdiff(required_vars, names(copd_data))
if (length(missing_vars) > 0) {
  stop("ERROR: Missing required variables: ", paste(missing_vars, collapse = ", "))
} else {
  cat("✓ All required variables present\n")
}

cat("\n=== FIRST ROWS OF DATA ===\n")
print(head(copd_data[, required_vars]))
cat("\n=== DATA SUMMARY ===\n")
print(summary(copd_data[, required_vars]))
cat("\n")

# ------------------------------------------------------------------------------
# 3. BAYESIAN GAM MODEL DEFINITION
# ------------------------------------------------------------------------------
#
# Family: Gamma (log link) to handle right-skewed positive prevalence data
# Priors: Weakly informative priors on Intercept
#
# Model specification:
#   - Smooth terms (splines) for continuous predictors with k=5 basis functions
#   - Linear term for total_prevalence
#   - Gamma family with log link for positive, right-skewed outcome
#   - 4 chains, 4000 iterations per chain
#   - High adapt_delta (0.999) for better sampling
# ------------------------------------------------------------------------------

cat("\n=== MODEL TRAINING STARTED ===\n")
cat("This may take several minutes due to MCMC sampling...\n")
cat("Chains: 4, Iterations: 4000 per chain\n\n")

bayesian_model_final <- brm(
  bf(adjustment_factor ~ s(spirometry_rate, k = 5) + 
                         s(lethality_rate, k = 5) + 
                         s(patients_rate, k = 5) + 
                         s(biomass_stove_usage, k = 5) + 
                         s(multidimensional_poverty_index, k = 5) + 
                         s(pop_over_40_percent, k = 5) + 
                         total_prevalence),
  data = copd_data,
  family = Gamma(link = "log"),
  prior = c(prior(normal(0, 1), class = "Intercept")),  # Normal prior for log-scale intercept
  control = list(adapt_delta = 0.999),
  cores = 4,
  chains = 4,
  iter = 4000,
  file = "models/copd_prevalence_final_model" # Auto-save the model
)

cat("\n✓ Model training completed\n\n")

# ------------------------------------------------------------------------------
# 4. SAVE MODEL OBJECT
# ------------------------------------------------------------------------------

cat("=== SAVING MODEL OBJECT ===\n")
saveRDS(bayesian_model_final, file = "models/final_model.rds")
cat("✓ Model object saved to: models/final_model.rds\n")
cat("  (You can reload it later with: readRDS('models/final_model.rds'))\n\n")

# ------------------------------------------------------------------------------
# 5. EXTRACT AND SAVE FIXED EFFECTS TABLE (FOR REVIEWER 3)
# ------------------------------------------------------------------------------

cat("=== EXTRACTING FIXED EFFECTS TABLE ===\n")

# Extract fixed effects summary (coefficients table)
model_summary <- summary(bayesian_model_final)
fixed_effects <- model_summary$fixed %>%
  as.data.frame() %>%
  rownames_to_column(var = "parameter")

# Save fixed effects table
write.csv(fixed_effects,
          file = "outputs/tables/bayesian_model_summary.csv",
          row.names = FALSE)
cat("✓ Fixed effects table saved to: outputs/tables/bayesian_model_summary.csv\n")
cat("  (This is the coefficients table requested by Reviewer 3)\n\n")

# Display summary
cat("=== FIXED EFFECTS SUMMARY ===\n")
print(fixed_effects)
cat("\n")

# ------------------------------------------------------------------------------
# 6. EXTRACT PREVALENCE ESTIMATES BY DEPARTMENT
# ------------------------------------------------------------------------------

cat("=== EXTRACTING PREVALENCE ESTIMATES ===\n")

# Extract prevalence estimates by department
departmental_prevalence <- copd_data %>%
  mutate(predicted_adjustment = fitted(bayesian_model_final)[, "Estimate"]) %>%
  select(DPNOM, Nom_Capital, Year, predicted_adjustment, adjustment_factor, total_prevalence)

# Save departmental prevalence estimates
write.csv(departmental_prevalence,
          file = "outputs/tables/departmental_prevalence_estimates.csv",
          row.names = FALSE)
cat("✓ Departmental prevalence estimates saved to: outputs/tables/departmental_prevalence_estimates.csv\n\n")

# ------------------------------------------------------------------------------
# 7. MODEL DIAGNOSTICS (OPTIONAL - COMMENTED OUT FOR NOW)
# ------------------------------------------------------------------------------

# Check convergence
# summary(bayesian_model_final)
# plot(bayesian_model_final)

# Posterior predictive checks
# pp_check(bayesian_model_final)

# LOO cross-validation
# loo_model <- loo(bayesian_model_final)

# Create diagnostic plots
# [Add plotting code here]

# Save figures to outputs/figures/
# ggsave("outputs/figures/model_diagnostics.png", ...)

# ------------------------------------------------------------------------------
# END OF SCRIPT
# ------------------------------------------------------------------------------

