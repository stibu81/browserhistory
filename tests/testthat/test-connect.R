library(glue)
library(RSQLite)
library(withr)
library(ini)

root_dir <- get_test_root_dir()

test_that("test list_profiles()", {
  expect_equal(list_profiles(root_dir),
               c(other = "bad_profile", default = "test_profile"),
               ignore_attr = TRUE)
  expect_equal(attr(list_profiles(root_dir), "default"), 2L)
})

test_that("test list_profiles() errors", {
  skip_on_os("windows")
  bad_dir <- tempfile()
  expect_error(list_profiles(bad_dir),
               glue("The root directory {bad_dir} does not exist."))
  expect_error(list_profiles(tempdir()),
               glue("The directory {tempdir()} is not a Firefox root directory."))
})


test_that("test auto_select_profile()", {
  expect_equal(autoselect_profile(root_dir), c(default = "test_profile"))
})

test_that("test auto_select_profile() errors", {
  skip_on_os("windows")
  bad_dir <- tempfile()
  expect_error(autoselect_profile(bad_dir),
               glue("The root directory {bad_dir} does not exist."))
  expect_error(autoselect_profile(tempdir()),
               glue("The directory {tempdir()} is not a Firefox root directory."))
})


test_that("tests with non-standard profiles.ini", {
  # read original profiles.ini as a starting point
  profiles_ini <- read.ini(file.path(root_dir, "profiles.ini"))
  root_dir2 <- tempfile()
  dir.create(root_dir2)
  defer(unlink(root_dir2))

  # ini-file without Default profile
  profiles_ini2 <- profiles_ini
  profiles_ini2$Profile0$Default <- NULL
  write.ini(profiles_ini2, file.path(root_dir2, "profiles.ini"))
  expect_equal(list_profiles(root_dir2),
               c(other = "bad_profile", default = "test_profile"),
               ignore_attr = TRUE)
  expect_equal(attr(list_profiles(root_dir2), "default"), NA_integer_)
  expect_equal(autoselect_profile(root_dir2), c(other = "bad_profile"))

  # ini-file with two default profiles
  profiles_ini3 <- profiles_ini
  profiles_ini3$Profile1$Default <- 1
  write.ini(profiles_ini3, file.path(root_dir2, "profiles.ini"))
  expect_equal(list_profiles(root_dir2),
               c(other = "bad_profile", default = "test_profile"),
               ignore_attr = TRUE) |>
    expect_warning(
      "There are multiple profiles marked as default. The first one is used."
    )
  expect_equal(attr(list_profiles(root_dir2), "default"), 1L) |>
    expect_warning(
      "There are multiple profiles marked as default. The first one is used."
    )
  expect_equal(autoselect_profile(root_dir2), c(other = "bad_profile")) |>
    expect_warning(
      "There are multiple profiles marked as default. The first one is used."
    )

  # ini-file with no profiles
  profiles_ini4 <- profiles_ini
  profiles_ini4$Profile0 <- NULL
  profiles_ini4$Profile1 <- NULL
  write.ini(profiles_ini4, file.path(root_dir2, "profiles.ini"))
  expect_equal(list_profiles(root_dir2),
               character(0),
               ignore_attr = TRUE)
  expect_equal(attr(list_profiles(root_dir2), "default"), NA_integer_)
  expect_error(autoselect_profile(root_dir2),
               "There are no profiles available.")
})


test_that("test connect_history_db()", {
  expect_silent(con <- connect_history_db(root_dir))
  defer(dbDisconnect(con))
  expect_true(dbIsValid(con))
  skip_on_os("windows")
  expect_equal(
    attr(con, "dbname"),
    normalizePath(file.path(root_dir, "test_profile", "places.sqlite"))
  )
})

test_that("test connect_history_db() errors", {
  expect_error(connect_history_db(root_dir, profile = "bad_profile"),
               "The history database places.sqlite does not exist.")
  skip_on_os("windows")
  bad_dir <- tempfile()
  expect_error(connect_history_db(bad_dir),
               glue("The root directory {bad_dir} does not exist."))
  expect_error(connect_history_db(tempdir()),
               glue("The directory {tempdir()} is not a Firefox root directory."))
  expect_error(connect_history_db(root_dir, profile = "inexistant_profile"),
               "The profile inexistant_profile does not exist.")
})

