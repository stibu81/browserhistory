library(glue)
library(withr)
library(dplyr, warn.conflicts = FALSE)
library(RSQLite)
library(lubridate, warn.conflicts = FALSE)

root_dir <- normalizePath(test_path("..", "testdata", "firefox"))
ref_data <- readRDS(test_path("..", "ref", "firefox_ref.rds"))
simple_names <- c("id", "visit_date", "url", "title", "visit_count",
                  "last_visit_date", "description", "prefix", "host")

test_that("test read_browser_history()", {
  con <- connect_history_db(root_dir)
  defer(dbDisconnect(con))

  expect_silent(history <- read_browser_history(con))
  expect_identical(history, select(ref_data, all_of(simple_names)))
  expect_equal(tz(history$visit_date), "")
  expect_equal(tz(history$last_visit_date), "")

  expect_silent(history <- read_browser_history(con, raw = TRUE))
  expect_identical(history, ref_data)
  expect_equal(tz(history$visit_date), "")
  expect_equal(tz(history$last_visit_date), "")

  expect_silent(history <- read_browser_history(con, tz = "UTC"))
  expect_identical(
    history,
    ref_data %>%
      select(all_of(simple_names)) %>%
      mutate(across(contains("date"), \(x) with_tz(x, tzone = "UTC")))
  )
  expect_equal(tz(history$visit_date), "UTC")
  expect_equal(tz(history$last_visit_date), "UTC")
})
