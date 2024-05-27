library(lubridate, warn.conflicts = FALSE)

ff_ts <- c(1716565337883336, 1716565348798941,
           1716565349171490, 1716565350439258)
ts <- as.POSIXct(c("2024-05-24 17:42:17.883336", "2024-05-24 17:42:28.798941",
                 "2024-05-24 17:42:29.17149", "2024-05-24 17:42:30.439258"),
                 tz = "CET")

test_that("test firefox_ts_to_posix()", {
  expect_equal(firefox_ts_to_posix(ff_ts, tz = "CET"), ts)
  expect_equal(firefox_ts_to_posix(ff_ts, tz = "UTC"), with_tz(ts, tz = "UTC"))
})

test_that("test posix_to_firefox_ts()", {
  expect_equal(posix_to_firefox_ts(ts), ff_ts)
  expect_equal(posix_to_firefox_ts(with_tz(ts, tz = "UTC")), ff_ts)
})
