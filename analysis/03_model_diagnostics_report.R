# ==============================================================================
# Model Diagnostics and Audit Report Script
# ==============================================================================
# Project: Bayesian Epidemiological Study on COPD Prevalence in Colombia
# Author: [Your Name]
# Date: [Date]
# 
# Description: This script performs comprehensive model auditing to prove
#              model validity through transparency, reliability, and predictive
#              accuracy checks.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SETUP
# ------------------------------------------------------------------------------

library(brms)
library(ggplot2)
library(bayesplot)
library(tidyverse)

# Set bayesplot theme
bayesplot_theme_set(theme_default())

cat("=== MODEL DIAGNOSTICS AND AUDIT REPORT ===\n\n")

# Create audit report directory
if (!dir.exists("outputs/audit_report")) {
  dir.create("outputs/audit_report", recursive = TRUE)
  cat("✓ Created directory: outputs/audit_report\n")
} else {
  cat("✓ Directory exists: outputs/audit_report\n")
}

# Load the model - check for both possible filenames
model_file <- NULL
if (file.exists("models/final_model.rds")) {
  model_file <- "models/final_model.rds"
  cat("\n✓ Found model file: models/final_model.rds\n")
} else if (file.exists("models/copd_prevalence_final_model.rds")) {
  model_file <- "models/copd_prevalence_final_model.rds"
  cat("\n✓ Found model file: models/copd_prevalence_final_model.rds\n")
} else {
  stop("ERROR: Model file not found. Please check models/ directory.")
}

cat("Loading model...\n")
model <- readRDS(model_file)
cat("✓ Model loaded successfully\n")
cat("  Model class: ", class(model)[1], "\n")
cat("  Formula: ", as.character(model$formula)[1], "\n\n")

# ------------------------------------------------------------------------------
# 2. AUDIT 1: MATHEMATICAL SPECIFICATION (TRANSPARENCY)
# ------------------------------------------------------------------------------

cat("=== AUDIT 1: MATHEMATICAL SPECIFICATION ===\n")

# Extract STAN code
cat("Extracting STAN code...\n")
stan_code <- stancode(model)

# Extract Priors
cat("Extracting prior specifications...\n")
prior_spec <- prior_summary(model)

# Save to text file
output_file <- "outputs/audit_report/01_model_specification.txt"
cat("Saving to: ", output_file, "\n")

sink(output_file)
cat("═══════════════════════════════════════════════════════════════\n")
cat("           MODEL MATHEMATICAL SPECIFICATION\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("MODEL FORMULA:\n")
cat("───────────────────────────────────────────────────────────────\n")
print(model$formula)
cat("\n\n")

cat("PRIOR SPECIFICATIONS:\n")
cat("───────────────────────────────────────────────────────────────\n")
print(prior_spec)
cat("\n\n")

cat("STAN CODE:\n")
cat("───────────────────────────────────────────────────────────────\n")
cat(stan_code)
cat("\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("END OF SPECIFICATION\n")
cat("═══════════════════════════════════════════════════════════════\n")
sink()

cat("✓ Model specification saved\n\n")

# ------------------------------------------------------------------------------
# 3. AUDIT 2: MCMC CONVERGENCE (RELIABILITY)
# ------------------------------------------------------------------------------

cat("=== AUDIT 2: MCMC CONVERGENCE ===\n")

# Get posterior samples for key parameters
cat("Extracting posterior samples...\n")
posterior_samples <- posterior_samples(model)

# Get summary to check Rhat values
model_summary <- summary(model)
fixed_effects <- model_summary$fixed

cat("Checking Rhat values (should be < 1.01 for convergence)...\n")
max_rhat <- max(fixed_effects$Rhat, na.rm = TRUE)
cat("  Maximum Rhat: ", round(max_rhat, 4), "\n")
if (max_rhat < 1.01) {
  cat("  ✓ All Rhat values indicate good convergence\n")
} else {
  cat("  ⚠ WARNING: Some Rhat values > 1.01 - check convergence\n")
}

# Generate trace plots for key parameters
cat("Generating trace plots...\n")

# Select key parameters to plot
key_params <- c("b_Intercept", "b_total_prevalence")
# Also include first smooth term if available
smooth_params <- grep("^bs_", names(posterior_samples), value = TRUE)
if (length(smooth_params) > 0) {
  key_params <- c(key_params, smooth_params[1])
}

# Filter to available parameters
key_params <- key_params[key_params %in% names(posterior_samples)]

if (length(key_params) > 0) {
  # Create trace plots
  png("outputs/audit_report/02_convergence_traceplots.png", 
      width = 12, height = 8, units = "in", res = 300)
  
  # Use bayesplot for trace plots
  trace_plots <- mcmc_trace(posterior_samples, pars = key_params, 
                            facet_args = list(ncol = 1))
  print(trace_plots)
  
  dev.off()
  cat("✓ Trace plots saved to: outputs/audit_report/02_convergence_traceplots.png\n")
} else {
  cat("⚠ Could not generate trace plots - parameter names not found\n")
}

# Generate Rhat plot
cat("Generating Rhat plot...\n")
tryCatch({
  png("outputs/audit_report/02_rhat_plot.png", 
      width = 10, height = 6, units = "in", res = 300)
  
  rhat_plot <- mcmc_rhat(fixed_effects$Rhat)
  print(rhat_plot)
  
  dev.off()
  cat("✓ Rhat plot saved to: outputs/audit_report/02_rhat_plot.png\n")
}, error = function(e) {
  cat("⚠ Could not generate Rhat plot: ", e$message, "\n")
})

cat("\n")

# ------------------------------------------------------------------------------
# 4. AUDIT 3: MODEL FIT (PREDICTIVE ACCURACY)
# ------------------------------------------------------------------------------

cat("=== AUDIT 3: MODEL FIT (POSTERIOR PREDICTIVE CHECK) ===\n")

cat("Running posterior predictive check...\n")
cat("  This may take a few moments...\n")

tryCatch({
  # Generate posterior predictive check
  pp_check_result <- pp_check(model, ndraws = 100)
  
  # Save plot
  ggsave("outputs/audit_report/03_posterior_predictive_check.png",
         plot = pp_check_result,
         width = 10, height = 6, units = "in", dpi = 300)
  
  cat("✓ Posterior predictive check saved to: outputs/audit_report/03_posterior_predictive_check.png\n")
}, error = function(e) {
  cat("⚠ Error in posterior predictive check: ", e$message, "\n")
  cat("  Attempting alternative method...\n")
  
  tryCatch({
    # Alternative: simpler pp_check
    pp_check_result <- pp_check(model)
    ggsave("outputs/audit_report/03_posterior_predictive_check.png",
           plot = pp_check_result,
           width = 10, height = 6, units = "in", dpi = 300)
    cat("✓ Posterior predictive check saved (alternative method)\n")
  }, error = function(e2) {
    cat("✗ Could not generate posterior predictive check\n")
  })
})

cat("\n")

# ------------------------------------------------------------------------------
# 5. AUDIT 4: VISUALIZING SPLINES (OPENING THE BLACK BOX)
# ------------------------------------------------------------------------------

cat("=== AUDIT 4: VISUALIZING CONDITIONAL EFFECTS (SPLINES) ===\n")

# Get list of smooth terms from the model
smooth_terms <- c("spirometry_rate", "lethality_rate", "patients_rate",
                  "biomass_stove_usage", "multidimensional_poverty_index",
                  "pop_over_40_percent")

cat("Generating conditional effects plots for each predictor...\n")

for (term in smooth_terms) {
  cat("  Processing: ", term, "...\n")
  
  tryCatch({
    # Generate conditional effects
    ce <- conditional_effects(model, effects = term, 
                               re_formula = NA, 
                               resolution = 100)
    
    # Extract the plot
    p <- plot(ce, plot = FALSE)[[1]]
    
    # Add title and formatting
    p <- p + 
      labs(title = paste("Conditional Effect of", term),
           subtitle = "Holding other variables constant") +
      theme_minimal() +
      theme(plot.title = element_text(size = 14, face = "bold"),
            plot.subtitle = element_text(size = 12))
    
    # Save plot
    filename <- paste0("outputs/audit_report/04_effect_", term, ".png")
    ggsave(filename, plot = p, width = 10, height = 6, units = "in", dpi = 300)
    
    cat("    ✓ Saved: ", filename, "\n")
  }, error = function(e) {
    cat("    ⚠ Error for ", term, ": ", e$message, "\n")
  })
}

# Also plot total_prevalence (linear term)
cat("  Processing: total_prevalence (linear term)...\n")
tryCatch({
  ce <- conditional_effects(model, effects = "total_prevalence",
                             re_formula = NA,
                             resolution = 100)
  p <- plot(ce, plot = FALSE)[[1]]
  p <- p + 
    labs(title = "Conditional Effect of total_prevalence",
         subtitle = "Linear term (holding other variables constant)") +
    theme_minimal() +
    theme(plot.title = element_text(size = 14, face = "bold"),
          plot.subtitle = element_text(size = 12))
  
  ggsave("outputs/audit_report/04_effect_total_prevalence.png",
         plot = p, width = 10, height = 6, units = "in", dpi = 300)
  cat("    ✓ Saved: outputs/audit_report/04_effect_total_prevalence.png\n")
}, error = function(e) {
  cat("    ⚠ Error for total_prevalence: ", e$message, "\n")
})

cat("✓ Conditional effects plots generated\n\n")

# ------------------------------------------------------------------------------
# 6. AUDIT 5: NUMERICAL SUMMARY
# ------------------------------------------------------------------------------

cat("=== AUDIT 5: FULL NUMERICAL SUMMARY ===\n")

cat("Generating comprehensive numerical summary...\n")

output_file <- "outputs/audit_report/05_full_numerical_summary.txt"
sink(output_file)

cat("═══════════════════════════════════════════════════════════════\n")
cat("           FULL NUMERICAL MODEL SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("MODEL SUMMARY:\n")
cat("───────────────────────────────────────────────────────────────\n")
print(summary(model))

cat("\n\nFIXED EFFECTS:\n")
cat("───────────────────────────────────────────────────────────────\n")
print(fixed_effects)

cat("\n\nRANDOM EFFECTS (if any):\n")
cat("───────────────────────────────────────────────────────────────\n")
if (!is.null(model_summary$random)) {
  print(model_summary$random)
} else {
  cat("No random effects in this model.\n")
}

cat("\n\nSMOOTH TERMS:\n")
cat("───────────────────────────────────────────────────────────────\n")
if (!is.null(model_summary$splines)) {
  print(model_summary$splines)
} else {
  cat("Smooth terms information available in fixed effects.\n")
}

cat("\n\nCONVERGENCE DIAGNOSTICS:\n")
cat("───────────────────────────────────────────────────────────────\n")
cat("Maximum Rhat: ", round(max_rhat, 4), "\n")
cat("Minimum ESS (Bulk): ", round(min(fixed_effects$Bulk_ESS, na.rm = TRUE), 0), "\n")
cat("Minimum ESS (Tail): ", round(min(fixed_effects$Tail_ESS, na.rm = TRUE), 0), "\n")

cat("\n\nMODEL FIT STATISTICS:\n")
cat("───────────────────────────────────────────────────────────────\n")
tryCatch({
  loo_result <- loo(model)
  print(loo_result)
}, error = function(e) {
  cat("LOO calculation not available: ", e$message, "\n")
})

cat("\n\n═══════════════════════════════════════════════════════════════\n")
cat("END OF NUMERICAL SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════\n")
sink()

cat("✓ Full numerical summary saved to: ", output_file, "\n\n")

# ------------------------------------------------------------------------------
# 7. FINAL REPORT SUMMARY
# ------------------------------------------------------------------------------

cat("═══════════════════════════════════════════════════════════════\n")
cat("                    AUDIT REPORT COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Generated files in outputs/audit_report/:\n")
audit_files <- list.files("outputs/audit_report", full.names = FALSE)
for (file in sort(audit_files)) {
  file_path <- file.path("outputs/audit_report", file)
  file_size <- file.info(file_path)$size
  cat("  ✓ ", file, " (", round(file_size/1024, 2), " KB)\n", sep = "")
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("All audit artifacts are ready for inspection.\n")
cat("═══════════════════════════════════════════════════════════════\n")

