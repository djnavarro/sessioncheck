
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sessioncheck

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/sessioncheck/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/sessioncheck/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test
coverage](https://codecov.io/gh/djnavarro/sessioncheck/graph/badge.svg)](https://app.codecov.io/gh/djnavarro/sessioncheck)
<!-- badges: end -->

The goal of **sessioncheck** is to provide simple tools that can be
called at the top of a script, and produce warnings or errors if it
detects hints that it is not being executed in a clean R session. It is
not intended as a replacement for sophisticated tools such as
**targets**, **renv**, **callr**, and the like. These are tools that
expert R users can use to impose tight controls over how a script is
executed, and for expert-level users these are strongly recommended over
**sessioncheck**. The purpose of **sessioncheck** is to provide a
collection of simple tools that novice or intermediate level R users can
use, as a drop-in replacement for the common (but unsafe) approach of
placing `rm(list = ls())` at the top of the script.

## Installation

You can install the development version of sessioncheck from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("djnavarro/sessioncheck")
```

## Example

``` r
# Basic use: the default action is to warn the user
sessioncheck::check_environment()
sessioncheck::check_packages()
#> Warning: Found loaded packages: digest, R6, fastmap, xfun, and 19 more

# To inspect the detected packages, assign the results to a variable. The pkg 
# variable is a logical vector, with names corresponding to the detected 
# packages. Values are set to TRUE for base packages as well as  any packages 
# included in the ignore list
pkg <- sessioncheck::check_packages(action = "none")
pkg
#>       digest      methods           R6      fastmap         xfun     magrittr 
#>        FALSE         TRUE        FALSE        FALSE        FALSE        FALSE 
#>         glue sessioncheck        knitr    htmltools    rmarkdown    lifecycle 
#>        FALSE         TRUE        FALSE        FALSE        FALSE        FALSE 
#>        utils          cli          pak        vctrs      pkgdown     graphics 
#>         TRUE        FALSE        FALSE        FALSE        FALSE         TRUE 
#>     testthat    grDevices        stats     compiler        purrr         base 
#>        FALSE         TRUE         TRUE         TRUE        FALSE         TRUE 
#>        tools         etal         brio     evaluate         yaml        rlang 
#>         TRUE        FALSE        FALSE        FALSE        FALSE        FALSE 
#>           fs      usethis     datasets 
#>        FALSE        FALSE         TRUE


# The same applies to objects detected in the global environment. The default 
# behaviour is to permit hidden variables (i.e., those with names that start 
# with a dot)
obj <- sessioncheck::check_environment(action = "none")
obj
#> .Random.seed          pkg 
#>         TRUE        FALSE
```
