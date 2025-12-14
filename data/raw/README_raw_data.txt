═══════════════════════════════════════════════════════════════
                    RAW DATA DIRECTORY
              IMMUTABLE SOURCE OF TRUTH
═══════════════════════════════════════════════════════════════

DATA GOVERNANCE MANIFESTO
───────────────────────────────────────────────────────────────

This directory contains the PRIMARY, IMMUTABLE source data for the 
COPD Prevalence Bayesian Analysis project. Files in this directory 
are considered the definitive source of truth and MUST NOT be 
modified under any circumstances.

PRIMARY DATA FILE
───────────────────────────────────────────────────────────────

File Name: copd_epidemiological_data_raw.xlsx

This Excel workbook contains aggregated, department-level 
epidemiological and administrative data for Colombia, covering the 
period 2020-2023. The data are derived from multiple national 
health information systems and demographic sources, aggregated at 
the department level to ensure privacy and confidentiality.

DATA CHARACTERISTICS
───────────────────────────────────────────────────────────────

• Data Type: Aggregated administrative records (non-identifiable)
• Geographic Unit: Department (Departamento) - 33 departments + Bogotá D.C.
• Temporal Coverage: 2020-2023 (4 years)
• Observation Level: Department-Year (132 total observations)
• Privacy Status: Fully anonymized and aggregated (no individual records)

EXPECTED FILE STRUCTURE
───────────────────────────────────────────────────────────────

The Excel file (copd_epidemiological_data_raw.xlsx) is expected to 
contain the following structure:

Worksheet: [Main/Default Sheet]
  • Contains all variables in a single table format
  • Rows: Department-Year combinations (132 observations)
  • Columns: 45 variables including:
    - Geographic identifiers (DPNOM, Cod_Capital, DP, Nom_Capital)
    - Temporal identifier (Year)
    - Population indicators (Poblacion_Depto, Pob40_Depto, etc.)
    - Health indicators (Espiro_NalTasa, Letalidad, Tasa_pts, etc.)
    - Socioeconomic indicators (IPM, Estufa, Porc40_may)
    - Prevalence measures (Prev_Total)
    - Legacy adjustment factors (Factor_Ajuste, Vero_Ajuste) 
      [Note: These are deprecated and replaced by R-calculated values]

DATA INTEGRITY AND VERIFICATION
───────────────────────────────────────────────────────────────

Data integrity is automatically verified by the preprocessing script:

  Script: analysis/00_data_preprocessing.R
  Verification Steps:
    1. File existence check
    2. Column name validation
    3. Data type verification
    4. Missing value detection
    5. Range validation for key variables
    6. Consistency checks across related variables

The preprocessing script generates a clean, analysis-ready dataset 
(data/processed/copd_analysis_ready_data.csv) with:
  • Standardized English variable names
  • Calculated bias-correction factors (adjustment_factor)
  • Data quality flags and filtering

IMPORTANT: Do NOT manually edit this file. All data transformations 
must be performed through the reproducible R scripts in the 
analysis/ directory.

DATA PROVENANCE
───────────────────────────────────────────────────────────────

Source Data Systems:
  • RIPS/SISPRO: Health service utilization and diagnostic procedures
  • DANE Vital Statistics: Mortality data (ICD-10: J44.x)
  • DANE ECV/Census: Demographic and socioeconomic indicators
  • DANE Population Projections: Age structure and population counts

For detailed variable definitions and provenance, see:
  docs/data_dictionary.md

VERSION CONTROL
───────────────────────────────────────────────────────────────

This file represents the version of the data used for the analysis 
as of the project execution date. If the source data systems are 
updated, a new version of this file should be created with a 
version identifier (e.g., copd_epidemiological_data_raw_v2.xlsx) 
and the analysis should be re-run to ensure reproducibility.

BACKUP AND ARCHIVAL
───────────────────────────────────────────────────────────────

• This file is tracked in version control (Git) for reproducibility
• Original source files should be archived separately
• Any updates to this file must be documented in the project 
  changelog

ACCESS CONTROL
───────────────────────────────────────────────────────────────

This directory contains aggregated, non-identifiable data. However, 
access should be restricted to authorized project personnel to 
maintain data governance standards.

CONTACT
───────────────────────────────────────────────────────────────

For questions regarding:
  • Data access: Contact project data steward
  • Data definitions: See docs/data_dictionary.md
  • Data processing: See analysis/00_data_preprocessing.R

═══════════════════════════════════════════════════════════════
Last Updated: 2024-12-13
Project: COPD Prevalence Bayesian Analysis - Colombia
═══════════════════════════════════════════════════════════════
