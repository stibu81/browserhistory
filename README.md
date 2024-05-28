
<!-- README.md is generated from README.Rmd. Please edit that file -->

# browserhistory

<!-- badges: start -->

[![R-CMD-check](https://github.com/stibu81/browserhistory/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/stibu81/browserhistory/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/stibu81/browserhistory/branch/main/graph/badge.svg)](https://app.codecov.io/gh/stibu81/browserhistory?branch=main)
<!-- badges: end -->

browserhistory offers tools to read and analyse the browser history of
Firefox with R. Support for other browsers might be added in the future.

## Installation

You can install the development version of browserhistory from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("stibu81/browserhistory")
```

## Reading the Browser History

Firefox stores the browser history in a SQLite database called
`places.sqlite`. The function `read_firefox_history()` reads the browser
history from this database and returns it as a tibble. The package
contains a small example database that is read in the following example:

``` r
library(browserhistory)
root_dir <- get_test_root_dir()
history <- read_browser_history(root_dir = root_dir)
history
#> # A tibble: 26 × 9
#>        id visit_date          url          title visit_count last_visit_date    
#>     <int> <dttm>              <chr>        <chr>       <int> <dttm>             
#>  1 524118 2024-05-24 17:42:17 https://duc… Duck…          18 2024-05-24 17:42:17
#>  2 524119 2024-05-24 17:42:28 https://duc… <NA>            5 2024-05-24 17:42:28
#>  3 524120 2024-05-24 17:42:29 https://duc… fire…          11 2024-05-24 17:42:29
#>  4 524121 2024-05-24 17:42:30 https://duc… fire…          13 2024-05-24 17:42:30
#>  5 524122 2024-05-24 17:42:51 https://blo… A fr…          13 2024-05-24 17:42:51
#>  6 524123 2024-05-24 17:43:02 https://www… Inte…           9 2024-05-24 17:43:02
#>  7 524124 2024-05-24 17:43:15 https://en.… <NA>            6 2024-05-24 17:43:15
#>  8 524125 2024-05-24 17:43:15 https://en.… Wiki…           8 2024-05-24 17:43:15
#>  9 524126 2024-05-24 17:43:22 https://en.… <NA>           20 2024-05-24 17:43:22
#> 10 524127 2024-05-24 17:43:22 https://en.… <NA>           15 2024-05-24 17:43:22
#> # ℹ 16 more rows
#> # ℹ 3 more variables: description <chr>, prefix <chr>, host <chr>
```

In order to read the history, you need to figure out where Firefox
stores the relevant files. The folder contains a file called
`profiles.ini` and subfolders for one or more profiles. Use the folder
that contains `profiles.ini` as the root directory. In the case of the
test data contained in browserhistory, the structure is as follows:

``` r
list.files(root_dir, recursive = TRUE)
#> [1] "bad_profile/somefile"       "profiles.ini"              
#> [3] "test_profile/places.sqlite"
```

`read_firefox_history()` will automatically select the default profiles,
but when there are several profiles and you want to read a different
one, you have to pass the name of the profile folder to the `profile`
argument as follows:

``` r
history <- read_browser_history(root_dir = root_dir, profile = "test_profile")
history
#> # A tibble: 26 × 9
#>        id visit_date          url          title visit_count last_visit_date    
#>     <int> <dttm>              <chr>        <chr>       <int> <dttm>             
#>  1 524118 2024-05-24 17:42:17 https://duc… Duck…          18 2024-05-24 17:42:17
#>  2 524119 2024-05-24 17:42:28 https://duc… <NA>            5 2024-05-24 17:42:28
#>  3 524120 2024-05-24 17:42:29 https://duc… fire…          11 2024-05-24 17:42:29
#>  4 524121 2024-05-24 17:42:30 https://duc… fire…          13 2024-05-24 17:42:30
#>  5 524122 2024-05-24 17:42:51 https://blo… A fr…          13 2024-05-24 17:42:51
#>  6 524123 2024-05-24 17:43:02 https://www… Inte…           9 2024-05-24 17:43:02
#>  7 524124 2024-05-24 17:43:15 https://en.… <NA>            6 2024-05-24 17:43:15
#>  8 524125 2024-05-24 17:43:15 https://en.… Wiki…           8 2024-05-24 17:43:15
#>  9 524126 2024-05-24 17:43:22 https://en.… <NA>           20 2024-05-24 17:43:22
#> 10 524127 2024-05-24 17:43:22 https://en.… <NA>           15 2024-05-24 17:43:22
#> # ℹ 16 more rows
#> # ℹ 3 more variables: description <chr>, prefix <chr>, host <chr>
```

The following list gives hints on where to find the root directory on a
small number of systems:

- **Ubuntu 20.04/22.04:** If Firefox has been installed from a deb
  package, the root directory is `⁠~/.mozilla/firefox`. (This might also
  be true for other Debian-based distributions.) If Firefox has been
  installed as a snap package, the root directory is
  `⁠~/snap/firefox/common/.mozilla/firefox`⁠.
- **Windows 10/11:** The root directory is
  `⁠C:\Users\<username>\AppData\Roaming\Mozilla\Firefox`, where
  `<username>` must be replaced by your user name.
