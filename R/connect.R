#' Connect to History Database
#'
#' Create a Connection to Firefox' history database.
#'
#' @param root_dir The root directory where Firefox' data is stored. See
#'   'Details' for hints where to find this on different systems.
#' @param profile The profile name to be used. The profile is a folder
#'   within the root dir. The names of the available profiles can be listed
#'   using [`list_profiles()`].
#'
#' @details
#' Where Firefox stores the history database depends on your opperating system.
#' This has been checked only for very few systems:
#'
#' \describe{
#'   \item{Ubuntu 22.04}{If Firefox has been installed from a deb package, the
#'   root directory is `~/.mozilla/firefox`. (This might also be true for other
#'   Debian-based distributions.) If Firefox has been installed as a snap
#'   package, the root directory is `~/snap/firefox/common/.mozilla/firefox`}
#' }
#'
#'
#' @export

connect_history_db <- function(root_dir, profile) {

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
    cli::cli_abort("The file {prof_file} does not exist.")
  }

  full_path

}
