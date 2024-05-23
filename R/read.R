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
#' @param raw logical. Should a raw table with all columns be returned?
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
                                 tz = "",
                                 raw = FALSE) {

  local_connection <- connect_local(con, root_dir, profile)
  con <- local_connection$con

  # the history is spread over two tables: moz_historyvisits contains the
  # timestamps, when sites were visited and moz_places contains metadata
  # on those sites. They can be combined using the place_id
  moz_visits <- dplyr::tbl(con, "moz_historyvisits")
  moz_places <- dplyr::tbl(con, "moz_places")
  moz_origins <- dplyr::tbl(con, "moz_origins") |>
    dplyr::select("id", "prefix", "host")

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
