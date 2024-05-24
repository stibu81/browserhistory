# Generate test database from Firefox history
library(testthat)
library(lubridate)
library(browserhistory)

generate_testdata(
  root_dir = "~/snap/firefox/common/.mozilla/firefox/",
  output_dir = test_path("..", "testdata", "firefox"),
  start_time = as.POSIXct("2024-05-24 17:42:00"),
  end_time = as.POSIXct("2024-05-24 17:46:00")
)
