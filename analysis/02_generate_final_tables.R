# ==============================================================================
# Final Reporting Script: Generate Manuscript Tables with 95% CrI
# ==============================================================================
# Project: Bayesian Epidemiological Study on COPD Prevalence in Colombia
# Author: Ospina J, García-Morales OM, Gaviria MC
# Date: December of 2025
# 
# Description: This script generates impeccable tables with 95% Credible 
#              Intervals (CrI) obtained directly from the posterior distribution
#              of the Bayesian model, including population-weighted national
#              estimates.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. LIBRARY IMPORTS
# ------------------------------------------------------------------------------

library(tidyverse)
library(brms)
library(readxl)

# ------------------------------------------------------------------------------
# 2. LOAD RESOURCES
# ------------------------------------------------------------------------------

cat("=== LOADING RESOURCES ===\n")

# Load the compiled model
cat("Loading Bayesian model from: models/final_model.rds\n")
model <- readRDS("models/final_model.rds")
cat("✓ Model loaded successfully\n")

# Load the clean processed data
cat("Loading processed data from: data/processed/copd_analysis_ready_data.csv\n")
data <- read_csv("data/processed/copd_analysis_ready_data.csv", show_col_types = FALSE)
cat("✓ Processed data loaded: ", nrow(data), " rows\n")

# Check if processed data already has population weights
if ("Pob40_Depto" %in% names(data)) {
  cat("✓ Population weights (Pob40_Depto) already available in processed data\n\n")
  use_raw_pop <- FALSE
} else {
  # Load raw data for population weights if not in processed data
  cat("Loading raw data for population weights from: data/raw/copd_epidemiological_data_raw.xlsx\n")
  raw_pop <- read_excel("data/raw/copd_epidemiological_data_raw.xlsx") %>%
    select(DPNOM, Year, Pob40_Depto)
  cat("✓ Raw population data loaded: ", nrow(raw_pop), " rows\n")
  
  # Ensure Year is character for merging
  raw_pop$Year <- as.character(raw_pop$Year)
  if (!is.character(data$Year)) {
    data$Year <- as.character(data$Year)
  }
  cat("  Year format standardized for merging\n\n")
  use_raw_pop <- TRUE
}

# ------------------------------------------------------------------------------
# 3. GENERATE POSTERIOR PREDICTIONS (THE "IMPECCABLE" METHOD)
# ------------------------------------------------------------------------------

cat("=== GENERATING POSTERIOR PREDICTIONS ===\n")
cat("This may take a few moments...\n")

# Get full posterior distribution of adjustment_factor using posterior_epred
# This gives us the expected value of the outcome for each observation
posterior_epred_adjustment <- posterior_epred(model, ndraws = NULL)

# Get number of draws and observations
n_draws <- nrow(posterior_epred_adjustment)
n_obs <- ncol(posterior_epred_adjustment)

cat("✓ Posterior predictions generated\n")
cat("  Number of posterior draws: ", n_draws, "\n")
cat("  Number of observations: ", n_obs, "\n")

# Multiply posterior draws by total_prevalence to get True Prevalence Posterior
# Each column is an observation, each row is a posterior draw
cat("\n=== CALCULATING TRUE PREVALENCE POSTERIOR ===\n")

# Create matrix: each row is a draw, each column is an observation
true_prevalence_posterior <- posterior_epred_adjustment * 
  matrix(rep(data$total_prevalence, each = n_draws), 
         nrow = n_draws, ncol = n_obs)

cat("✓ True prevalence posterior calculated\n")
cat("  Dimensions: ", nrow(true_prevalence_posterior), " draws × ", 
    ncol(true_prevalence_posterior), " observations\n\n")

# ------------------------------------------------------------------------------
# 4. CALCULATE DEPARTMENTAL ESTIMATES (MEDIAN OF THE PERIOD 2020-2023)
# ------------------------------------------------------------------------------

cat("=== CALCULATING DEPARTMENTAL ESTIMATES ===\n")

# Add department and year information to the posterior matrix
# We need to aggregate across years for each department
dept_year_info <- data %>%
  select(DPNOM, Year) %>%
  mutate(obs_index = row_number())

# For each department, aggregate across all years (2020-2023)
departments <- unique(data$DPNOM)
n_depts <- length(departments)

# Initialize storage for departmental posterior distributions
dept_posterior_list <- vector("list", n_depts)
names(dept_posterior_list) <- departments

cat("Aggregating posterior draws by department...\n")

for (i in seq_along(departments)) {
  dept <- departments[i]
  
  # Get indices for this department across all years
  dept_indices <- which(data$DPNOM == dept)
  
  # Extract posterior draws for this department (all years combined)
  # Each row is a draw, we combine all years
  dept_posterior <- true_prevalence_posterior[, dept_indices, drop = FALSE]
  
  # For each posterior draw, calculate the median across years
  # This gives us one value per draw for this department
  dept_median_per_draw <- apply(dept_posterior, 1, median)
  
  dept_posterior_list[[i]] <- dept_median_per_draw
  
  if (i %% 10 == 0) {
    cat("  Processed ", i, " / ", n_depts, " departments\n")
  }
}

cat("✓ Departmental posterior distributions calculated\n\n")

# Calculate summary statistics for each department
cat("=== CALCULATING DEPARTMENTAL SUMMARY STATISTICS ===\n")

departmental_estimates <- tibble(
  Department = departments,
  Prevalence = map_dbl(dept_posterior_list, ~ median(.x)),
  `Lower_95_CrI` = map_dbl(dept_posterior_list, ~ quantile(.x, probs = 0.025)),
  `Upper_95_CrI` = map_dbl(dept_posterior_list, ~ quantile(.x, probs = 0.975))
) %>%
  arrange(desc(Prevalence))  # Sort by Prevalence descending

cat("✓ Departmental estimates calculated\n")
cat("  Number of departments: ", nrow(departmental_estimates), "\n\n")

# ------------------------------------------------------------------------------
# 5. CALCULATE NATIONAL AGGREGATED ESTIMATE (POPULATION WEIGHTED)
# ------------------------------------------------------------------------------

cat("=== CALCULATING NATIONAL POPULATION-WEIGHTED ESTIMATE ===\n")

# Prepare data with population weights
cat("Preparing data with population weights...\n")

if (use_raw_pop) {
  # Merge population weights with data
  data_with_pop <- data %>%
    left_join(raw_pop, by = c("DPNOM", "Year"))
} else {
  # Use existing population data
  data_with_pop <- data
}

# Check if Pob40_Depto column exists
if (!"Pob40_Depto" %in% names(data_with_pop)) {
  stop("ERROR: Pob40_Depto column not found. Available columns: ", 
       paste(names(data_with_pop), collapse = ", "))
}

# Remove any missing population data
data_with_pop <- data_with_pop %>%
  filter(!is.na(Pob40_Depto))

cat("  Final dataset: ", nrow(data_with_pop), " rows with population data\n")

# Verify we have population data for all observations
cat("  After filtering NAs: ", nrow(data_with_pop), " rows\n")
if (nrow(data_with_pop) != nrow(data)) {
  cat("⚠ WARNING: Some observations missing population data\n")
  cat("  Data rows: ", nrow(data), ", With population: ", nrow(data_with_pop), "\n")
} else {
  cat("✓ All observations have population data\n")
}
cat("\n")

# For each posterior draw, calculate weighted national average
cat("Calculating population-weighted national estimates for each draw...\n")

national_posterior <- numeric(n_draws)

for (draw in 1:n_draws) {
  # Get true prevalence for this draw (all observations)
  draw_prevalence <- true_prevalence_posterior[draw, ]
  
  # Calculate weighted average: Sum(Dept_Prevalence * Dept_Pop40) / Sum(Dept_Pop40)
  # Match by observation index
  if (length(draw_prevalence) == nrow(data_with_pop)) {
    weighted_sum <- sum(draw_prevalence * data_with_pop$Pob40_Depto)
    total_pop <- sum(data_with_pop$Pob40_Depto)
    national_posterior[draw] <- weighted_sum / total_pop
  } else {
    # If dimensions don't match, use available data
    n_available <- min(length(draw_prevalence), nrow(data_with_pop))
    weighted_sum <- sum(draw_prevalence[1:n_available] * 
                       data_with_pop$Pob40_Depto[1:n_available])
    total_pop <- sum(data_with_pop$Pob40_Depto[1:n_available])
    national_posterior[draw] <- weighted_sum / total_pop
  }
  
  if (draw %% 1000 == 0) {
    cat("  Processed ", draw, " / ", n_draws, " draws\n")
  }
}

cat("✓ National posterior distribution calculated\n\n")

# Calculate summary statistics for national estimate
national_estimate <- tibble(
  Region = "Colombia",
  Prevalence = median(national_posterior),
  `Lower_95_CrI` = quantile(national_posterior, probs = 0.025),
  `Upper_95_CrI` = quantile(national_posterior, probs = 0.975)
)

cat("✓ National estimate calculated\n\n")

# ------------------------------------------------------------------------------
# 6. FORMAT & SAVE TABLES
# ------------------------------------------------------------------------------

cat("=== FORMATTING AND SAVING TABLES ===\n")

# Format the 95% CrI as a single column
national_table <- national_estimate %>%
  mutate(
    `95% CrI` = paste0("[", 
                       sprintf("%.4f", Lower_95_CrI), 
                       ", ", 
                       sprintf("%.4f", Upper_95_CrI), 
                       "]"),
    Prevalence = sprintf("%.4f", Prevalence),
    Department = NA_character_  # Add Department column for consistency
  ) %>%
  select(Region, Prevalence, `95% CrI`, Department)

departmental_table <- departmental_estimates %>%
  mutate(
    `95% CrI` = paste0("[", 
                       sprintf("%.4f", Lower_95_CrI), 
                       ", ", 
                       sprintf("%.4f", Upper_95_CrI), 
                       "]"),
    Prevalence = sprintf("%.4f", Prevalence),
    Region = NA_character_  # Add Region column for consistency
  ) %>%
  select(Region, Prevalence, `95% CrI`, Department)

# Combine tables (National first, then Departmental)
final_table <- bind_rows(
  national_table,
  departmental_table
) %>%
  # Reorder columns: Region/Department, Prevalence, 95% CrI
  select(Region, Department, Prevalence, `95% CrI`)

# Save to CSV
write.csv(final_table, 
          file = "outputs/tables/final_manuscript_tables.csv",
          row.names = FALSE)

cat("✓ Final manuscript tables saved to: outputs/tables/final_manuscript_tables.csv\n\n")

# ------------------------------------------------------------------------------
# 7. PRINT VERIFICATION
# ------------------------------------------------------------------------------

cat("═══════════════════════════════════════════════════════════════\n")
cat("                    VERIFICATION REPORT\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("=== NATIONAL ESTIMATE ===\n")
cat("Region: ", national_estimate$Region, "\n")
cat("Prevalence: ", sprintf("%.4f", national_estimate$Prevalence), "\n")
cat("95% CrI: [", sprintf("%.4f", national_estimate$Lower_95_CrI), 
    ", ", sprintf("%.4f", national_estimate$Upper_95_CrI), "]\n\n")

cat("=== TOP 3 DEPARTMENTS BY PREVALENCE ===\n")
top3 <- head(departmental_estimates, 3)
for (i in 1:nrow(top3)) {
  cat("\n", i, ". ", top3$Department[i], "\n", sep = "")
  cat("   Prevalence: ", sprintf("%.4f", top3$Prevalence[i]), "\n")
  cat("   95% CrI: [", sprintf("%.4f", top3$Lower_95_CrI[i]), 
      ", ", sprintf("%.4f", top3$Upper_95_CrI[i]), "]\n")
}

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("                    SCRIPT COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════\n")

