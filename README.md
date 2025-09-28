
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sessioncheck

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/sessioncheck/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/sessioncheck/actions/workflows/R-CMD-check.yaml)
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
# Basic use
sessioncheck::check_environment()
sessioncheck::check_packages()
#> Warning: Found loaded packages: digest, R6, fastmap, xfun, and 19 more

# To inspect the detected packages, assign the results
# to a variable. The pkg variable is a logical vector,
# with names corresponding to the detected packages. 
# Values are set to TRUE for base packages as well as 
# any packages included in the ignore list
pkg <- sessioncheck::check_packages()
#> Warning: Found loaded packages: digest, R6, fastmap, xfun, and 19 more
pkg
#>       digest      methods           R6      fastmap         xfun     magrittr         glue sessioncheck        knitr 
#>        FALSE         TRUE        FALSE        FALSE        FALSE        FALSE        FALSE         TRUE        FALSE 
#>    htmltools    rmarkdown    lifecycle        utils          cli          pak        vctrs      pkgdown     graphics 
#>        FALSE        FALSE        FALSE         TRUE        FALSE        FALSE        FALSE        FALSE         TRUE 
#>     testthat    grDevices        stats     compiler        purrr         base        tools         etal         brio 
#>        FALSE         TRUE         TRUE         TRUE        FALSE         TRUE         TRUE        FALSE        FALSE 
#>     evaluate         yaml        rlang           fs      usethis     datasets 
#>        FALSE        FALSE        FALSE        FALSE        FALSE         TRUE


# The same applies to objects detected in the global
# environment. Default behaviour is to permit hidden
# variables (i.e., those with names that start with 
# a dot)
obj <- sessioncheck::check_environment()
#> Warning: Found variables: pkg
obj
#> .Random.seed          pkg 
#>         TRUE        FALSE
```
