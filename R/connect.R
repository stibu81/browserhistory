#' Connect to History Database
#'
#' Create a Connection to Firefox' history database.
#'
#' @param root_dir The root directory where Firefox' data is stored. See
#'   'Details' for hints where to find this on different systems. If omitted,
#'   the function tries to guess the root directory using [`guess_root_dir()`].
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
#'   \item{Ubuntu 20.04/22.04}{If Firefox has been installed from a deb package, the
#'    root directory is `~/.mozilla/firefox`. (This might also be true for other
#'    Debian-based distributions.) If Firefox has been installed as a snap
#'    package, the root directory is `~/snap/firefox/common/.mozilla/firefox`.}
#'   \item{Windows 10/11}{The root directory is
#'    `C:\Users\<username>\AppData\Roaming\Mozilla\Firefox`, where
#'    `<username>` must be replaced by your user name.}
#' }
#'
#' @return
#' a database connection (class `SQLiteConnection`) to the history database
#'
#' @export

connect_history_db <- function(root_dir = guess_root_dir(),
                               profile = autoselect_profile(root_dir)) {

  full_path <- get_hist_file_path(root_dir, profile)

  # if the database is locked, connection produces a warning that is not useful
  con <- suppressWarnings(
    RSQLite::dbConnect(RSQLite::SQLite(), full_path, flags = RSQLite::SQLITE_RO)
  )

  # increase the timeout in case the database is locked
  # this should make the probability of a lock small.
  RSQLite::sqliteSetBusyHandler(con, 5000)

  con
}


#' List the Available Profiles
#'
#' List all the profiles that are contained in a root directory.
#'
#' @param root_dir The root directory where Firefox' data is stored. See
#'   'Details' in the documentation of [`connect_history_db()`]
#'   for hints where to find this on different systems. If omitted,
#'   the function tries to guess the root directory using [`guess_root_dir()`].
#'
#' @return
#' a named vector where the values are the path to the profiles and the names
#' are the names of the profiles. The path must be passed to
#' [`connect_history_db()`] to build up a connection. The index of the default
#' profile is returned as an attribute `"default"`. If no profile is marked as
#' default, the attribute is set to `NA`.
#'
#' @export

list_profiles <- function(root_dir = guess_root_dir()) {

  full_path <- get_profiles_file_path(root_dir)

  ini <- ini::read.ini(full_path)

  # the profile information is stored in fields that are named Profilei, where
  # is an integer
  profiles <- ini[stringr::str_detect(names(ini), "^Profile")]

  # return the profiles as a named vector, where the values are the path and
  # the names the profile name.
  profile_paths <- vapply(profiles, getElement, character(1), name = "Path")
  names(profile_paths) <- vapply(profiles, getElement, character(1), name = "Name")

  # add an attribute that contains the index of the default profile. If no
  # profile is marked as default, the attribute is set to NA.
  default_profile <- vapply(profiles, is_default_profile,
                            logical(1), USE.NAMES = FALSE) |>
    which()
  if (length(default_profile) > 1) {
    cli::cli_warn("There are multiple profiles marked as default. The first one is used.")
    default_profile <- default_profile[1]
  }
  if (length(default_profile) == 0) default_profile <- NA_integer_

  attr(profile_paths, "default") <- default_profile

  profile_paths
}


#' Automatically Select a Profile
#'
#' Automatically select one of the available profiles. If a profile is marked
#' as default (`Default=1`), its path is returned.
#' Otherwise, the first profile defined in the ini-file is returned.
#' If no profiles are defined, the function throws an error.
#'
#' @inheritParams list_profiles
#'
#' @return
#' a character vector of length 1 giving the path to the selected profile.
#'
#' @seealso List all available profiles with [list_profiles()].
#'
#' @export

autoselect_profile <- function(root_dir = guess_root_dir()) {

  profiles <- list_profiles(root_dir)

  if (length(profiles) == 0) {
    cli::cli_abort("There are no profiles available.")
  }

  # if there is a profile marked as default, return it. Otherwise, return the
  # first available profile.
  i_default <- attr(profiles, "default")
  profile <- if (!is.na(i_default)) {
    profiles[i_default]
  } else {
    profiles[1]
  }

  profile
}


#' Try to Guess the Directory Where the Firefox History Is Stored
#'
#' Try to guess the directory, where Firefox stores the history database. This
#' works according to the rules laid out in the documentation of
#' [`connect_history_db()`]. If it returns a directory path, this path is
#' guaranteed to exist. If guessing is unsuccessful, `NA` is returned.
#'
#' @returns
#' a character vector with the path to the root directory or `NA` if
#' guessing was unsuccessful.
#'
#' @export

guess_root_dir <- function() {

  system <- tolower(Sys.info()["sysname"])

  if (system == "linux") {
    # for Ubuntu, try the snap folder first
    if (stringr::str_detect(utils::osVersion, "Ubuntu")) {
      root_dir <- "~/snap/firefox/common/.mozilla/firefox"
      if (dir.exists(root_dir)) return(root_dir)
    }

    root_dir <- "~/.mozilla/firefox"
    if (dir.exists(root_dir)) return(root_dir)

  } else if (system == "windows") {
    app_dir <- Sys.getenv("APPDATA")
    root_dir <- file.path(app_dir, "Mozilla", "Firefox")
    if (dir.exists(root_dir)) return(root_dir)
  } else if (system == "darwin") {
    root_dir <- "~/Library/Application Support/Firefox"
    if (dir.exists(root_dir)) return(root_dir)
  }

  return(NA_character_)
}
