#' Read History From Database
#'
#' Read the Browser History from the database. The function can be called
#' with a database connection created with [`connect_history_db()`] or by
#' specifying a root directory and (optionally).
#'
#' @param con a connection to a history database created with
#'   [`connect_history_db()`]. Instead of passing a connection, you can also
#'   specify a root directory and (optionally) a profile and the function
#'   will build up the connection automatically.
#' @param start_time,end_time POSIXt objects that specifies the time interval
#'  for which browser history will be returned.
#' @param tz character giving the time zone to be used for the conversion of
#'   the timestamps. The default value `""` is the current time zone.
#'   See [time zones][base::timezones] for more information on time zones in R.
#' @param raw logical. Should a raw table with all columns be returned?
#' @inheritParams list_profiles
#' @inheritParams connect_history_db
#'
#' @return
#' a `tibble` with the browser history
#'
#' @export

read_browser_history <- function(con = NULL,
                                 root_dir = guess_root_dir(),
                                 profile = autoselect_profile(root_dir),
                                 start_time = NULL,
                                 end_time = NULL,
                                 tz = "",
                                 raw = FALSE) {

  # check inputs
  if (!is.null(start_time) && !lubridate::is.POSIXt(start_time)) {
    cli::cli_abort("start_time must be a POSIXt object.")
  }
  if (!is.null(end_time) && !lubridate::is.POSIXt(end_time)) {
    cli::cli_abort("end_time must be a POSIXt object.")
  }

  local_connection <- connect_local(con, root_dir, profile)
  con <- local_connection$con

  if (is_locked(con)) {
    cli::cli_abort(
      "The database is locked. Close Firefox before reading the history."
    )
  }

  # the history is spread over two tables: moz_historyvisits contains the
  # timestamps, when sites were visited and moz_places contains metadata
  # on those sites. They can be combined using the place_id
  moz_visits <- dplyr::tbl(con, "moz_historyvisits")
  moz_places <- dplyr::tbl(con, "moz_places")
  moz_origins <- dplyr::tbl(con, "moz_origins") |>
    dplyr::select("id", "prefix", "host")

  # if a time filter is given, apply it to the visits before joining
  if (!is.null(start_time)) {
    start_time_ts <- posix_to_firefox_ts(start_time)
    moz_visits <- moz_visits |>
      dplyr::filter(.data$visit_date >= start_time_ts)
  }
  if (!is.null(end_time)) {
    end_time_ts <- posix_to_firefox_ts(end_time)
    moz_visits <- moz_visits |>
      dplyr::filter(.data$visit_date <= end_time_ts)
  }

  hist_combined <- moz_visits |>
    dplyr::left_join(moz_places, by = c("place_id" = "id")) |>
    dplyr::left_join(moz_origins, by = c("origin_id" = "id"))

  # simplify the table unless the raw table is requested
  if (!raw) {
    hist_combined <- hist_combined |>
      dplyr::select("id", "visit_date", "url", "title", "visit_count",
                    "last_visit_date", "description", "prefix", "host")
  }

  # parse the date columns
  hist_combined <- hist_combined |>
    dplyr::collect() |>
    dplyr::mutate(
      visit_date = firefox_ts_to_posix(.data$visit_date, tz = tz),
      last_visit_date = firefox_ts_to_posix(.data$last_visit_date, tz = tz)
    )

  # disconnect the database if the connection has been created within this
  # function
  if (local_connection$is_local) RSQLite::dbDisconnect(con)

  hist_combined
}
