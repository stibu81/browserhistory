library(ini)
library(RSQLite)
library(dplyr, warn.conflicts = FALSE)
library(withr)

test_that("check profiles.ini", {
  ini_file <- test_path("..", "testdata", "firefox", "profiles.ini")
  expect_true(file.exists(ini_file))
  ini <- read.ini(ini_file)
  expect_named(ini, c("Profile0", "General"))
  expect_equal(ini$Profile0$Name, "default")
  expect_equal(ini$Profile0$Path, "test_profile")
})


test_that("check test database", {
  db_file <- test_path("..", "testdata", "firefox", "test_profile", "places.sqlite")
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
  defer(unlink(output_dir))

  expect_s3_class(
    generate_testdata(root_dir = test_path("..", "testdata", "firefox"),
                      start_time = as.POSIXct("2024-05-24 17:42:00"),
                      end_time = as.POSIXct("2024-05-24 17:46:00"),
                      output_dir = output_dir),
    "tbl_df"
  )

  expect_true(file.exists(file.path(output_dir, "profiles.ini")))
  expect_true(file.exists(file.path(output_dir, "test_profile", "places.sqlite")))

  # check contents of the ini file
  expect_equal(read.ini(file.path(output_dir, "profiles.ini")),
               read.ini(test_path("..", "testdata", "firefox", "profiles.ini")))

  # check contents of the database
  con_orig <- dbConnect(SQLite(), test_path("..", "testdata", "firefox", "test_profile", "places.sqlite"))
  con_test <- dbConnect(SQLite(), file.path(output_dir, "test_profile", "places.sqlite"))
  defer({
    dbDisconnect(con_orig)
    dbDisconnect(con_test)
  })
  # visit_count is overwritten by random numbers in generate_testdata(), so
  # it should not be compared
  expect_equal(dbReadTable(con_orig, "moz_places") |> select(-visit_count),
               dbReadTable(con_test, "moz_places") |> select(-visit_count))
  expect_equal(dbReadTable(con_orig, "moz_origins"),
               dbReadTable(con_test, "moz_origins"))
  expect_equal(dbReadTable(con_orig, "moz_historyvisits"),
               dbReadTable(con_test, "moz_historyvisits"))

})
