# sessioncheck

The goal of **sessioncheck** is to provide simple tools that can be
called at the top of a script, and produce warnings or errors if it
detects signs that the script is not being executed in a clean R
session. The intended user for **sessioncheck** is a beginner or
intermediate level R user who has learned enough about R to understand
the limitations of using `rm(list = ls())` as a method to clean the R
session, but is perhaps not at the point that they can take advantage of
sophisticated tools like [targets](https://books.ropensci.org/targets/),
[callr](https://callr.r-lib.org/), and so on.

In short, the goal is to provide a simple drop-in replacement for
`rm(list = ls())`.

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
error by using `sessioncheck::sessioncheck("error")` if a stricter check
is required, and additional checks (e.g., loaded namespaces, session
runtime) can be added if desired.

Explanations of how the checks work and how they can be customised are
provided on the [get
started](https://sessioncheck.djnavarro.net/articles/sessioncheck.html)
page.
