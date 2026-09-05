# S3 classes and methods

``` r

library(sessioncheck)
```

The **sessioncheck** package is designed to be lightweight, and has no
dependencies. It defines three S3 classes: the individual check
functions return objects of class `sessioncheck_status`, the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function returns an object of class `sessioncheck_sessioncheck`, and
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
returns an object of class `sessioncheck_sessionstate`.

``` r

pkg_status <- check_attached_packages(action = "none")
obj_status <- check_globalenv_objects(action = "none") 
session_check <- sessioncheck(action = "none")
session_state <- sessionstate()

class(pkg_status)
#> [1] "sessioncheck_status"
class(obj_status)
#> [1] "sessioncheck_status"
class(session_check)
#> [1] "sessioncheck_sessioncheck"
class(session_state)
#> [1] "sessioncheck_sessionstate"
```

All three classes have a
[`format()`](https://rdrr.io/r/base/format.html) method and a
[`print()`](https://rdrr.io/r/base/print.html) method, and all three are
coercible to data frames via
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
  created the status object.

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
#> ✖ Attached packages: sessioncheck
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
#> ✖ Objects in global environment: obj_status, pkg_status
#> ✖ Attached packages: sessioncheck
#> ✔ Attached environments: [no issues detected]
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

## sessioncheck_sessionstate objects

Unlike the two classes above, a `sessioncheck_sessionstate` object isn’t
a check result – it’s a snapshot of session state produced by
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md),
intended as an audit record rather than a pass/fail judgment. Internally
it’s a named list with twelve components (`platform`, `locale`,
`matrix`, `document`, `machine`, `git`, `timing`, `rng`, `libpaths`,
`packages`, `globalenv`, `attachments`), most of which are themselves
lists or data frames rather than simple vectors:

``` r

str(unclass(session_state), max.level = 1)
#> List of 12
#>  $ platform   :List of 6
#>  $ locale     :List of 3
#>  $ matrix     :List of 2
#>  $ document   :List of 2
#>  $ machine    :List of 3
#>  $ git        :List of 2
#>  $ timing     :List of 2
#>  $ rng        :List of 4
#>  $ libpaths   : chr [1:3] "/home/runner/work/_temp/Library" "/opt/R/4.6.1/lib/R/site-library" "/opt/R/4.6.1/lib/R/library"
#>  $ packages   :'data.frame': 34 obs. of  10 variables:
#>  $ globalenv  :'data.frame': 4 obs. of  3 variables:
#>  $ attachments:'data.frame': 11 obs. of  2 variables:
```

Because there’s a lot captured here, the
[`format()`](https://rdrr.io/r/base/format.html) and
[`print()`](https://rdrr.io/r/base/print.html) methods accept optional
arguments (one per component, plus `globalenv_n`) that select which
fields or columns to display, without touching the underlying object:

``` r

print(session_state, packages = "package", globalenv = "class", machine = character(0))
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version         R version 4.6.1 (2026-06-24)
#> • os              Ubuntu 24.04.4 LTS
#> • system          x86_64, linux-gnu
#> • ui              non-interactive
#> • tz              UTC
#> • date            2026-09-05
#> 
#> ─ Locale ───────────────────────────────────────────────────────────────────────
#> • language        en-US
#> • collate         C.UTF-8
#> • ctype           C.UTF-8
#> 
#> ─ Matrix products ──────────────────────────────────────────────────────────────
#> • BLAS            /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
#> • LAPACK          /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so
#> 
#> ─ Document products ────────────────────────────────────────────────────────────
#> • pandoc          3.8.3
#> • quarto          (not found)
#> 
#> ─ Machine ──────────────────────────────────────────────────────────────────────
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha      e9b01e150baf84de167b7e21de9630947f83e519
#> • dirty           FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at              2026-09-05 13:43:53 UTC
#> • session runtime (sec)    0.818
#> 
#> ─ RNG state ────────────────────────────────────────────────────────────────────
#> • kind            Mersenne-Twister
#> • normal kind     Inversion
#> • sample kind     Rejection
#> • seed hash       b71d56b44eb5ee9ceb53ef4cf66a2ed4
#> 
#> ─ Library paths [n = 3] ────────────────────────────────────────────────────────
#> • /home/runner/work/_temp/Library
#> • /opt/R/4.6.1/lib/R/site-library
#> • /opt/R/4.6.1/lib/R/library
#> 
#> ─ Packages [n = 34] (attached + loaded via namespace) ──────────────────────────
#>       package
#>          base
#>         bslib
#>        cachem
#>           cli
#>      compiler
#>      datasets
#>          desc
#>        digest
#>      evaluate
#>       fastmap
#>            fs
#>      graphics
#>     grDevices
#>     htmltools
#>     jquerylib
#>      jsonlite
#>         knitr
#>     lifecycle
#>       methods
#>          otel
#>       pkgdown
#>            R6
#>          ragg
#>         rlang
#>     rmarkdown
#>          sass
#>  sessioncheck
#>         stats
#>   systemfonts
#>   textshaping
#>         tools
#>         utils
#>          xfun
#>          yaml
#> 
#> ─ Global environment [n = 4] ───────────────────────────────────────────────────
#>                      class
#>  sessioncheck_sessioncheck
#>                    integer
#>        sessioncheck_status
#>        sessioncheck_status
#> 
#> ─ Attached environments [n = 11] ───────────────────────────────────────────────
#>                  name    type
#>            .GlobalEnv   other
#>  package:sessioncheck package
#>         package:stats package
#>      package:graphics package
#>     package:grDevices package
#>         package:utils package
#>      package:datasets package
#>       package:methods package
#>             Autoloads   other
#>           tools:callr   other
#>          package:base package
```

See
[`?display_methods`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
for the complete list of these arguments and how their defaults are
resolved.

The [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
method is necessarily different here too. For
`sessioncheck_status`/`sessioncheck_sessioncheck` objects, the coercion
is lossless: every entity and status recorded in `x` shows up as a row.
That guarantee is impossible for `sessioncheck_sessionstate`, because
there is no single rectangular table that could hold eight scalar-field
components, a bare character vector, and three differently-shaped data
frames all at once. Rather than pretend otherwise,
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
exactly one of the three tabular components – `packages`, `globalenv`,
or `attachments` – selected via its `which` argument (defaulting to
`"packages"`, the largest and most commonly needed of the three):

``` r

head(as.data.frame(session_state))
#>    package attached ondisk_version loaded_version version_mismatch
#> 1     base     TRUE          4.6.1          4.6.1            FALSE
#> 2    bslib    FALSE         0.12.0         0.12.0            FALSE
#> 3   cachem    FALSE          1.1.0          1.1.0            FALSE
#> 4      cli    FALSE          3.6.6          3.6.6            FALSE
#> 5 compiler    FALSE          4.6.1          4.6.1            FALSE
#> 6 datasets     TRUE          4.6.1          4.6.1            FALSE
#>                              ondisk_path                            loaded_path
#> 1        /opt/R/4.6.1/lib/R/library/base        /opt/R/4.6.1/lib/R/library/base
#> 2  /home/runner/work/_temp/Library/bslib  /home/runner/work/_temp/Library/bslib
#> 3 /home/runner/work/_temp/Library/cachem /home/runner/work/_temp/Library/cachem
#> 4    /home/runner/work/_temp/Library/cli    /home/runner/work/_temp/Library/cli
#> 5    /opt/R/4.6.1/lib/R/library/compiler    /opt/R/4.6.1/lib/R/library/compiler
#> 6    /opt/R/4.6.1/lib/R/library/datasets    /opt/R/4.6.1/lib/R/library/datasets
#>   path_mismatch removed_from_disk         source
#> 1         FALSE             FALSE           base
#> 2         FALSE             FALSE RSPM (R 4.6.0)
#> 3         FALSE             FALSE RSPM (R 4.6.0)
#> 4         FALSE             FALSE RSPM (R 4.6.0)
#> 5         FALSE             FALSE           base
#> 6         FALSE             FALSE           base
head(as.data.frame(session_state, which = "globalenv"))
#>            name                     class size
#> 1  .Random.seed                   integer 2552
#> 2    obj_status       sessioncheck_status 1080
#> 3    pkg_status       sessioncheck_status 1496
#> 4 session_check sessioncheck_sessioncheck 5248
```

The eight scalar-field components (`platform`, `locale`, `matrix`,
`document`, `machine`, `git`, `timing`, `rng`) and `libpaths` are never
included in
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)’s output,
regardless of `which` – access them directly via
`session_state$platform`, `session_state$machine`, and so on, or via
`unclass(session_state)` for everything at once. See [sessionstate()
versus sessionInfo() and
session_info()](https://sessioncheck.djnavarro.net/articles/sessionstate-vs-sessioninfo.md)
for a discussion of what each component captures.
