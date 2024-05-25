# Create reference data for tests
library(testthat)
library(browserhistory)

data <- read_browser_history(root_dir = "tests/testdata/firefox/", raw = TRUE)
saveRDS(data, test_path("..", "ref", "firefox_ref.rds"))
