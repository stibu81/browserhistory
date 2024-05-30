# compile the full path to the history database.
# check that all the directories and the file actually exist.

get_hist_file_path <- function(root_dir,
                               profile,
                               error_call = rlang::caller_env()) {

  if (!dir.exists(root_dir)) {
    cli::cli_abort("The root directory {root_dir} does not exist.",
                   call = error_call)
  }

  if (!dir.exists(file.path(root_dir, profile))) {
    cli::cli_abort("The profile {profile} does not exist.", call = error_call)
  }

  hist_file <- "places.sqlite"
  full_path <- file.path(root_dir, profile, hist_file)
  if (!file.exists(full_path)) {
    cli::cli_abort("The history database {hist_file} does not exist.")
  }

  full_path
}


# compile the full path to profiles.ini
# check that all the directories and the file actually exist.

get_profiles_file_path <- function(root_dir,
                                   error_call = rlang::caller_env()) {

  if (!dir.exists(root_dir)) {
    cli::cli_abort("The root directory {root_dir} does not exist.",
                   call = error_call)
  }

  prof_file <- "profiles.ini"
  full_path <- file.path(root_dir, prof_file)
  if (!file.exists(full_path)) {
    cli::cli_abort("The directory {root_dir} is not a Firefox root directory.")
  }

  full_path
}


# helper function that determines for a profile, whether it is the default
# profile, i.e., whether it has an attribute Default set to 1.
is_default_profile <- function(profile) {
  "Default" %in% names(profile) && profile["Default"] == "1"
}


# Ensure a connection from within a function. Either, an already existing
# connection is returned or a new connection is created. The function also
# returns a logical that indicates whether a local connection has been
# created or not.

connect_local <- function(con,
                          root_dir,
                          profile,
                          error_call = rlang::caller_env()) {

  is_local <- FALSE
  if (is.null(con)) {
    con <- connect_history_db(root_dir, profile)
    is_local <- TRUE
  } else if (!inherits(con, "SQLiteConnection") || !RSQLite::dbIsValid(con)) {
    cli::cli_abort("con is not a valid database connection.", call = error_call)
  }

  list(con = con, is_local = is_local)
}


# check, whether database is locked. This can happen, when Firefox is running.
is_locked <- function(con) {
  tryCatch({
    dplyr::tbl(con, "moz_historyvisits")
    FALSE
  }, error = function(e) {
    if ("parent" %in% names(e)) {
      stringr::str_detect(as.character(e$parent), "database is locked")
    } else {
      FALSE
    }
  })
}


# for testing purposes: connect to database and lock it
connect_and_lock <- function(root_dir, profile = autoselect_profile(root_dir)) {

  full_path <- get_hist_file_path(root_dir, profile)

  # open database in read/write mode
  con <- suppressWarnings(
    RSQLite::dbConnect(RSQLite::SQLite(), full_path)
  )

  # begin an exclusive transaction. This locks the database.
  RSQLite::dbExecute(con, "BEGIN EXCLUSIVE TRANSACTION;")

  con
}
