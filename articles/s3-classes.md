# S3 classes and methods

``` r
library(sessioncheck)
```

The **sessioncheck** package is designed to be lightweight, and has no
dependencies. It defines two S3 classes: the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function returns an object of class `sessioncheck_sessioncheck` and the
individual check functions return objects of class
`sessioncheck_status`.

``` r
pkg_status <- check_attached_packages(action = "none")
obj_status <- check_globalenv_objects(action = "none") 
session_check <- sessioncheck(action = "none")

class(pkg_status)
#> [1] "sessioncheck_status"
class(obj_status)
#> [1] "sessioncheck_status"
class(session_check)
#> [1] "sessioncheck_sessioncheck"
```

Both classes have a [`format()`](https://rdrr.io/r/base/format.html)
method and a [`print()`](https://rdrr.io/r/base/print.html) method, and
both are coercible to data frames via
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html). A brief
discussion of these classes and methods is provided here.

## sessioncheck_status objects

Internally, a `sessioncheck_status` object is a named list with two
components:

- The `status` component is a named logical vector where names
  correspond to detected entities, and values that indicate whether an
  action is triggered by that entity. It is intended to be roughly
  analogous to an “exit status”: `FALSE` corresponds to exit status zero
  and no actions are triggered, `TRUE` is a non-zero exist status and
  actions can be taken.
- The `type` component is a string indicating which check function
  create the status object.

This is illustrated below:

``` r
unclass(pkg_status)
#> $status
#> sessioncheck        stats     graphics    grDevices        utils     datasets 
#>         TRUE        FALSE        FALSE        FALSE        FALSE        FALSE 
#>      methods         base 
#>        FALSE        FALSE 
#> 
#> $type
#> [1] "package"
```

The [`format()`](https://rdrr.io/r/base/format.html) and
[`print()`](https://rdrr.io/r/base/print.html) methods for a
`sessioncheck_status` object produce the text displayed to the user in
any message, warning, or error:

``` r
print(pkg_status)
#> Attached packages: sessioncheck
```

As a convenience, an
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) method is
also supplied:

``` r
as.data.frame(pkg_status)
#>      type       entity status
#> 1 package sessioncheck   TRUE
#> 2 package        stats  FALSE
#> 3 package     graphics  FALSE
#> 4 package    grDevices  FALSE
#> 5 package        utils  FALSE
#> 6 package     datasets  FALSE
#> 7 package      methods  FALSE
#> 8 package         base  FALSE
```

## sessioncheck_sessioncheck objects

Because the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function can call multiple checks, the data structure it returns is
slightly different. As illustrated below it is a named list of
`sessioncheck_status` objects:

``` r
lapply(session_check, unclass)
#> $globalenv
#> $globalenv$status
#> .Random.seed   obj_status   pkg_status 
#>        FALSE         TRUE         TRUE 
#> 
#> $globalenv$type
#> [1] "globalenv"
#> 
#> 
#> $packages
#> $packages$status
#> sessioncheck        stats     graphics    grDevices        utils     datasets 
#>         TRUE        FALSE        FALSE        FALSE        FALSE        FALSE 
#>      methods         base 
#>        FALSE        FALSE 
#> 
#> $packages$type
#> [1] "package"
#> 
#> 
#> $attachments
#> $attachments$status
#>           .GlobalEnv package:sessioncheck        package:stats 
#>                FALSE                FALSE                FALSE 
#>     package:graphics    package:grDevices        package:utils 
#>                FALSE                FALSE                FALSE 
#>     package:datasets      package:methods            Autoloads 
#>                FALSE                FALSE                FALSE 
#>          tools:callr         package:base 
#>                FALSE                FALSE 
#> 
#> $attachments$type
#> [1] "attachment"
```

As before, the [`format()`](https://rdrr.io/r/base/format.html) and
[`print()`](https://rdrr.io/r/base/print.html) methods are used to
construct the text to be displayed to the user:

``` r
print(session_check)
#> Session check results:
#> - Objects in global environment: obj_status, pkg_status
#> - Attached packages: sessioncheck
#> - Attached environments: [no issues detected]
```

Similarly, there is an
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) method
provided as a convenience:

``` r
as.data.frame(session_check)
#>          type               entity status
#> 1   globalenv         .Random.seed  FALSE
#> 2   globalenv           obj_status   TRUE
#> 3   globalenv           pkg_status   TRUE
#> 4     package         sessioncheck   TRUE
#> 5     package                stats  FALSE
#> 6     package             graphics  FALSE
#> 7     package            grDevices  FALSE
#> 8     package                utils  FALSE
#> 9     package             datasets  FALSE
#> 10    package              methods  FALSE
#> 11    package                 base  FALSE
#> 12 attachment           .GlobalEnv  FALSE
#> 13 attachment package:sessioncheck  FALSE
#> 14 attachment        package:stats  FALSE
#> 15 attachment     package:graphics  FALSE
#> 16 attachment    package:grDevices  FALSE
#> 17 attachment        package:utils  FALSE
#> 18 attachment     package:datasets  FALSE
#> 19 attachment      package:methods  FALSE
#> 20 attachment            Autoloads  FALSE
#> 21 attachment          tools:callr  FALSE
#> 22 attachment         package:base  FALSE
```
