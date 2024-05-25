# Generate test database from Firefox history
library(devtools)
library(lubridate)
library(browserhistory)

output_dir <- package_file("inst", "extdata", "firefox")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

generate_testdata(
  root_dir = "~/snap/firefox/common/.mozilla/firefox/",
  output_dir = output_dir,
  start_time = as.POSIXct("2024-05-24 17:42:00"),
  end_time = as.POSIXct("2024-05-24 17:46:00")
)
