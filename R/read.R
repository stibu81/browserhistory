#' Read History From Database
#'
#' Read the Browser History from the database. The function can be called
#' with a database connection created with [`connect_history_db()`] or by
#' specifying a root directory and (optionally).
#'
#' @param con a connection to a history database created with
#'   [`connect_history_db()`].
#' @param tz character giving the time zone to be used for the conversion of
#'   the timestamps. The default value `""` is the current time zone.
#'   See [time zones][base::timezones] for more information on time zones in R.
#' @inheritParams list_profiles
#' @inheritParams connect_history_db
#'
#' @return
#' a `tibble` with the browser history
#'
#' @export

read_browser_history <- function(con = NULL,
                                 root_dir = NULL,
                                 profile = autoselect_profile(root_dir),
                                 tz = "") {

  # if no connection is given, connect now
  local_connection <- FALSE
  if (is.null(con)) {
    con <- connect_history_db(root_dir, profile)
    local_connection <- TRUE
  } else if (!inherits(con, "SQLiteConnection") || !RSQLite::dbIsValid(con)) {
    cli::cli_abort("con is not a valid database connection.")
  }

  # the history is spread over two tables: moz_historyvisits contains the
  # timestamps, when sites were visited and moz_places contains metadata
  # on those sites. They can be combined using the place_id
  moz_visits <- dplyr::tbl(con, "moz_historyvisits")
  moz_places <- dplyr::tbl(con, "moz_places")

  hist_combined <- moz_visits |>
    dplyr::left_join(moz_places, by = c("place_id" = "id")) |>
    dplyr::collect() |>
    dplyr::mutate(visit_date = as.POSIXct(.data$visit_date/1e6, tz = tz))

  # disconnect the database if the connection has been created within this
  # function
  if (local_connection) RSQLite::dbDisconnect(con)

  hist_combined
}
