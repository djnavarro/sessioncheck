# Customizing sessionstate() output

The [session state
reporting](https://sessioncheck.djnavarro.net/articles/sessionstate-reporting.md)
and [session state
comparisons](https://sessioncheck.djnavarro.net/articles/sessionstate-comparison.md)
articles both capture and print a lot of detail. That’s the point when
you’re inspecting a session interactively, but it can get in the way
once
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)/[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
calls are embedded in something you run repeatedly – a rendered report,
a CI log, a script you rerun every day. You may want to consistently
hide a section you don’t care about (or don’t want to expose, per the
[privacy
discussion](https://sessioncheck.djnavarro.net/articles/sessionstate-reporting.html#the-cost-more-identifying-information)),
shorten a long table, or both, without repeating the same arguments
everywhere. This article covers how.

``` r

library(sessioncheck)
```

## Selecting fields for a single call

[`print()`](https://rdrr.io/r/base/print.html)/[`format()`](https://rdrr.io/r/base/format.html)
on a
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
result accept one argument per section (`platform`, `locale`, `matrix`,
`document`, `machine`, `git`, `timing`, `rng`, `packages`, `globalenv`,
`attachments`), plus `globalenv_n` for how many `globalenv` rows to
show. Passing `character(0)` hides a section entirely; passing a
character vector of column names narrows a tabular section to just those
columns.

For example, this hides `machine` (dropping hostname/username/working
directory), keeps only two columns of the package table, and shows just
the three largest `globalenv` objects:

``` r

print(
  sessionstate(),
  machine = character(0),
  packages = c("package", "loaded_version"),
  globalenv_n = 3
)
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version             R version 4.6.1 (2026-06-24)
#> • os                  Ubuntu 24.04.5 LTS
#> • system              x86_64, linux-gnu
#> • ui                  non-interactive
#> • tz                  UTC
#> • date                2026-09-13
#> 
#> ─ Locale ───────────────────────────────────────────────────────────────────────
#> • language            en-US
#> • collate             C.UTF-8
#> • ctype               C.UTF-8
#> 
#> ─ Matrix products ──────────────────────────────────────────────────────────────
#> • BLAS                /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
#> • LAPACK              /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so
#> 
#> ─ Document products ────────────────────────────────────────────────────────────
#> • pandoc              3.8.3
#> • quarto              (not found)
#> 
#> ─ Machine ──────────────────────────────────────────────────────────────────────
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha          d1ab25c1d945f7c01970c23b8dee4f108776ab46
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-13 09:25:57 UTC
#> • session uptime      0.712 sec
#> 
#> ─ RNG state ────────────────────────────────────────────────────────────────────
#> • kind                Mersenne-Twister
#> • normal kind         Inversion
#> • sample kind         Rejection
#> • seed hash           b71d56b44eb5ee9ceb53ef4cf66a2ed4
#> 
#> ─ Library paths [n = 3] ────────────────────────────────────────────────────────
#> • /home/runner/work/_temp/Library
#> • /opt/R/4.6.1/lib/R/site-library
#> • /opt/R/4.6.1/lib/R/library
#> 
#> ─ Packages [n = 34] (attached + loaded via namespace) ──────────────────────────
#>       package loaded_version
#>          base          4.6.1
#>         bslib         0.12.0
#>        cachem          1.1.0
#>           cli          3.6.6
#>      compiler          4.6.1
#>      datasets          4.6.1
#>          desc          1.4.3
#>        digest         0.6.39
#>      evaluate          1.0.5
#>       fastmap          1.2.0
#>            fs          2.1.0
#>      graphics          4.6.1
#>     grDevices          4.6.1
#>     htmltools          0.5.9
#>     jquerylib          0.1.4
#>      jsonlite          2.0.0
#>         knitr           1.52
#>     lifecycle          1.0.5
#>       methods          4.6.1
#>          otel          0.2.0
#>       pkgdown          2.2.1
#>            R6          2.6.1
#>          ragg          1.5.2
#>         rlang          1.3.0
#>     rmarkdown           2.32
#>          sass         0.4.10
#>  sessioncheck     0.1.1.9000
#>         stats          4.6.1
#>   systemfonts          1.3.2
#>   textshaping          1.0.5
#>         tools          4.6.1
#>         utils          4.6.1
#>          xfun           0.60
#>          yaml         2.3.12
#> 
#> ─ Global environment [n = 1] ───────────────────────────────────────────────────
#>          name   class   size
#>  .Random.seed integer 2.5 Kb
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

[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
results take a smaller, analogous set: `changed_only` (default `TRUE`,
collapsing unchanged sections to “(no changes)”),
`packages`/`globalenv`/`attachments` for column selection, and
`max_rows` for how many rows to show in each
`added`/`removed`/`modified` block.

None of this touches the underlying object – `x$machine`, `x$packages`,
`x$globalenv`, and so on always hold everything, regardless of what was
selected for display. Field selection is purely a
[`print()`](https://rdrr.io/r/base/print.html)/[`format()`](https://rdrr.io/r/base/format.html)-time
concern.

## Setting defaults once

Passing the same arguments at every call site gets repetitive,
especially if a whole team or a whole project wants the same defaults.
Like
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
(see [customizing sessioncheck()
behavior](https://sessioncheck.djnavarro.net/articles/customizing-sessioncheck.md)),
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)/[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
display options can be set globally via
`options(sessioncheck = list(...))`, typically in a `.Rprofile`:

``` r

options(
  sessioncheck = list(
    sessionstate_machine = character(0),
    sessionstate_globalenv_n = 3,
    sessionstatediff_max_rows = 5
  )
)
```

With that option set, calls that don’t pass an explicit argument pick up
these defaults automatically:

``` r

sessionstate()
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version             R version 4.6.1 (2026-06-24)
#> • os                  Ubuntu 24.04.5 LTS
#> • system              x86_64, linux-gnu
#> • ui                  non-interactive
#> • tz                  UTC
#> • date                2026-09-13
#> 
#> ─ Locale ───────────────────────────────────────────────────────────────────────
#> • language            en-US
#> • collate             C.UTF-8
#> • ctype               C.UTF-8
#> 
#> ─ Matrix products ──────────────────────────────────────────────────────────────
#> • BLAS                /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
#> • LAPACK              /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so
#> 
#> ─ Document products ────────────────────────────────────────────────────────────
#> • pandoc              3.8.3
#> • quarto              (not found)
#> 
#> ─ Machine ──────────────────────────────────────────────────────────────────────
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha          d1ab25c1d945f7c01970c23b8dee4f108776ab46
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-13 09:25:57 UTC
#> • session uptime      0.866 sec
#> 
#> ─ RNG state ────────────────────────────────────────────────────────────────────
#> • kind                Mersenne-Twister
#> • normal kind         Inversion
#> • sample kind         Rejection
#> • seed hash           b71d56b44eb5ee9ceb53ef4cf66a2ed4
#> 
#> ─ Library paths [n = 3] ────────────────────────────────────────────────────────
#> • /home/runner/work/_temp/Library
#> • /opt/R/4.6.1/lib/R/site-library
#> • /opt/R/4.6.1/lib/R/library
#> 
#> ─ Packages [n = 34] (attached + loaded via namespace) ──────────────────────────
#>       package attached loaded_version         source
#>          base        *          4.6.1           base
#>         bslib                  0.12.0 RSPM (R 4.6.0)
#>        cachem                   1.1.0 RSPM (R 4.6.0)
#>           cli                   3.6.6 RSPM (R 4.6.0)
#>      compiler                   4.6.1           base
#>      datasets        *          4.6.1           base
#>          desc                   1.4.3 RSPM (R 4.6.0)
#>        digest                  0.6.39 RSPM (R 4.6.0)
#>      evaluate                   1.0.5 RSPM (R 4.6.0)
#>       fastmap                   1.2.0 RSPM (R 4.6.0)
#>            fs                   2.1.0 RSPM (R 4.6.0)
#>      graphics        *          4.6.1           base
#>     grDevices        *          4.6.1           base
#>     htmltools                   0.5.9 RSPM (R 4.6.0)
#>     jquerylib                   0.1.4 RSPM (R 4.6.0)
#>      jsonlite                   2.0.0 RSPM (R 4.6.0)
#>         knitr                    1.52 RSPM (R 4.6.0)
#>     lifecycle                   1.0.5 RSPM (R 4.6.0)
#>       methods        *          4.6.1           base
#>          otel                   0.2.0 RSPM (R 4.6.0)
#>       pkgdown                   2.2.1 RSPM (R 4.6.0)
#>            R6                   2.6.1 RSPM (R 4.6.0)
#>          ragg                   1.5.2 RSPM (R 4.6.0)
#>         rlang                   1.3.0 RSPM (R 4.6.0)
#>     rmarkdown                    2.32 RSPM (R 4.6.0)
#>          sass                  0.4.10 RSPM (R 4.6.0)
#>  sessioncheck        *     0.1.1.9000      local (.)
#>         stats        *          4.6.1           base
#>   systemfonts                   1.3.2 RSPM (R 4.6.0)
#>   textshaping                   1.0.5 RSPM (R 4.6.0)
#>         tools                   4.6.1           base
#>         utils        *          4.6.1           base
#>          xfun                    0.60 RSPM (R 4.6.0)
#>          yaml                  2.3.12 RSPM (R 4.6.0)
#> 
#> ─ Global environment [n = 1] ───────────────────────────────────────────────────
#>          name   class   size
#>  .Random.seed integer 2.5 Kb
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

The precedence is the same as everywhere else in the package: an
explicit argument to
[`print()`](https://rdrr.io/r/base/print.html)/[`format()`](https://rdrr.io/r/base/format.html)
always wins; otherwise the relevant field in
`options(sessioncheck = list(...))` is used; otherwise a built-in
default applies. The option field names mirror the print arguments with
a prefix identifying which class they apply to –
`sessionstate_platform`, `sessionstate_machine`,
`sessionstate_globalenv_n`, and so on for
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md),
and `sessionstatediff_changed_only`, `sessionstatediff_packages`,
`sessionstatediff_max_rows`, and so on for
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md).
See
[`?display_methods`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
for the complete list of arguments and their corresponding option names.

## What this doesn’t affect

Field selection is purely cosmetic: it changes what
[`print()`](https://rdrr.io/r/base/print.html)/[`format()`](https://rdrr.io/r/base/format.html)
shows, never what
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)/[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
capture or return. In particular:

- `x$platform`, `x$machine`, `x$packages`, `x$globalenv`, and every
  other element of a
  [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)/[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
  result are always complete, no matter what display options are in
  effect.
- [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) on
  either class always returns every row of the table it selects (see
  [`?coercion_methods`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md))
  – there is no `max_rows`-style truncation for programmatic use, only
  for the printed/formatted view.

If you need to filter or redact data itself, rather than just its
display, do that after capture – for example,
`x$globalenv <- x$globalenv[, c("name", "class")]` before saving or
sharing `x` – rather than relying on print options to do it for you.
