# Data Dictionary

## Overview

This dataset contains aggregated, department-level epidemiological and administrative indicators for Chronic Obstructive Pulmonary Disease (COPD) in Colombia, covering the period 2020-2023. The data are derived from multiple national health information systems and demographic sources, aggregated at the department (departamento) level to ensure privacy and confidentiality. This dataset serves as the foundation for a Bayesian epidemiological analysis estimating COPD prevalence while accounting for diagnostic capacity, healthcare access, and socioeconomic determinants.

**Temporal Coverage:** 2020-2023  
**Geographic Unit:** Department (Departamento) - 33 departments + Bogotá D.C.  
**Observation Level:** Department-Year (132 total observations)  
**Data Type:** Aggregated administrative records (non-identifiable)

---

## Variable Definitions

| Variable Name | Original Source Field | Definition | Units | Role |
|--------------|----------------------|------------|-------|------|
| `adjustment_factor` | *Calculated* | **Composite Bias-Correction Multiplier.** Derived from Spirometry, Lethality, and Access benchmarks. Calculated as 1 + (Spirometry Score + Lethality Score + Access Score). Represents the multiplicative factor to correct for systematic underdiagnosis. Values ≥ 1.0, where 1.0 indicates no bias and higher values indicate greater underdiagnosis. | Dimensionless (≥1.0) | **Response** |
| `spirometry_rate` | `Espiro_NalTasa` | **Spirometries performed per 100,000 inhabitants.** Source: SISPRO. Measures diagnostic capacity for COPD confirmation via spirometry testing. National administrative benchmark: 1105.08 per 100,000 population aged 40+ years. | Per 100,000 inhabitants (40+ years) | **Predictor** |
| `lethality_rate` | `Letalidad` | **COPD mortality rate per 100,000 cases.** Source: DANE Vital Statistics. Case-fatality ratio calculated as deaths per confirmed case. Higher values indicate more severe disease presentation, delayed diagnosis, or limited treatment access. | Ratio (deaths per case) | **Predictor** |
| `patients_rate` | `Tasa_pts` | Rate of COPD patients per 100,000 population aged 40+ years. Reflects healthcare utilization and case detection. Source: SISPRO. | Per 100,000 inhabitants (40+ years) | **Predictor** |
| `biomass_stove_usage` | `Estufa` | **Proportion of households using solid fuels.** Source: DANE ECV (Encuesta de Calidad de Vida). Measures the proportion of households using biomass fuel (wood, charcoal) for cooking. Major risk factor for COPD in rural and peri-urban settings. | Proportion (0-1) | **Predictor** |
| `multidimensional_poverty_index` | `IPM` | Multidimensional Poverty Index (Índice de Pobreza Multidimensional). Composite measure of deprivation across health, education, and living conditions dimensions. Source: DANE. | Index (0-1, higher = more poverty) | **Predictor** |
| `pop_over_40_percent` | `Porc40_may` | Percentage of department population aged 40 years and older. COPD prevalence increases significantly with age, making this a critical demographic control. Source: DANE Population Projections. | Percentage (0-100) | **Predictor** |
| `total_prevalence` | `Prev_Total` | **Raw reported prevalence.** Source: SISPRO. Observed COPD prevalence rate based on administrative records. Calculated as confirmed cases per population at risk (40+ years). This is the uncorrected prevalence that requires adjustment for diagnostic access bias. | Proportion (0-1) | **Predictor** |
| `DPNOM` | `DPNOM` | Department name (official Spanish name). | Text | **Metadata** |
| `Nom_Capital` | `Nom_Capital` | Capital city name of the department. | Text | **Metadata** |
| `Year` | `Year` | Calendar year of observation (2020, 2021, 2022, 2023). | Year | **Metadata** |
| `Cod_Capital` | `Cod_Capital` | Official administrative code for the capital city (DANE coding system). | Numeric code | **Metadata** |
| `DP` | `DP` | Department code (official DANE coding system). | Numeric code | **Metadata** |
| `Pob40_Depto` | `Pob40_Depto` | Total population aged 40 years and older in the department. Used for population-weighted aggregations. | Count (persons) | **Metadata** |
| `Poblacion_Depto` | `Poblacion_Depto` | Total department population (all ages). | Count (persons) | **Metadata** |

### Derived Variables (Calculated in Preprocessing)

| Variable Name | Calculation Method | Definition | Units | Role |
|--------------|-------------------|------------|-------|------|
| `bias_index_score` | Sum of three penalty scores | Composite index quantifying diagnostic and access barriers. Components: Spirometry Score (if rate < 1105.08), Lethality Score (if rate > Q3), Access Score (if rate < Q1). | Dimensionless (≥0) | **Intermediate** |
| `spirometry_score` | `(1105.08 - Espiro_NalTasa) / 1105.08` if `Espiro_NalTasa < 1105.08`, else 0 | Penalty for suboptimal diagnostic capacity relative to administrative standard (1105.08 per 100,000). | Dimensionless (0-1) | **Intermediate** |
| `lethality_score` | `(Letalidad - Q3) / Q3` if `Letalidad > Q3`, else 0 | Penalty for excess mortality relative to 75th percentile threshold. | Dimensionless (≥0) | **Intermediate** |
| `access_score` | `(Q1 - Tasa_pts) / Q1` if `Tasa_pts < Q1`, else 0 | Penalty for suboptimal healthcare access relative to 25th percentile threshold. | Dimensionless (0-1) | **Intermediate** |

---

## Data Provenance

### Primary Data Sources

#### 1. Health Information Systems (RIPS/SISPRO)
**Source:** Registro Individual de Prestación de Servicios (RIPS) / Sistema Integral de Información de la Protección Social (SISPRO)  
**Variables Derived:**
- `spirometry_rate` (`Espiro_NalTasa`): Spirometry procedures performed
- `patients_rate` (`Tasa_pts`): COPD patient encounters
- `total_prevalence` (`Prev_Total`): Confirmed COPD cases
- Healthcare utilization indicators (ambulatory, hospital, emergency care)

**Aggregation Level:** Department-year  
**Update Frequency:** Annual  
**Data Quality:** Administrative records subject to reporting completeness variations

#### 2. Vital Statistics (DANE)
**Source:** Departamento Administrativo Nacional de Estadística (DANE) - Estadísticas Vitales  
**Variables Derived:**
- `lethality_rate` (`Letalidad`): COPD-related deaths (ICD-10: J44.x)
- Mortality counts by sex and age group

**Aggregation Level:** Department-year  
**Update Frequency:** Annual (with 1-2 year lag for final data)  
**Data Quality:** High completeness for mortality data (>95% coverage)

#### 3. Multidimensional Poverty Index (DANE)
**Source:** DANE - Encuesta de Calidad de Vida (ECV) / Censo Nacional  
**Variables Derived:**
- `multidimensional_poverty_index` (`IPM`): Official multidimensional poverty measure

**Aggregation Level:** Department  
**Update Frequency:** Every 2-3 years (intercensal estimates)  
**Data Quality:** Official statistical product with documented methodology

#### 4. Demographic Data (DANE)
**Source:** DANE - Proyecciones de Población / Censo Nacional de Población y Vivienda  
**Variables Derived:**
- `pop_over_40_percent` (`Porc40_may`): Age structure indicators
- `Pob40_Depto`: Population counts by age group
- `Poblacion_Depto`: Total population estimates

**Aggregation Level:** Department-year  
**Update Frequency:** Annual projections, decennial census  
**Data Quality:** Official demographic estimates with documented projection methodology

#### 5. Household Survey Data (DANE)
**Source:** DANE - Encuesta Nacional de Calidad de Vida (ECV)  
**Variables Derived:**
- `biomass_stove_usage` (`Estufa`): Household cooking fuel type

**Aggregation Level:** Department (survey-weighted estimates)  
**Update Frequency:** Every 2-3 years  
**Data Quality:** Sample-based estimates with design weights

### Data Integration and Processing

All source data are integrated at the department-year level through a standardized ETL pipeline (`analysis/00_data_preprocessing.R`). The preprocessing script:

1. **Validates** data completeness and consistency
2. **Calculates** derived variables (bias correction factors)
3. **Standardizes** variable names (Spanish → English)
4. **Documents** all transformations in reproducible code

### Data Quality Considerations

- **Completeness:** Administrative health data may have reporting gaps, particularly in remote departments
- **Temporal Consistency:** Some indicators (e.g., IPM) are updated less frequently than others
- **Geographic Coverage:** All 33 departments + Bogotá D.C. are included
- **Privacy:** All data are aggregated; no individual-level records are present

### Missing Data Handling

Missing values in key variables result in exclusion from the analysis. The preprocessing script (`analysis/00_data_preprocessing.R`) filters observations with missing values in any of the core predictors or the response variable.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-12-13 | Initial comprehensive data dictionary |

---

## Contact and Data Access

For questions regarding data definitions, provenance, or access to source data, please refer to:
- **Health Data:** Ministerio de Salud y Protección Social (MINSALUD) / SISPRO
- **Demographic Data:** DANE (https://www.dane.gov.co)
- **Project Repository:** [Repository URL]

---

*This data dictionary follows FAIR (Findable, Accessible, Interoperable, Reusable) principles and TIER (Transparency and Reproducibility in Research) protocol standards.*
