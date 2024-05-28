
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
that contains `profiles.ini` as the root directory.

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

You can use the function `guess_root_dir()` that tries to find a
suitable root directory according to the above rules.

``` r
guess_root_dir()
#> [1] "~/snap/firefox/common/.mozilla/firefox"
```

Most of the functions that take a root directory as input use
`guess_root_dir()` as the default value. So, on some system, it will be
enough to simply call `read_browser_history()` without any inputs to get
a result:

``` r
read_browser_history()
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

The structure of the root directory depends on the system. In all cases,
it contains the file `profiles.ini` that stores the information about
the available profiles. Use `list_profiles()` too see, which profiles
there are:

``` r
list_profiles(root_dir)
#>          other        default 
#>  "bad_profile" "test_profile" 
#> attr(,"default")
#> [1] 2
```

The test data contains two profiles and the second one is the default,
as is indicated by the attribute `"default"`:

``` r
attr(list_profiles(root_dir), "default")
#> [1] 2
```

The values of the vector indicate the directories in which the profile
data is stored. As one can check, the test data indeed contain a
directory for each profile:

``` r
list.files(root_dir, recursive = FALSE)
#> [1] "bad_profile"  "profiles.ini" "test_profile"
```

The full structure of the root directory on Linux looks as follows:

    root_dir
    ├── bad_profile
    │   └── somefile
    ├── profiles.ini
    └── test_profile
        └── places.sqlite

The profile `test_profile` actually contains the history database
`places.sqlite` (next to many other files in an actual root directory).
Sometimes, there are invalid profile like `bad_profile` that do not
contain `places.sqlite`.

On Windows, the root directory contains a directory `Profiles` that has
the profile directories as subdirectories. The equivalent of the test
data would have the following structure:

    root_dir
    ├── Profiles
    │   ├── bad_profile
    │   │   └── somefile
    │   └── test_profile
    │       └── places.sqlite
    └── profiles.ini

`read_firefox_history()` will automatically select the default profile,
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

On Windows, since the profile directories are inside a subdirectory, the
equivalent call would look as follows:

``` r
history <- read_browser_history(root_dir = root_dir, profile = "Profiles/test_profile")
```
