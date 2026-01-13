# ===============================================================
# Download daily 1 km SSM NetCDF files using a manifest file
# ===============================================================

library(httr)   # for downloading files

# ---------------- USER SETTINGS ----------------
manifest_url <- "https://globalland.vito.be/download/manifest/ssm_1km_v1_daily_netcdf/manifest_clms_global_ssm_1km_v1_daily_netcdf_latest.txt"

start_date <- as.Date("2024-01-01")
end_date   <- as.Date("2025-01-01")

save_dir <- "" # add your path inside quotes
# ------------------------------------------------

# Create folder if it does not exist
if (!dir.exists(save_dir)) {
  dir.create(save_dir, recursive = TRUE)
}

# ---------------- DOWNLOAD ----------------

# Read the manifest file (list of URLs)
manifest_text <- content(GET(manifest_url), "text", encoding = "UTF-8")
urls <- strsplit(manifest_text, "\n")[[1]]

# Loop over all URLs in the manifest
for (url in urls) {

  # Extract date (YYYYMMDD) from the file name
  date_string <- sub(".*_(\\d{8})0000_.*", "\\1", url)
  file_date <- as.Date(date_string, format = "%Y%m%d")

  # Skip files outside the selected date range
  if (is.na(file_date)) next
  if (file_date < start_date || file_date > end_date) next

  # Local file path
  file_name <- basename(url)
  local_path <- file.path(save_dir, file_name)

  # Download file
  cat("Downloading:", file_name, "\n")
  tryCatch(
    {
      GET(url, write_disk(local_path, overwrite = TRUE))
      cat("Saved to:", local_path, "\n")
    },
    error = function(e) {
      cat("Failed to download:", file_name, "\n")
    }
  )
}

cat("Download finished.\n")
