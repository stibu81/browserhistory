library(RSQLite)
library(withr)

root_dir <- get_test_root_dir()

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
})

test_that("test connect_local() errors", {
  expect_error(
    connect_local(con = 1, root_dir = root_dir, profile = "test_profile"),
    "con is not a valid database connection."
  )
})
