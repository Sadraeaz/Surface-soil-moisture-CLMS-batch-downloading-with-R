# ---------------------------------------------------------------
# SSM 1km daily (NetCDF) downloader from a manifest file
# ---------------------------------------------------------------

# Required library
library(httr)  # For downloading files

# ---------- Edit these 3 things ----------
manifest_url <- "https://globalland.vito.be/download/manifest/ssm_1km_v1_daily_netcdf/manifest_clms_global_ssm_1km_v1_daily_netcdf_latest.txt"
start_date   <- "2024-12-01"   # inclusive
end_date     <- "2025-01-01"   # inclusive
save_dir     <- "" # Add your path inside quotes
# ----------------------------------------

# create the directory if it doesn't exist (also works if nested)
if (!dir.exists(save_dir)) dir.create(save_dir, recursive = TRUE)

# a small helper that downloads files listed in a text manifest (one URL per line)
download_ssm_files_from_manifest <- function(manifest_url, start_date, end_date, save_dir) {
  # read the manifest (plain text)
  resp <- GET(manifest_url)
  if (http_error(resp)) {
    stop("Could not fetch manifest. HTTP status: ", status_code(resp))
  }
  manifest_lines <- content(resp, "text", encoding = "UTF-8")
  urls <- unlist(strsplit(manifest_lines, "\\r?\\n"))
  urls <- urls[nzchar(urls)]  # drop empty lines

  # loop over urls and pick only the ones inside our date range
  for (url in urls) {
    # extract the date from the URL (pattern like ..._YYYYMMDD0000_...)
    url_date_str <- sub(".*_(\\d{8})0000_.*", "\\1", url)  # get YYYYMMDD
    url_date <- as.Date(url_date_str, format = "%Y%m%d")

    # check if this line actually had a date and is in range
    if (!is.na(url_date) && url_date >= as.Date(start_date) && url_date <= as.Date(end_date)) {
      # local file path
      file_name  <- basename(url)
      local_file <- file.path(save_dir, file_name)

      # skip if already downloaded (easy to rerun)
      if (file.exists(local_file)) {
        cat("Already have:", local_file, "\n")
        next
      }

      # download
      cat("Downloading:", file_name, "(", format(url_date), ")\n")
      ok <- TRUE
      tryCatch(
        GET(url, write_disk(local_file, overwrite = TRUE)),
        error = function(e) { ok <<- FALSE }
      )
      if (ok) {
        cat("Saved to:", local_file, "\n")
      } else {
        cat("Error downloading:", url, "\n")
        if (file.exists(local_file)) file.remove(local_file)  # clean partial file
      }
    }
  }

  cat("Done.\n")
}

# run it
download_ssm_files_from_manifest(manifest_url, start_date, end_date, save_dir)
