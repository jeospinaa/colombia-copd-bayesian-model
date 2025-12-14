# ==============================================================================
# Manuscript Figures: High-Resolution Publication-Quality Visualizations
# ==============================================================================
# Project: Bayesian Epidemiological Study on COPD Prevalence in Colombia
# Author: [Your Name]
# Date: [Date]
# 
# Description: Generates publication-quality figures adhering to biomedical
#              journal standards with high-resolution PNG (300 dpi) and PDF formats.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SETUP AND LIBRARY IMPORTS
# ------------------------------------------------------------------------------

# Check and install required packages
required_packages <- c("tidyverse", "patchwork", "ggpubr", "ggrepel", "viridis", "RColorBrewer")
spatial_packages <- c("sf", "rnaturalearth", "rnaturalearthdata")

# Install basic packages
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# Try to load spatial packages - check R 4.3 library first
# Add R 4.3 library path if it exists (packages may be installed there)
lib_43 <- "/home/jorge/R/x86_64-pc-linux-gnu-library/4.3"
if (dir.exists(lib_43)) {
  .libPaths(c(lib_43, .libPaths()))
  cat("✓ Added R 4.3 library path\n")
}

spatial_available <- TRUE
for (pkg in spatial_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    # Try to install from Posit binary repository
    tryCatch({
      cat("Installing", pkg, "from Posit binary repository...\n")
      options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
      install.packages(pkg, repos = "https://packagemanager.posit.co/cran/__linux__/noble/latest", quiet = FALSE)
      library(pkg, character.only = TRUE)
      cat("✓", pkg, "installed and loaded successfully\n")
    }, error = function(e) {
      cat("⚠ Warning: Could not install", pkg, "- Figure 1 (maps) may not be generated\n")
      cat("  Error:", e$message, "\n")
      spatial_available <<- FALSE
    })
  } else {
    cat("✓", pkg, "already available\n")
  }
}

# Load libraries
library(tidyverse)
library(patchwork)
library(ggpubr)
library(ggrepel)
library(viridis)

# Load spatial libraries if available
if (spatial_available) {
  library(sf)
  library(rnaturalearth)
  library(rnaturalearthdata)
}

cat("=== MANUSCRIPT FIGURES GENERATION ===\n\n")

# Create output directory
if (!dir.exists("outputs/figures")) {
  dir.create("outputs/figures", recursive = TRUE)
  cat("✓ Created directory: outputs/figures\n")
} else {
  cat("✓ Directory exists: outputs/figures\n")
}

# Set global theme
theme_set(theme_minimal(base_size = 11) +
  theme(
    plot.margin = margin(10, 10, 10, 10),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    axis.text = element_text(color = "black"),
    axis.title = element_text(color = "black", face = "bold"),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 12)
  ))

# Color-blind friendly palette
cb_palette <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", 
                "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf")

cat("\n")

# ------------------------------------------------------------------------------
# 2. DATA LOADING
# ------------------------------------------------------------------------------

cat("=== LOADING DATA ===\n")

# Load final manuscript tables (estimates)
cat("Loading prevalence estimates...\n")
estimates <- read_csv("outputs/tables/final_manuscript_tables.csv", 
                      show_col_types = FALSE)

# Load processed data (for observed prevalence and spirometry)
cat("Loading processed data...\n")
data <- read_csv("data/processed/copd_analysis_ready_data.csv", 
                 show_col_types = FALSE)

# Calculate observed prevalence by department (median across years)
observed_prevalence <- data %>%
  group_by(DPNOM) %>%
  summarise(
    total_prevalence = median(total_prevalence, na.rm = TRUE),
    .groups = "drop"
  )

# Prepare estimates data (remove national row, keep only departments)
estimates_dept <- estimates %>%
  filter(!is.na(Department)) %>%
  mutate(
    Prevalence = as.numeric(Prevalence),
    DPNOM = Department
  )

# Standardize department names for matching
# Create a mapping function to match rnaturalearth shapefile names
standardize_names <- function(name) {
  name <- str_trim(name)
  # Map CSV names to shapefile names (rnaturalearth standard)
  name <- case_when(
    # Bogotá variations
    str_detect(name, "Bogotá, D.C.|Bogotá D.C.") ~ "Bogota",
    str_detect(name, "^Bogota$") ~ "Bogota",
    # Quindío - add accent if missing
    str_detect(name, "^Quindio$") ~ "Quindío",
    str_detect(name, "^Quindío$") ~ "Quindío",
    # San Andrés - map to shapefile name
    str_detect(name, "Archipiélago de San Andrés|Archipielago de San Andres") ~ "San Andrés y Providencia",
    str_detect(name, "San Andrés y Providencia") ~ "San Andrés y Providencia",
    # Norte de Santander - ensure correct capitalization
    str_detect(name, "Norte de Santander|Norte De Santander") ~ "Norte de Santander",
    # Other accents (already correct in most cases)
    str_detect(name, "Guainía|Guainia") ~ "Guainía",
    str_detect(name, "Vaupés|Vaupes") ~ "Vaupés",
    # Default: keep as is
    TRUE ~ name
  )
  return(name)
}

# Standardize names in datasets
observed_prevalence <- observed_prevalence %>%
  mutate(DPNOM_std = standardize_names(DPNOM))

estimates_dept <- estimates_dept %>%
  mutate(DPNOM_std = standardize_names(DPNOM))

# Load Colombia administrative boundaries
if (spatial_available) {
  cat("Loading Colombia administrative boundaries...\n")
  tryCatch({
    colombia_sf <- ne_states(country = "colombia", returnclass = "sf")
    
    # Shapefile names are already in standard format, just create DPNOM_std
    colombia_sf <- colombia_sf %>%
      mutate(DPNOM_std = name)  # Shapefile names are the standard
    
    cat("✓ Administrative boundaries loaded\n")
    cat("  Shapefile contains", nrow(colombia_sf), "departments\n")
  }, error = function(e) {
    cat("⚠ Error loading boundaries:", e$message, "\n")
    cat("  Figure 1 will be skipped\n")
    spatial_available <<- FALSE
  })
} else {
  cat("⚠ Spatial packages not available - Figure 1 will be skipped\n")
}

cat("✓ Data loaded successfully\n\n")

# ------------------------------------------------------------------------------
# 3. FIGURE 1: PAIRED PREVALENCE MAPS (Observed vs. Estimated)
# ------------------------------------------------------------------------------

cat("=== GENERATING FIGURE 1: PAIRED PREVALENCE MAPS ===\n")

if (!spatial_available) {
  cat("⚠ Spatial packages not available - Creating alternative Figure 1 (comparison plot)\n")
  cat("  Note: Choropleth maps require 'sf' package with system dependencies\n")
  cat("  Creating bar chart comparison instead...\n\n")
  
  # Alternative Figure 1: Side-by-side comparison plot
  # Prepare data for comparison
  comparison_wide <- observed_prevalence %>%
    left_join(estimates_dept %>% 
               mutate(Estimated = as.numeric(Prevalence)) %>%
               select(DPNOM, Estimated),
              by = "DPNOM") %>%
    arrange(desc(Estimated)) %>%
    slice_head(n = 25) %>%  # Top 25 departments
    mutate(DPNOM = fct_reorder(DPNOM, Estimated))
  
  # Create long format for plotting
  comparison_data <- comparison_wide %>%
    pivot_longer(cols = c(total_prevalence, Estimated),
                 names_to = "Type",
                 values_to = "Prevalence") %>%
    mutate(
      Type = case_when(
        Type == "total_prevalence" ~ "A. Reported Prevalence",
        Type == "Estimated" ~ "B. Estimated True Prevalence (Bayesian Model)"
      ),
      Type = factor(Type, levels = c("A. Reported Prevalence", 
                                     "B. Estimated True Prevalence (Bayesian Model)"))
    )
  
  # Create side-by-side comparison plot
  fig1_alt <- ggplot(comparison_data, aes(x = DPNOM, y = Prevalence, fill = Type)) +
    geom_col(position = "dodge", alpha = 0.85, width = 0.7) +
    scale_fill_viridis_d(
      option = "plasma",
      begin = 0.2,
      end = 0.8,
      direction = -1,
      name = ""
    ) +
    scale_y_continuous(
      labels = scales::percent_format(accuracy = 0.1),
      expand = expansion(mult = c(0, 0.05))
    ) +
    labs(
      x = "Department",
      y = "Prevalence"
    ) +
    coord_flip() +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 8),
      axis.text.x = element_text(size = 9),
      axis.title = element_text(size = 11, face = "bold"),
      legend.position = "top",
      legend.text = element_text(size = 10, face = "bold"),
      plot.margin = margin(10, 10, 10, 10),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    facet_wrap(~ Type, ncol = 2, scales = "free_x")
  
  # Save alternative figure
  cat("Saving alternative Figure 1 (comparison plot)...\n")
  ggsave("outputs/figures/Fig1_Colombia_Prevalence_Maps.png",
         plot = fig1_alt,
         width = 12, height = 10, units = "in", dpi = 300)
  cat("  ✓ PNG saved (300 dpi, 12×10 inches)\n")
  
  ggsave("outputs/figures/Fig1_Colombia_Prevalence_Maps.pdf",
         plot = fig1_alt,
         width = 12, height = 10, units = "in")
  cat("  ✓ PDF saved (vector format)\n\n")
  
} else {
  # Split Figure 1 into two separate files: Mainland and Islands
  cat("Preparing data for split figure approach (Mainland + Islands)...\n")
  
  # Join both datasets with shapefile
  map_observed <- colombia_sf %>%
    left_join(observed_prevalence, by = "DPNOM_std")
  
  map_estimated <- colombia_sf %>%
    left_join(estimates_dept, by = "DPNOM_std")
  
  # Check San Andrés data specifically
  san_andres_observed <- map_observed %>%
    filter(str_detect(name, "San Andr|San Andrés"))
  san_andres_estimated <- map_estimated %>%
    filter(str_detect(name, "San Andr|San Andrés"))
  
  cat("  Checking San Andrés y Providencia data:\n")
  if (nrow(san_andres_observed) > 0) {
    cat("    Observed prevalence:", ifelse(is.na(san_andres_observed$total_prevalence[1]), "MISSING", 
                                          paste0(round(san_andres_observed$total_prevalence[1] * 100, 2), "%")), "\n")
  }
  if (nrow(san_andres_estimated) > 0) {
    cat("    Estimated prevalence:", ifelse(is.na(san_andres_estimated$Prevalence[1]), "MISSING", 
                                            paste0(round(san_andres_estimated$Prevalence[1] * 100, 2), "%")), "\n")
  }
  
  # Calculate GLOBAL scale limits across ENTIRE dataset (both Reported and Estimated)
  all_observed_values <- map_observed$total_prevalence[!is.na(map_observed$total_prevalence)]
  all_estimated_values <- map_estimated$Prevalence[!is.na(map_estimated$Prevalence)]
  global_min <- 0  # Always start at 0
  global_max <- max(c(all_observed_values, all_estimated_values), na.rm = TRUE)
  global_limits <- c(global_min, global_max)
  
  cat("  Global scale limits: 0 to", round(global_max * 100, 2), "%\n")
  cat("  (Applied to BOTH Part A and Part B for color consistency)\n")
  
  # Separate mainland and islands
  islands_mask <- str_detect(map_observed$name, "San Andrés y Providencia")
  
  # Mainland maps (exclude islands)
  mainland_observed <- map_observed %>%
    filter(!islands_mask)
  
  mainland_estimated <- map_estimated %>%
    filter(!islands_mask)
  
  # Island maps (only San Andrés)
  islands_observed <- map_observed %>%
    filter(islands_mask)
  
  islands_estimated <- map_estimated %>%
    filter(islands_mask)
  
  cat("  ✓ Separated mainland (", nrow(mainland_observed), " depts) and islands (", 
      nrow(islands_observed), " dept)\n")
  
  # ============================================================================
  # OUTPUT 1: MAINLAND MAP (Part A)
  # ============================================================================
  cat("\n=== GENERATING PART A: MAINLAND MAP ===\n")
  
  # Prepare mainland data in long format for facet_wrap
  mainland_long <- bind_rows(
    mainland_observed %>%
      select(geometry, name, DPNOM_std, total_prevalence) %>%
      mutate(
        Prevalence_Type = "A. Reported Prevalence",
        Prevalence_Value = total_prevalence
      ) %>%
      select(geometry, name, DPNOM_std, Prevalence_Type, Prevalence_Value),
    mainland_estimated %>%
      select(geometry, name, DPNOM_std, Prevalence) %>%
      mutate(
        Prevalence_Type = "B. Estimated True Prevalence (Bayesian Model)",
        Prevalence_Value = Prevalence
      ) %>%
      select(geometry, name, DPNOM_std, Prevalence_Type, Prevalence_Value)
  ) %>%
    mutate(
      Prevalence_Type = factor(Prevalence_Type,
                               levels = c("A. Reported Prevalence",
                                         "B. Estimated True Prevalence (Bayesian Model)"))
    )
  
  # Create mainland plot with facet_wrap
  fig1_partA <- ggplot(mainland_long) +
    geom_sf(aes(fill = Prevalence_Value), color = "white", linewidth = 0.3) +
    scale_fill_viridis_c(
      option = "magma",
      direction = -1,
      limits = global_limits,  # Use global limits
      labels = scales::percent_format(accuracy = 0.1),
      name = "Prevalence (%)",
      guide = guide_colorbar(
        title.position = "top",
        barwidth = 0.5,
        barheight = 8
      )
    ) +
    facet_wrap(~ Prevalence_Type, ncol = 2) +
    theme_void() +
    theme(
      strip.text = element_text(size = 12, face = "bold", hjust = 0.5,
                                margin = margin(b = 10)),
      legend.position = "right",
      plot.margin = margin(5, 5, 5, 5),
      panel.spacing = unit(0.5, "cm")
    )
  
  # Save Part A
  cat("Saving Part A (Mainland)...\n")
  ggsave("outputs/figures/Fig1_PartA_Mainland.png",
         plot = fig1_partA,
         width = 10, height = 8, units = "in", dpi = 300)
  cat("  ✓ PNG saved (300 dpi, 10×8 inches)\n")
  
  ggsave("outputs/figures/Fig1_PartA_Mainland.pdf",
         plot = fig1_partA,
         width = 10, height = 8, units = "in")
  cat("  ✓ PDF saved (vector format)\n")
  
  # ============================================================================
  # OUTPUT 2: ISLANDS MAP (Part B)
  # ============================================================================
  cat("\n=== GENERATING PART B: ISLANDS MAP ===\n")
  
  # Prepare islands data in long format for facet_wrap
  islands_long <- bind_rows(
    islands_observed %>%
      select(geometry, name, DPNOM_std, total_prevalence) %>%
      mutate(
        Prevalence_Type = "A. Reported Prevalence",
        Prevalence_Value = total_prevalence
      ) %>%
      select(geometry, name, DPNOM_std, Prevalence_Type, Prevalence_Value),
    islands_estimated %>%
      select(geometry, name, DPNOM_std, Prevalence) %>%
      mutate(
        Prevalence_Type = "B. Estimated True Prevalence (Bayesian Model)",
        Prevalence_Value = Prevalence
      ) %>%
      select(geometry, name, DPNOM_std, Prevalence_Type, Prevalence_Value)
  ) %>%
    mutate(
      Prevalence_Type = factor(Prevalence_Type,
                               levels = c("A. Reported Prevalence",
                                         "B. Estimated True Prevalence (Bayesian Model)"))
    )
  
  # Create islands plot with facet_wrap (auto-zooms to bounding box)
  fig1_partB <- ggplot(islands_long) +
    geom_sf(aes(fill = Prevalence_Value), color = "black", linewidth = 0.5) +
    scale_fill_viridis_c(
      option = "magma",
      direction = -1,
      limits = global_limits,  # Use SAME global limits for color consistency
      labels = scales::percent_format(accuracy = 0.1),
      guide = "none"  # No legend (identical to Part A)
    ) +
    facet_wrap(~ Prevalence_Type, ncol = 2) +
    theme_void() +
    theme(
      strip.text = element_text(size = 10, face = "bold", hjust = 0.5,
                                margin = margin(b = 8)),
      plot.margin = margin(5, 5, 5, 5),
      panel.spacing = unit(0.3, "cm"),
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.5)
    )
  
  # Save Part B
  cat("Saving Part B (San Andrés)...\n")
  ggsave("outputs/figures/Fig1_PartB_SanAndres.png",
         plot = fig1_partB,
         width = 4, height = 3, units = "in", dpi = 300)
  cat("  ✓ PNG saved (300 dpi, 4×3 inches)\n")
  
  ggsave("outputs/figures/Fig1_PartB_SanAndres.pdf",
         plot = fig1_partB,
         width = 4, height = 3, units = "in")
  cat("  ✓ PDF saved (vector format)\n\n")
  
  # Also save the combined figure for reference (optional)
  cat("Note: Original combined figure saved as Fig1_Colombia_Prevalence_Maps.png\n")
  cat("      Use Part A and Part B for manuscript submission\n\n")
}  # End of spatial_available check

# ------------------------------------------------------------------------------
# 4. FIGURE 2: CORRELATION PLOT (Spirometry vs. Reported)
# ------------------------------------------------------------------------------

cat("=== GENERATING FIGURE 2: SPIROMETRY CORRELATION ===\n")

# Prepare data for correlation plot
corr_data <- data %>%
  select(DPNOM, spirometry_rate, total_prevalence) %>%
  # Calculate median by department
  group_by(DPNOM) %>%
  summarise(
    spirometry_rate = median(spirometry_rate, na.rm = TRUE),
    total_prevalence = median(total_prevalence, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Identify outliers (departments with extreme values)
  mutate(
    is_outlier = abs(spirometry_rate - median(spirometry_rate, na.rm = TRUE)) > 
                 2 * IQR(spirometry_rate, na.rm = TRUE) |
                 abs(total_prevalence - median(total_prevalence, na.rm = TRUE)) > 
                 2 * IQR(total_prevalence, na.rm = TRUE)
  )

# Create correlation plot
fig2 <- ggplot(corr_data, aes(x = spirometry_rate, y = total_prevalence)) +
  geom_point(aes(color = is_outlier), size = 2.5, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "grey40", 
              fill = "grey80", alpha = 0.3, linewidth = 0.8) +
  geom_text_repel(
    data = filter(corr_data, is_outlier),
    aes(label = DPNOM),
    size = 3,
    max.overlaps = 10,
    box.padding = 0.5,
    point.padding = 0.3
  ) +
  scale_color_manual(
    values = c("FALSE" = "#2E86AB", "TRUE" = "#A23B72"),
    guide = "none"
  ) +
  stat_cor(
    method = "pearson",
    label.x = 0.1 * max(corr_data$spirometry_rate, na.rm = TRUE),
    label.y = 0.95 * max(corr_data$total_prevalence, na.rm = TRUE),
    size = 4,
    color = "black"
  ) +
  labs(
    x = "Spirometry Rate (per 100k inhabitants)",
    y = "Reported COPD Prevalence"
  ) +
  theme(
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10)
  )

# Save in both formats
cat("Saving Figure 2...\n")
ggsave("outputs/figures/Fig2_Spirometry_Correlation.png",
       plot = fig2,
       width = 8, height = 6, units = "in", dpi = 300)
cat("  ✓ PNG saved (300 dpi, 8×6 inches)\n")

ggsave("outputs/figures/Fig2_Spirometry_Correlation.pdf",
       plot = fig2,
       width = 8, height = 6, units = "in")
cat("  ✓ PDF saved (vector format)\n\n")

# ------------------------------------------------------------------------------
# 5. FIGURE 3: SPIROMETRY CAPACITY VS. BENCHMARK
# ------------------------------------------------------------------------------

cat("=== GENERATING FIGURE 3: SPIROMETRY BENCHMARK ===\n")

# Prepare data for benchmark plot
benchmark_data <- data %>%
  group_by(DPNOM) %>%
  summarise(
    spirometry_rate = median(spirometry_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(spirometry_rate)) %>%
  mutate(
    DPNOM = fct_reorder(DPNOM, spirometry_rate),
    above_50pct = spirometry_rate >= (1105.08 * 0.5),
    above_benchmark = spirometry_rate >= 1105.08
  )

# Define benchmark
spirometry_benchmark <- 1105.08
benchmark_50pct <- spirometry_benchmark * 0.5

# Create lollipop chart
fig3 <- ggplot(benchmark_data, aes(x = DPNOM, y = spirometry_rate)) +
  geom_segment(
    aes(x = DPNOM, xend = DPNOM, y = 0, yend = spirometry_rate),
    color = ifelse(benchmark_data$above_50pct, "#2E86AB", "#A23B72"),
    linewidth = 0.8
  ) +
  geom_point(
    aes(color = above_50pct),
    size = 2.5,
    alpha = 0.8
  ) +
  geom_hline(
    yintercept = spirometry_benchmark,
    linetype = "dashed",
    color = "red",
    linewidth = 1,
    alpha = 0.7
  ) +
  geom_hline(
    yintercept = benchmark_50pct,
    linetype = "dotted",
    color = "orange",
    linewidth = 0.8,
    alpha = 0.5
  ) +
  annotate(
    "text",
    x = length(levels(benchmark_data$DPNOM)) * 0.95,
    y = spirometry_benchmark + 50,
    label = "National Spirometry Benchmark\n(1,105/100k)",
    hjust = 1,
    vjust = 0,
    size = 3.5,
    color = "red",
    fontface = "bold"
  ) +
  scale_color_manual(
    values = c("FALSE" = "#A23B72", "TRUE" = "#2E86AB"),
    labels = c("Below 50% Benchmark", "Above 50% Benchmark"),
    name = "Status"
  ) +
  scale_y_continuous(
    breaks = c(0, benchmark_50pct, spirometry_benchmark, 1500, 2000),
    labels = c("0", "553", "1,105", "1,500", "2,000"),
    expand = expansion(mult = c(0, 0.1))
  ) +
  labs(
    x = "Department",
    y = "Spirometry Rate (per 100k inhabitants)"
  ) +
  coord_flip() +
  theme(
    axis.text.y = element_text(size = 7),
    axis.text.x = element_text(size = 9),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 10),
    legend.text = element_text(size = 9)
  )

# Save in both formats
cat("Saving Figure 3...\n")
ggsave("outputs/figures/Fig3_Spirometry_Benchmark.png",
       plot = fig3,
       width = 8, height = 12, units = "in", dpi = 300)
cat("  ✓ PNG saved (300 dpi, 8×12 inches)\n")

ggsave("outputs/figures/Fig3_Spirometry_Benchmark.pdf",
       plot = fig3,
       width = 8, height = 12, units = "in")
cat("  ✓ PDF saved (vector format)\n\n")

# ------------------------------------------------------------------------------
# 6. SUMMARY
# ------------------------------------------------------------------------------

cat("═══════════════════════════════════════════════════════════════\n")
cat("                    FIGURES GENERATION COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Generated files in outputs/figures/:\n")
figure_files <- list.files("outputs/figures", pattern = "^Fig[0-9]", full.names = FALSE)
for (file in sort(figure_files)) {
  file_path <- file.path("outputs/figures", file)
  if (file.exists(file_path)) {
    file_size <- file.info(file_path)$size
    cat("  ✓ ", file, " (", round(file_size/1024, 2), " KB)\n", sep = "")
  }
}

cat("\n")
cat("All figures saved in both PNG (300 dpi) and PDF (vector) formats.\n")
cat("Figures are ready for manuscript submission.\n")
cat("═══════════════════════════════════════════════════════════════\n")

