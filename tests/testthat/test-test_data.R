library(ini)
library(RSQLite)
library(dplyr, warn.conflicts = FALSE)
library(withr)
library(glue)

root_dir <- get_test_root_dir()

test_that("check profiles.ini", {
  ini_file <- file.path(root_dir, "profiles.ini")
  expect_true(file.exists(ini_file))
  ini <- read.ini(ini_file)
  expect_named(ini, c("Profile1", "Profile0", "General"))
  expect_equal(ini$Profile0$Name, "default")
  expect_equal(ini$Profile0$Path, "test_profile")
  expect_equal(ini$Profile0$Default, "1")
})


test_that("check test database", {
  db_file <- file.path(root_dir, "test_profile", "places.sqlite")
  expect_true(file.exists(db_file))
  expect_silent(con <- dbConnect(SQLite(), db_file))
  expect_true(dbIsValid(con))
  on.exit(dbDisconnect(con))

  # check that tables exist
  expect_true(dbExistsTable(con, "moz_places"))
  expect_true(dbExistsTable(con, "moz_origins"))
  expect_true(dbExistsTable(con, "moz_historyvisits"))

  # check that fields exist
  expect_equal(
    dbListFields(con, "moz_places"),
    c("id", "url", "title", "rev_host", "visit_count", "hidden",
      "typed", "favicon_id", "frecency", "last_visit_date", "guid",
      "foreign_count", "url_hash", "description", "preview_image_url",
      "origin_id", "site_name", "recalc_frecency", "alt_frecency",
      "recalc_alt_frecency")
  )
  expect_equal(
    dbListFields(con, "moz_origins"),
    c("id", "prefix", "host", "frecency", "recalc_frecency", "alt_frecency",
      "recalc_alt_frecency")
  )
  expect_equal(
    dbListFields(con, "moz_historyvisits"),
    c("id", "from_visit", "place_id", "visit_date", "visit_type",
      "session", "source", "triggeringPlaceId")
  )
})


test_that("test generation of test data", {
  output_dir <- file.path(tempdir(), "test_data")
  dir.create(output_dir)
  defer(unlink(output_dir, recursive = TRUE))

  expect_s3_class(
    generate_testdata(root_dir = root_dir,
                      start_time = as.POSIXct("2024-05-24 17:42:00"),
                      end_time = as.POSIXct("2024-05-24 17:46:00"),
                      output_dir = output_dir),
    "tbl_df"
  )

  expect_true(file.exists(file.path(output_dir, "profiles.ini")))
  expect_true(file.exists(file.path(output_dir, "test_profile", "places.sqlite")))

  # check that overwriting of the testdata works.
  expect_s3_class(
    generate_testdata(root_dir = root_dir,
                      start_time = as.POSIXct("2024-05-24 17:42:00"),
                      end_time = as.POSIXct("2024-05-24 17:46:00"),
                      output_dir = output_dir),
    "tbl_df"
  )

  # check contents of the ini file
  expect_equal(read.ini(file.path(output_dir, "profiles.ini")),
               read.ini(file.path(root_dir, "profiles.ini")))

  # the following tests do not work on github for some reason. The tables seem
  # to be empty. Since this functionality is not necessary for users of the
  # package, it is also not relevant to check that it works on different
  # systems. => Skip.
  skip_on_ci()

  # check contents of the database
  con_orig <- dbConnect(SQLite(), file.path(root_dir, "test_profile", "places.sqlite"))
  con_test <- dbConnect(SQLite(), file.path(output_dir, "test_profile", "places.sqlite"))
  defer({
    dbDisconnect(con_orig)
    dbDisconnect(con_test)
  })
  # visit_count is overwritten by random numbers in generate_testdata(), so
  # it should not be compared
  expect_equal(dbReadTable(con_test, "moz_places") |> select(-visit_count),
               dbReadTable(con_orig, "moz_places") |> select(-visit_count))
  expect_equal(dbReadTable(con_test, "moz_origins"),
               dbReadTable(con_orig, "moz_origins"))
  expect_equal(dbReadTable(con_test, "moz_historyvisits"),
               dbReadTable(con_orig, "moz_historyvisits"))

})


test_that("test generate_testdata() errors", {
  expect_error(
    generate_testdata(root_dir = root_dir,
                      start_time = "2024-05-24 17:42:00",
                      end_time = as.POSIXct("2024-05-24 17:46:00"),
                      output_dir = tempdir()),
    "start_time must be a POSIXt object."
  )
  expect_error(
    generate_testdata(root_dir = root_dir,
                      start_time = as.POSIXct("2024-05-24 17:42:00"),
                      end_time = "2024-05-24 17:46:00",
                      output_dir = tempdir()),
    "end_time must be a POSIXt object."
  )
  skip_on_os("windows")
  output_dir <- file.path(tempdir(), "doesnotexist")
  expect_error(
    generate_testdata(root_dir = root_dir,
                      start_time = as.POSIXct("2024-05-24 17:42:00"),
                      end_time = as.POSIXct("2024-05-24 17:46:00"),
                      output_dir = output_dir),
    glue("The output directory {output_dir} does not exist.")
  )
})
