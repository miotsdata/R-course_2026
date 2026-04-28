# ============================================================
# Generate mock immunofluorescence data
# 5 CSV files, each with 2 KO and 2 wt measurements
# Columns: group, area (mm^2), intensity
# Normalized intensity (intensity / area) is designed to be
# statistically different between KO and wt
# ============================================================

set.seed(42)

# --- Fixed parameters ---
n_files     <- 5
n_per_group <- 2   # KO and wt replicates per file

# Area parameters (small values, typical for IF in mm^2)
# ~0.001–0.010 mm^2  →  ~1000–10000 µm^2 after conversion
area_mean  <- 0.005   # mm^2
area_sd    <- 0.001

# Raw intensity parameters
# KO will have higher raw intensity AND similar area → higher normalised intensity
intensity_mean_wt <- 500
intensity_mean_ko <- intensity_mean_wt * 1.5
intensity_sd      <- 100

# Output directory (creates a subfolder to keep things tidy)
out_dir <- "data/day-5/"
dir.create(out_dir, showWarnings = FALSE)

# --- Generate files ---
for (i in seq_len(n_files)) {
    
    groups <- c(rep("wt", n_per_group), rep("KO", n_per_group))
    
    area <- c(
        rnorm(n_per_group, mean = area_mean, sd = area_sd),   # wt
        rnorm(n_per_group, mean = area_mean, sd = area_sd)    # KO
    )
    # Ensure area is always positive
    area <- abs(area)
    
    intensity <- c(
        rnorm(n_per_group, mean = intensity_mean_wt, sd = intensity_sd),  # wt
        rnorm(n_per_group, mean = intensity_mean_ko, sd = intensity_sd)   # KO
    )
    intensity <- abs(intensity)
    
    df <- data.frame(
        group     = groups,
        area      = round(area, 6),        # mm^2, 6 decimal places
        intensity = round(intensity, 2)
    )
    
    file_name <- file.path(out_dir, paste0("slide_", i, ".csv"))
    write.csv(df, file = file_name, row.names = FALSE)
    message("Written: ", file_name)
}

message("\nDone! ", n_files, " files saved in '", out_dir, "/'")