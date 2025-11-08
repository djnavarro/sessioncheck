# Check required values for options, locale, and environment

Individual session check functions that inspect the session options,
locale, or system environment variables. Session checkers can produce
errors, warnings, or messages if requested.

## Usage

``` r
check_options(action = "warn", required = NULL)

check_sysenv(action = "warn", required = NULL)

check_locale(action = "warn", required = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required:

  A named list of required options, locale settings, or environment
  variables. If any of these values are missing, or have different
  values, an action is triggered.

## Value

Invisibly returns a status flag vector, a logical vector with names that
match those in `required`. If the session value matches the required
value, no action is triggered and the status flag is `FALSE`. For
mismatches or absent values, the flag is `TRUE`.

## Examples

``` r
check_options(action = "message", required = list(scipen = 0L, max.print = 50L))
#> Unexpected options: max.print
```
