# Create reference data for tests
library(testthat)
library(browserhistory)

data <- read_browser_history(root_dir = get_test_root_dir(), raw = TRUE)
saveRDS(data, test_path("..", "ref", "firefox_ref.rds"))
