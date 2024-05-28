#' Generate Test Data
#'
#' Generate a test database from a Firefox history database.
#'
#' @inheritParams read_browser_history
#' @param start_time,end_time POSIXt objects that specifies the time interval
#'  for which browser history will be included in the test database.
#' @param output_dir The directory where the test database should be
#'  written to. The directory must exist.
#'
#' @details
#' A file `profiles.ini` will be created in the output directory that contains
#' the test profile. A folder `test_profile` will be created that contains
#' the test database in a file called `places.sqlite`. The database contains
#' only the three tables (`moz_historyvisits`, `moz_places`, `moz_origins`)
#' that are processed by [`read_browser_history()`].
#'
#' @return
#' The function reads the test database it has written and returns
#' its contents as a data frame.
#'
#'
#' @export

generate_testdata <- function(con = NULL,
                              root_dir = guess_root_dir(),
                              profile = autoselect_profile(root_dir),
                              start_time,
                              end_time = Sys.time(),
                              output_dir) {

  # check inputs
  rlang::check_required(start_time)
  if (!lubridate::is.POSIXt(start_time)) {
    cli::cli_abort("start_time must be a POSIXt object.")
  }
  rlang::check_required(end_time)
  if (!lubridate::is.POSIXt(end_time)) {
    cli::cli_abort("end_time must be a POSIXt object.")
  }
  rlang::check_required(output_dir)
  if (!dir.exists(output_dir)) {
    cli::cli_abort("The output directory {output_dir} does not exist.")
  }

  local_connection <- connect_local(con, root_dir, profile)
  con <- local_connection$con

  # read the relevant tables
  moz_visits <- dplyr::tbl(con, "moz_historyvisits")
  moz_places <- dplyr::tbl(con, "moz_places")
  moz_origins <- dplyr::tbl(con, "moz_origins")

  # keep only the data that is newer than the requested date
  # filter moz_visits by date, then filter the other tables for the ids that
  # are left in the filtered moz_visits.
  start_time_firefox_ts <- posix_to_firefox_ts(start_time)
  end_time_firefox_ts <- posix_to_firefox_ts(end_time)
  moz_visits <- moz_visits |>
    dplyr::filter(.data$visit_date > start_time_firefox_ts,
                  .data$visit_date < end_time_firefox_ts) |>
    dplyr::collect()
  moz_places <- moz_places |>
    dplyr::filter(.data$id %in% moz_visits$place_id) |>
    dplyr::collect()
  moz_origins <- moz_origins |>
    dplyr::filter(.data$id %in% moz_places$origin_id) |>
    dplyr::collect()

  # hide the actual visit count by overwriting with random values
  moz_places$visit_count <- sample(1:20, nrow(moz_places), replace = TRUE)

  write_profiles_ini(output_dir)
  write_history_db(output_dir, "test_profile", moz_visits, moz_places, moz_origins)
  # write an empty file to the bad_profile to simulate a profile without history
  some_file <- file.path(output_dir, "bad_profile", "somefile")
  if (!dir.exists(dirname(some_file))) dir.create(dirname(some_file))
  writeLines("", some_file)

  # disconnect the database if the connection has been created within this
  # function
  if (local_connection$is_local) RSQLite::dbDisconnect(con)

    # read data back from the database that was just created.
  read_browser_history(root_dir = output_dir, profile = "test_profile")
}


#' Get the Root Directory of the Test Data
#'
#' @export

get_test_root_dir <- function() {
  system.file("extdata", "firefox", package = "browserhistory")
}


# write ini file with the test profile
write_profiles_ini <- function(output_dir) {
  ini_file <- file.path(output_dir, "profiles.ini")
  contents <- list(
    Profile1 = list(
      Name = "other",
      IsRelative = 1,
      Path = "bad_profile"
    ),
    Profile0 = list(
      Name = "default",
      IsRelative = 1,
      Path = "test_profile",
      Default = 1
    ),
    General = list(
      StartWithLastProfile = 1,
      Version = 2
    )
  )
  ini::write.ini(contents, ini_file)
}


write_history_db <- function(output_dir, profile,
                             moz_visits, moz_places, moz_origins) {

  hist_file <- file.path(output_dir, profile, "places.sqlite")
  if (!dir.exists(dirname(hist_file))) {
    dir.create(dirname(hist_file), recursive = TRUE)
  }
  if (file.exists(hist_file)) {
    file.remove(hist_file)
  }

  con <- RSQLite::dbConnect(RSQLite::SQLite(), hist_file)

  RSQLite::dbWriteTable(con, "moz_historyvisits", moz_visits)
  RSQLite::dbWriteTable(con, "moz_places", moz_places)
  RSQLite::dbWriteTable(con, "moz_origins", moz_origins)

  RSQLite::dbDisconnect(con)
}
