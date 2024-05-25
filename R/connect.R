#' Connect to History Database
#'
#' Create a Connection to Firefox' history database.
#'
#' @param root_dir The root directory where Firefox' data is stored. See
#'   'Details' for hints where to find this on different systems.
#' @param profile The profile name to be used. The profile is a folder
#'   within the root directory. The names of the available profiles can be listed
#'   using [`list_profiles()`]. If no profile is specified, the function
#'   automatically selects a profile called "default", if it is available,
#'   and the first available profile otherwise.
#'
#' @details
#' Where Firefox stores the history database depends on your operating system.
#' This has been checked only for very few systems:
#'
#' \describe{
#'   \item{Ubuntu 22.04}{If Firefox has been installed from a deb package, the
#'   root directory is `~/.mozilla/firefox`. (This might also be true for other
#'   Debian-based distributions.) If Firefox has been installed as a snap
#'   package, the root directory is `~/snap/firefox/common/.mozilla/firefox`.}
#' }
#'
#' @return
#' a database connection (class `SQLiteConnection`) to the history database
#'
#' @export

connect_history_db <- function(root_dir,
                               profile = autoselect_profile(root_dir)) {

  full_path <- get_hist_file_path(root_dir, profile)

  # if the database is locked, connection produces a warning that is not useful
  con <- suppressWarnings(
    RSQLite::dbConnect(RSQLite::SQLite(), full_path, flags = RSQLite::SQLITE_RO)
  )

  con
}


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


#' List the Available Profiles
#'
#' List all the profiles that are contained in a root directory.
#'
#' @param root_dir The root directory where Firefox' data is stored. See
#'   'Details' in the documentation of [`connect_history_db()`]
#'   for hints where to find this on different systems.
#'
#' @return
#' a named vector where the values are the path to the profiles and the names
#' are the names of the profiles. The path must be passed to
#' [`connect_history_db()`] to build up a connection.
#'
#' @export

list_profiles <- function(root_dir) {

  full_path <- get_profiles_file_path(root_dir)

  ini <- ini::read.ini(full_path)

  # the profile information is stored in fields that are named Profilei, where
  # is an integer
  profiles <- ini[stringr::str_detect(names(ini), "^Profile")]

  # return the profiles as a named vector, where the values are the path and
  # the names the profile name.
  profile_paths <- vapply(profiles, getElement, character(1), name = "Path")
  names(profile_paths) <- vapply(profiles, getElement, character(1), name = "Name")

  profile_paths
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


#' Automatically Select a Profile
#'
#' Automatically select one of the available profiles. If a profile with the
#' name given by the argument `name` exists, its path is returned.
#' Otherwise, the path of the first available profile is returned.
#'
#' @param name character giving the name of the profile to be selected.
#' @inheritParams list_profiles
#'
#' @return
#' a character vector of length 1 giving the path to the selected profile.
#'
#' @seealso List all available profiles with [list_profiles()].
#'
#' @export

autoselect_profile <- function(root_dir, name = "default") {

  profiles <- list_profiles(root_dir)

  if (length(profiles) == 0) {
    cli::cli_abort("There are no profiles available.")
  }

  # if there is a profile with the name given by the argument name, return it.
  # otherwise, return the first profile
  profile <- if (name %in% names(profiles)) {
    profiles[name]
  } else {
    profiles[1]
  }

  profile
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
