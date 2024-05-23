# convert timestamps from Firefox history to POSIX and vice versa
firefox_ts_to_posix <- function(ts, tz = "") {
  as.POSIXct(ts/1e6, tz = tz)
}

posix_to_firefox_ts <- function(ts) {
  as.numeric(ts) * 1e6
}
