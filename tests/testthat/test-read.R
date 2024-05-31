library(withr)
library(dplyr, warn.conflicts = FALSE)
library(RSQLite)
library(lubridate, warn.conflicts = FALSE)

root_dir <- get_test_root_dir()
ref_data <- readRDS(test_path("..", "ref", "firefox_ref.rds"))
simple_names <- c("id", "visit_date", "url", "title", "visit_count",
                  "last_visit_date", "description", "prefix", "host")
ref_data_simple <- select(ref_data, all_of(simple_names))

test_that("test read_browser_history()", {
  con <- connect_history_db(root_dir)
  defer(dbDisconnect(con))

  expect_silent(history <- read_browser_history(con))
  expect_identical(history, ref_data_simple)
  expect_equal(tz(history$visit_date), "")
  expect_equal(tz(history$last_visit_date), "")

  expect_silent(history <- read_browser_history(con, raw = TRUE))
  expect_identical(history, ref_data)
  expect_equal(tz(history$visit_date), "")
  expect_equal(tz(history$last_visit_date), "")

  expect_silent(history <- read_browser_history(con, tz = "UTC"))
  expect_identical(
    history,
    ref_data_simple %>%
      mutate(across(contains("date"), \(x) with_tz(x, tzone = "UTC")))
  )
  expect_equal(tz(history$visit_date), "UTC")
  expect_equal(tz(history$last_visit_date), "UTC")
})


test_that("test read_browser_history() with time range", {
  con <- connect_history_db(root_dir)
  defer(dbDisconnect(con))

  start_time <- as.POSIXct("2024-05-24 17:43:15")
  end_time <- as.POSIXct("2024-05-24 17:45:09")

  expect_silent(
    history <- read_browser_history(con, start_time = start_time)
  )
  expect_identical(
    history,
    ref_data_simple %>% filter(visit_date >= start_time)
  )

  expect_silent(
    history <- read_browser_history(con, end_time = end_time)
  )
  expect_identical(
    history,
    ref_data_simple %>% filter(visit_date <= end_time)
  )

  expect_silent(
    history <- read_browser_history(con,
                                    start_time = start_time,
                                    end_time = end_time)
  )
  expect_identical(
    history,
    ref_data_simple %>% filter(visit_date >= start_time,
                               visit_date <= end_time)
  )
})


test_that("test read_browser_history() errors", {
  expect_error(read_browser_history(start_time = 3),
               "start_time must be a POSIXt object.")
  expect_error(read_browser_history(end_time = 3),
               "end_time must be a POSIXt object.")

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
