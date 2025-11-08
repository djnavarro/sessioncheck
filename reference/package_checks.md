# Check loaded namespaces and attached packages

Individual session check functions that examine attached packages and
loaded namespaces. Session checkers can produce errors, warnings, or
messages if requested.

## Usage

``` r
check_packages(action = "warn", allow = NULL)

check_namespaces(action = "warn", allow = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- allow:

  Character vector containing names of packages that are "allowed", and
  will not trigger an action. Base priority packages are always allowed
  and will never trigger actions (see details).

## Value

Invisibly returns a status flag vector, a logical vector with names
referring to a detected package. Values are `TRUE` if the package
triggers an action, `FALSE` if it does not.

## Details

The default behaviour of the `allow` argument is slightly for each
checker:

- `check_packages()`: This checker inspects the list of packages that
  have been attached to the search path (e.g., via
  [`library()`](https://rdrr.io/r/base/library.html)). Regardless of the
  value of `allow`, R packages that have "base" priority (e.g.,
  **base**, **utils**, and **grDevices**) do not trigger an action. When
  `allow = NULL` these are the only packages that will not trigger
  actions.

- `check_namespaces()`: This checker inspects the list of loaded
  namespaces (packages that have been loaded but not attached). The
  `allow` argument for this checker is almost identical to
  `check_packages()`: the only difference is that the **sessioncheck**
  package is always allowed as a loaded namespace, since the package
  namespace must be loaded in order to call the function itself.

## Examples

``` r
check_packages(action = "message")
#> Attached packages: sessioncheck
check_namespaces(action = "message")
#> Loaded namespaces: jsonlite, xml2, jquerylib, textshaping, and 39 more
 
```
