# ==============================================================================
# Data Preprocessing Script: Composite Bias-Correction Multiplier Calculation
# ==============================================================================
# Project: Bayesian Epidemiological Study on COPD Prevalence in Colombia
# Author: Ospina J, García-Morales OM, Gaviria MC
# Date: December of 2025
# 
# Description: This script loads raw data, calculates the Composite 
#              Bias-Correction Multiplier (adjustment_factor) based on
#              reproducible R logic, and prepares the clean dataset for modeling.
#              This is the definitive source of truth for the Bayesian Model.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. LIBRARY IMPORTS
# ------------------------------------------------------------------------------

library(tidyverse)
library(readxl)

# ------------------------------------------------------------------------------
# 2. DATA LOADING
# ------------------------------------------------------------------------------

cat("=== LOADING RAW DATA ===\n")
raw_data <- read_excel("data/raw/copd_epidemiological_data_raw.xlsx")
cat("Raw data loaded: ", nrow(raw_data), " rows × ", ncol(raw_data), " columns\n\n")

# ------------------------------------------------------------------------------
# 3. DEFINE THRESHOLDS
# ------------------------------------------------------------------------------

cat("=== DEFINING THRESHOLDS ===\n")

# Administrative Standard for Spirometry
Spiro_Target <- 1105.08
cat("Spiro_Target (Administrative Standard):", Spiro_Target, "\n")

# Lethality Threshold: 75th Percentile (Q3) of 'Letalidad' column
Lethality_Threshold <- quantile(raw_data$Letalidad, probs = 0.75, na.rm = TRUE)
cat("Lethality_Threshold (Q3):", Lethality_Threshold, "\n")

# Access Threshold: 25th Percentile (Q1) of 'Tasa_pts' column
Access_Threshold <- quantile(raw_data$Tasa_pts, probs = 0.25, na.rm = TRUE)
cat("Access_Threshold (Q1):", Access_Threshold, "\n\n")

# ------------------------------------------------------------------------------
# 4. CALCULATE PARTIAL PENALTIES (BIAS INDEX COMPONENTS)
# ------------------------------------------------------------------------------

cat("=== CALCULATING BIAS INDEX COMPONENTS ===\n")

copd_data <- raw_data %>%
  mutate(
    # Spirometry Score
    # If Espiro_NalTasa < Spiro_Target, penalty = (Spiro_Target - Espiro_NalTasa) / Spiro_Target
    # Else 0
    spirometry_score = if_else(
      Espiro_NalTasa < Spiro_Target,
      (Spiro_Target - Espiro_NalTasa) / Spiro_Target,
      0
    ),
    
    # Lethality Score
    # If Letalidad > Lethality_Threshold, penalty = (Letalidad - Lethality_Threshold) / Lethality_Threshold
    # Else 0
    lethality_score = if_else(
      Letalidad > Lethality_Threshold,
      (Letalidad - Lethality_Threshold) / Lethality_Threshold,
      0
    ),
    
    # Access Score
    # If Tasa_pts < Access_Threshold, penalty = (Access_Threshold - Tasa_pts) / Access_Threshold
    # Else 0
    access_score = if_else(
      Tasa_pts < Access_Threshold,
      (Access_Threshold - Tasa_pts) / Access_Threshold,
      0
    )
  )

cat("Partial scores calculated\n")
cat("Spirometry Score range: [", min(copd_data$spirometry_score, na.rm = TRUE), 
    ", ", max(copd_data$spirometry_score, na.rm = TRUE), "]\n")
cat("Lethality Score range: [", min(copd_data$lethality_score, na.rm = TRUE), 
    ", ", max(copd_data$lethality_score, na.rm = TRUE), "]\n")
cat("Access Score range: [", min(copd_data$access_score, na.rm = TRUE), 
    ", ", max(copd_data$access_score, na.rm = TRUE), "]\n\n")

# ------------------------------------------------------------------------------
# 5. CALCULATE FINAL ADJUSTMENT FACTOR
# ------------------------------------------------------------------------------

cat("=== CALCULATING ADJUSTMENT FACTOR ===\n")

copd_data <- copd_data %>%
  mutate(
    # Bias Index Score
    bias_index_score = spirometry_score + lethality_score + access_score,
    
    # Adjustment Factor: 1 + bias_index_score
    adjustment_factor = 1 + bias_index_score
  )

cat("Adjustment factor calculated using reproducible R logic\n")
cat("Bias Index Score range: [", min(copd_data$bias_index_score, na.rm = TRUE), 
    ", ", max(copd_data$bias_index_score, na.rm = TRUE), "]\n")
cat("Adjustment Factor range: [", min(copd_data$adjustment_factor, na.rm = TRUE), 
    ", ", max(copd_data$adjustment_factor, na.rm = TRUE), "]\n\n")

# ------------------------------------------------------------------------------
# 6. FINALIZE DATASET: SELECT, RENAME, AND CLEAN
# ------------------------------------------------------------------------------

cat("=== FINALIZING DATASET ===\n")

# Select relevant columns and rename to English standards
# Drop old manual columns (Vero_Ajuste, Factor_Ajuste, etc.)
clean_data <- copd_data %>%
  # Rename Spanish columns to English standards
  rename(
    spirometry_rate = Espiro_NalTasa,
    lethality_rate = Letalidad,
    patients_rate = Tasa_pts,
    biomass_stove_usage = Estufa,
    multidimensional_poverty_index = IPM,
    pop_over_40_percent = Porc40_may,
    total_prevalence = Prev_Total
  ) %>%
  # Drop old manual adjustment columns (deprecated methodology)
  select(-any_of(c("Vero_Ajuste", "Factor_Ajuste")))

cat("✓ Dataset finalized\n")
cat("  - Variables renamed to English standards\n")
cat("  - Old manual columns removed (Vero_Ajuste, Factor_Ajuste)\n")
cat("  - Adjustment factor calculated using new reproducible methodology\n")
cat("  - Final columns: ", ncol(clean_data), "\n\n")

# ------------------------------------------------------------------------------
# 7. DATA QUALITY CHECKS
# ------------------------------------------------------------------------------

cat("=== DATA QUALITY CHECKS ===\n")

# Remove rows with missing values in key variables
rows_before <- nrow(clean_data)
clean_data <- clean_data %>%
  filter(!is.na(spirometry_rate),
         !is.na(lethality_rate),
         !is.na(patients_rate),
         !is.na(biomass_stove_usage),
         !is.na(multidimensional_poverty_index),
         !is.na(pop_over_40_percent),
         !is.na(total_prevalence),
         !is.na(adjustment_factor))
rows_after <- nrow(clean_data)

cat("Rows before filtering: ", rows_before, "\n")
cat("Rows after filtering: ", rows_after, "\n")
cat("Rows removed: ", rows_before - rows_after, "\n\n")

# ------------------------------------------------------------------------------
# 8. VERIFICATION: SUMMARY OF ADJUSTMENT_FACTOR
# ------------------------------------------------------------------------------

cat("=== VERIFICATION: ADJUSTMENT_FACTOR SUMMARY ===\n")
print(summary(clean_data$adjustment_factor))
cat("\n")

# Verify that all values are >= 1
if (all(clean_data$adjustment_factor >= 1, na.rm = TRUE)) {
  cat("✓ All adjustment_factor values are >= 1 (as expected)\n")
} else {
  cat("⚠ WARNING: Some adjustment_factor values are < 1\n")
}

cat("\n=== SAMPLE OF FINAL DATASET ===\n")
sample_data <- clean_data %>%
  select(DPNOM, Nom_Capital, Year, 
         spirometry_rate, lethality_rate, patients_rate,
         biomass_stove_usage, multidimensional_poverty_index, 
         pop_over_40_percent, total_prevalence, adjustment_factor) %>%
  head(10)
print(sample_data)
cat("\n")

# ------------------------------------------------------------------------------
# 9. SAVE OUTPUT
# ------------------------------------------------------------------------------

cat("=== SAVING PROCESSED DATA ===\n")

# Ensure output directory exists
if (!dir.exists("data/processed")) {
  dir.create("data/processed", recursive = TRUE)
}

# Save the clean processed dataset
write.csv(clean_data, 
          file = "data/processed/copd_analysis_ready_data.csv", 
          row.names = FALSE)

cat("✓ Clean processed data saved to: data/processed/copd_analysis_ready_data.csv\n")
cat("Final dataset: ", nrow(clean_data), " rows × ", ncol(clean_data), " columns\n")
cat("  This is the definitive source of truth for the Bayesian Model\n\n")

# ------------------------------------------------------------------------------
# END OF SCRIPT
# ------------------------------------------------------------------------------

cat("=== PREPROCESSING COMPLETE ===\n")
cat("  Dataset ready for Bayesian modeling with reproducible adjustment_factor\n")
