library(glue)
library(RSQLite)
library(withr)

root_dir <- normalizePath(test_path("..", "testdata", "firefox"))

test_that("test list_profiles()", {
  expect_equal(list_profiles(root_dir), c(default = "test_profile"))
  bad_dir <- tempfile()
  expect_error(list_profiles(bad_dir),
               glue("The root directory {bad_dir} does not exist."))
  expect_error(list_profiles(tempdir()),
               glue("The directory {tempdir()} is not a Firefox root directory."))
})


test_that("test auto_select_profile()", {
  expect_equal(autoselect_profile(root_dir), c(default = "test_profile"))
  expect_equal(autoselect_profile(root_dir, "default"), c(default = "test_profile"))
  expect_equal(autoselect_profile(root_dir, "nonexistent"), c(default = "test_profile"))
  bad_dir <- tempfile()
  expect_error(autoselect_profile(bad_dir),
               glue("The root directory {bad_dir} does not exist."))
  expect_error(autoselect_profile(tempdir()),
               glue("The directory {tempdir()} is not a Firefox root directory."))
})


test_that("test connect_history_db()", {
  expect_silent(con <- connect_history_db(root_dir))
  defer(dbDisconnect(con))
  expect_true(dbIsValid(con))
  expect_equal(attr(con, "dbname"), file.path(root_dir, "test_profile", "places.sqlite"))
  bad_dir <- tempfile()
  expect_error(connect_history_db(bad_dir),
               glue("The root directory {bad_dir} does not exist."))
  expect_error(connect_history_db(tempdir()),
               glue("The directory {tempdir()} is not a Firefox root directory."))
  expect_error(connect_history_db(root_dir, profile = "bad_profile"),
               "The profile bad_profile does not exist.")
})


test_that("test connect_local()", {
  expect_silent(
    local_connection <- connect_local(con = NULL,
                                      root_dir = root_dir,
                                      profile = "test_profile")
  )
  defer(dbDisconnect(local_connection$con))
  expect_true(dbIsValid(local_connection$con))
  expect_true(local_connection$is_local)
  expect_silent(
    local_connection <- connect_local(con = local_connection$con,
                                      root_dir = root_dir,
                                      profile = "test_profile")
  )
  expect_true(dbIsValid(local_connection$con))
  expect_false(local_connection$is_local)
  expect_error(
    connect_local(con = 1, root_dir = root_dir, profile = "test_profile"),
    "con is not a valid database connection."
  )
})
