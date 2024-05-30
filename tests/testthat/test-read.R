library(withr)
library(dplyr, warn.conflicts = FALSE)
library(RSQLite)
library(lubridate, warn.conflicts = FALSE)

root_dir <- get_test_root_dir()
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


test_that("test read_browser_history() errors", {
  # try to read from locked database
  con <- connect_history_db(root_dir)
  defer(dbDisconnect(con))
  # set the busy timeout to zero to make the test run fast
  RSQLite::sqliteSetBusyHandler(con, 0)
  con2 <- connect_and_lock(root_dir)
  defer(dbDisconnect(con2))
  expect_error(
    read_browser_history(con),
    "The database is locked. Close Firefox before reading the history."
  )
})
