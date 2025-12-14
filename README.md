# Estimation of COPD Prevalence in Colombia Accounting for Diagnostic Access

![R Status](https://img.shields.io/badge/R%20Status-Working-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Data](https://img.shields.io/badge/Data-Open-success)

## Executive Summary

This repository contains a Bayesian epidemiological analysis that estimates the true prevalence of Chronic Obstructive Pulmonary Disease (COPD) in Colombia while accounting for systematic underdiagnosis due to limited diagnostic access. The analysis employs a **Bayesian Generalized Additive Model (GAM)** to correct for bias introduced by regional variations in spirometry capacity, healthcare access, and case fatality rates.

The model addresses a critical public health challenge: reported prevalence rates are systematically underestimated in regions with limited diagnostic infrastructure. By incorporating administrative benchmarks and demographic covariates, we generate **bias-corrected prevalence estimates** with full uncertainty quantification through 95% Credible Intervals (CrI).

## Key Findings

### National Prevalence
- **Population-Weighted National Prevalence: 2.22%** (95% CrI: 1.98% - 2.47%)
- This represents a significant upward adjustment from raw administrative data, reflecting the true burden of undiagnosed COPD cases.

### Regional Burden
The highest estimated prevalence is observed in:
- **Caldas: 3.50%** (95% CrI: 3.12% - 3.89%)
- **Boyacá: 3.42%** (95% CrI: 3.05% - 3.80%)
- **Risaralda: 3.38%** (95% CrI: 3.01% - 3.76%)

These regions exhibit elevated prevalence despite moderate reported rates, indicating substantial underdiagnosis.

### Model Performance
- **Leave-One-Out Information Criterion (LOOIC): -461.1**
- This robust fit metric indicates excellent model performance and predictive accuracy.
- All MCMC chains converged (Rhat < 1.01) with adequate effective sample sizes.

## Repository Structure

```
.
├── analysis/
│   ├── 00_data_preprocessing.R              # ETL pipeline: Cleans raw data & calculates bias correction factors
│   ├── 01_copd_prevalence_bayesian_model.R  # Main analysis: Trains the Bayesian GAM (brms)
│   ├── 02_generate_final_tables.R           # Post-processing: Generates tables with 95% CrI
│   ├── 03_model_diagnostics_report.R        # Validation: Generates traceplots, PPCs, and audit logs
│   └── 04_manuscript_figures_high_res.R     # Visualization: Generates publication-quality figures
├── data/
│   ├── raw/
│   │   ├── copd_epidemiological_data_raw.xlsx  # Primary Input: Aggregated administrative records
│   │   └── README_raw_data.txt                 # Data governance documentation
│   └── processed/
│       └── copd_analysis_ready_data.csv        # Analysis-Ready Data: Standardized & English-labeled
├── docs/
│   └── data_dictionary.md                      # Detailed variable definitions and provenance
├── models/
│   └── final_model.rds                         # Compiled Bayesian Model Object (Production Ready)
├── outputs/
│   ├── audit_report/                           # Model Diagnostics (Traceplots, Posterior Checks)
│   ├── figures/                                # Publication-Quality Visualizations
│   └── tables/                                 # Final Manuscript Tables (Prevalence Estimates)
└── README.md                                   # Master Project Documentation
```

### Directory Descriptions

**`analysis/`** - Analysis Scripts (Execute in numerical order)
- `00_data_preprocessing.R`: ETL pipeline that loads raw Excel data, calculates composite bias-correction multipliers using administrative thresholds (Spirometry Target: 1105.08 per 100k, Lethality Q3, Access Q1), and generates the analysis-ready dataset with standardized English variable names.
- `01_copd_prevalence_bayesian_model.R`: Main Bayesian analysis script. Trains a Gamma GAM with log link using `brms`, incorporating smooth spline terms (k=5) for continuous predictors. Saves the compiled model object and generates fixed effects tables.
- `02_generate_final_tables.R`: Post-processing script that uses posterior predictive distributions to calculate department-level and population-weighted national prevalence estimates with 95% Credible Intervals (CrI). Generates manuscript-ready tables.
- `03_model_diagnostics_report.R`: Model validation and audit script. Generates traceplots for convergence assessment, posterior predictive checks for model fit validation, conditional effects plots for spline visualization, and comprehensive numerical summaries.
- `04_manuscript_figures_high_res.R`: High-resolution figure generation script. Creates publication-quality visualizations including choropleth maps, correlation plots, and benchmark comparisons (300 dpi PNG and vector PDF formats).

**`data/raw/`** - Immutable Source Data
- `copd_epidemiological_data_raw.xlsx`: Primary data file containing aggregated department-level indicators (2020-2023) from RIPS/SISPRO, DANE Vital Statistics, and demographic sources. This file is the immutable source of truth and must not be modified.
- `README_raw_data.txt`: Data governance documentation specifying data provenance, integrity verification procedures, and expected file structure.

**`data/processed/`** - Analysis-Ready Data
- `copd_analysis_ready_data.csv`: Clean, standardized dataset with English variable names, calculated `adjustment_factor`, and all quality checks applied. This is the definitive input for all modeling steps.

**`docs/`** - Documentation
- `data_dictionary.md`: Comprehensive variable definitions including original source fields, epidemiological definitions, units, data roles (predictor/response/metadata), and detailed data provenance from national health information systems.

**`models/`** - Trained Model Objects
- `final_model.rds`: Compiled Bayesian GAM model object. Contains the full posterior distribution, model specification, and can be reloaded for predictions or further analysis without retraining.

**`outputs/audit_report/`** - Model Validation Artifacts
- Contains traceplots (`02_convergence_traceplots.png`), Rhat diagnostics (`02_rhat_plot.png`), posterior predictive checks (`03_posterior_predictive_check.png`), conditional effects plots for each predictor (`04_effect_*.png`), model specification (`01_model_specification.txt`), and full numerical summary (`05_full_numerical_summary.txt`).

**`outputs/figures/`** - Publication-Quality Visualizations
- `Fig1_PartA_Mainland.png/pdf`: Mainland Colombia choropleth maps (Reported vs. Estimated prevalence)
- `Fig1_PartB_SanAndres.png/pdf`: San Andrés y Providencia inset map
- `Fig2_Spirometry_Correlation.png/pdf`: Correlation between spirometry capacity and reported prevalence
- `Fig3_Spirometry_Benchmark.png/pdf`: Department-level spirometry rates vs. national benchmark

**`outputs/tables/`** - Final Results
- `final_manuscript_tables.csv`: Department-level and national prevalence estimates with 95% CrI, ready for manuscript inclusion.
- `bayesian_model_summary.csv`: Fixed effects table with coefficients, credible intervals, and convergence diagnostics.
- `departmental_prevalence_estimates.csv`: Detailed department-year level predictions and observed values.

## Reproducibility Instructions

This project adheres to **TIER (Transparency and Reproducibility in Research)** protocol standards and **TRIPOD (Transparent Reporting of a Multivariable Prediction Model for Individual Prognosis or Diagnosis)** reporting guidelines.

### Prerequisites

- **R Version**: 4.x or higher
- **Required R Packages**:
  - `tidyverse` (v2.0.0+) - Data manipulation and visualization
  - `brms` (v2.20.0+) - Bayesian regression modeling with Stan
  - `bayesplot` (v1.10.0+) - Bayesian model diagnostics
  - `loo` (v2.6.0+) - Leave-one-out cross-validation
  - `readxl` - Excel file reading
  - `patchwork` - Figure layout
  - `ggpubr` - Publication-quality graphics
  - `ggrepel` - Text label positioning
  - `viridis` - Color-blind friendly palettes

Install dependencies:
```r
install.packages(c("tidyverse", "brms", "bayesplot", "loo", "readxl", 
                   "patchwork", "ggpubr", "ggrepel", "viridis"))
```

**Note**: For spatial visualizations (Figure 1), additional system dependencies are required. See `INSTALL_SPATIAL_PACKAGES.md` for installation instructions.

### Step-by-Step Execution

Execute scripts in numerical order:

#### Step 1: Data Preprocessing
```r
source("analysis/00_data_preprocessing.R")
```
**What it does:**
- Loads raw Excel data from `data/raw/copd_epidemiological_data_raw.xlsx`
- Calculates `adjustment_factor` using administrative benchmarks:
  - Spirometry Score: Penalty if rate < 1105.08 per 100k
  - Lethality Score: Penalty if rate > Q3 threshold
  - Access Score: Penalty if rate < Q1 threshold
- Standardizes variable names (Spanish → English)
- Saves clean dataset to `data/processed/copd_analysis_ready_data.csv`

**Expected output:**
- `data/processed/copd_analysis_ready_data.csv` (clean dataset)
- Console summary of `adjustment_factor` distribution

#### Step 2: Bayesian Model Training
```r
source("analysis/01_copd_prevalence_bayesian_model.R")
```
**What it does:**
- Loads processed data
- Trains Bayesian GAM with Gamma family (log link)
- Smooth splines (k=5) for continuous predictors
- MCMC sampling: 4 chains × 4000 iterations
- Saves model object to `models/final_model.rds`
- Generates fixed effects table

**Expected output:**
- `models/final_model.rds` (compiled model, ~33 MB)
- `outputs/tables/bayesian_model_summary.csv` (coefficients table)
- Console message: "Model training started..." followed by progress updates

**Runtime:** ~7-10 minutes (depending on hardware)

#### Step 3: Generate Final Tables
```r
source("analysis/02_generate_final_tables.R")
```
**What it does:**
- Loads trained model and processed data
- Generates posterior predictions for all departments
- Calculates "True Prevalence Posterior" (adjustment_factor × total_prevalence)
- Aggregates to department-level medians (2020-2023)
- Calculates population-weighted national estimate
- Formats tables with 95% Credible Intervals

**Expected output:**
- `outputs/tables/final_manuscript_tables.csv` (national + departmental estimates)
- Console print of national estimate and top 3 departments

#### Step 4: Model Diagnostics (Optional but Recommended)
```r
source("analysis/03_model_diagnostics_report.R")
```
**What it does:**
- Loads trained model
- Generates convergence diagnostics (traceplots, Rhat plots)
- Performs posterior predictive checks
- Visualizes conditional effects of splines
- Saves comprehensive audit report

**Expected output:**
- `outputs/audit_report/` directory with all validation artifacts

#### Step 5: Generate Figures (Optional)
```r
source("analysis/04_manuscript_figures_high_res.R")
```
**What it does:**
- Generates publication-quality figures (300 dpi PNG + vector PDF)
- Creates choropleth maps, correlation plots, and benchmark visualizations

**Expected output:**
- `outputs/figures/` directory with all manuscript figures

## Methodology

### Model Specification

- **Family**: Gamma distribution with log link (for right-skewed positive prevalence data)
- **Response Variable**: `adjustment_factor` (Composite Bias-Correction Multiplier)
- **Predictors**:
  - Smooth splines (k=5) for: `spirometry_rate`, `lethality_rate`, `patients_rate`, `biomass_stove_usage`, `multidimensional_poverty_index`, `pop_over_40_percent`
  - Linear term: `total_prevalence`
- **Priors**: Weakly informative normal(0, 1) prior on intercept
- **Sampling**: 4 chains, 4000 iterations per chain (warmup: 2000)
- **Convergence**: adapt_delta = 0.999 for improved sampling efficiency

### Variable Definitions

See `docs/data_dictionary.md` for complete variable mapping, definitions, units, and data provenance.

## Outputs

### Primary Results
- **Final Manuscript Tables** (`outputs/tables/final_manuscript_tables.csv`): Department-level and national prevalence estimates with 95% Credible Intervals
- **Model Summary** (`outputs/tables/bayesian_model_summary.csv`): Fixed effects coefficients table for manuscript/review

### Model Artifacts
- **Trained Model** (`models/final_model.rds`): Compiled Bayesian GAM - can be reloaded for predictions
- **Audit Reports** (`outputs/audit_report/`): Complete model validation including traceplots, posterior predictive checks, and conditional effects visualizations

### Visualizations
- **Figure 1** (`outputs/figures/Fig1_PartA_Mainland.*`, `Fig1_PartB_SanAndres.*`): Choropleth maps of reported vs. estimated prevalence
- **Figure 2** (`outputs/figures/Fig2_Spirometry_Correlation.*`): Correlation between spirometry capacity and reported prevalence
- **Figure 3** (`outputs/figures/Fig3_Spirometry_Benchmark.*`): Department-level spirometry rates vs. national benchmark

## Citation

If you use this code or methodology in your research, please cite:

```bibtex
@software{ospina2025copd,
  title = {Estimation of COPD Prevalence in Colombia Accounting for Diagnostic Access},
  author = {Ospina, Jorge and García-Morales, Oscar M. and Gaviria, María C.},
  year = {2025},
  url = {https://github.com/[username]/copd-colombia-prevalence},
  note = {Bayesian epidemiological analysis using Generalized Additive Models}
}
```

Or in text format:

> Ospina J, García-Morales OM, Gaviria MC. Estimation of COPD Prevalence in Colombia Accounting for Diagnostic Access [Computer software]. 2025. Available from: https://github.com/[username]/copd-colombia-prevalence

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Authors

- **Jorge Ospina, MD** - Principal Investigator
- **Oscar M. García-Morales** - Co-author
- **María C. Gaviria** - Co-author

## Acknowledgments

- Data sources: RIPS/SISPRO (Colombian Health Information System), DANE (National Statistics Department)
- Methodology: Bayesian modeling framework using `brms` and Stan
- Reproducibility standards: TIER Protocol, TRIPOD Guidelines

## Contact

For questions or collaboration inquiries, please open an issue on GitHub or contact the corresponding author.

---

**Note**: This repository follows open science principles. All code, data processing steps, and model specifications are fully transparent and reproducible.
