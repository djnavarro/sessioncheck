
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
detects hints that it is not being executed in a clean R session. It not
intended as a replacement for sophisticated tools available to expert R
users. Instead, it is intended as drop-in replacement for the common
(but unsafe) approach of placing `rm(list = ls())` at the top of the
script. Rather than attempt to clean a dirty session using `rm()`, which
rarely works as well as one might hope, you can put `check_session()` at
the top of the script to produce a warning or an error if the R session
looks dirty

## Installation

You can install the development version of sessioncheck from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("djnavarro/sessioncheck")
```

## Basic use

The intention when using **sessioncheck** is that you would rarely if
ever load it with `library()`. Instead, a single line of code like this
would be added at the top of the script:

``` r
sessioncheck::check_session()
#> Warning: Session checks found the following issues:
#> - Attached packages: pak, pkgdown, testthat, usethis
#> - Loaded namespaces: digest, R6, fastmap, xfun, and 19 more
```

The default behaviour is to produce a warning when potential issues are
detected, but more often you’d want it to produce an error, which can be
accomplished with `sessioncheck::check_session("error")`. Explanations
of how the checks work – and how they can be customised – are provided
in the package documentation and vignettes.
