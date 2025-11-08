# sessioncheck

The goal of **sessioncheck** is to provide simple tools that can be
called at the top of a script, and produce warnings or errors if it
detects signs that the script is not being executed in a clean R
session. The intended user for **sessioncheck** is a beginner or
intermediate level R user who needs a drop-in replacement for the simple
but unsafe method of calling `rm(list = ls())` at the top of the script.

## Installation

You can install the development version of sessioncheck from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("djnavarro/sessioncheck")
```

## Example

The intention when using **sessioncheck** is that you would rarely load
it with [`library()`](https://rdrr.io/r/base/library.html). Instead, a
single line of code like this would be added at the top of the script:

``` r
sessioncheck::sessioncheck()
```

The default behaviour is to check for objects in the global environment
and to check packages and environments attached to the search path and
produce a warning if issues are detected. This can be converted to an
error if a stricter check is required, and additional checks can be
added if desired. For details on how the checks work and how they can be
customised see the [get
started](https://sessioncheck.djnavarro.net/articles/sessioncheck.html)
page.
