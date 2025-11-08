# Check session run time

Individual session check functions that inspect the session run time
information. Session checkers can produce errors, warnings, or messages
if requested.

## Usage

``` r
check_sessiontime(action = "warn", tol = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- tol:

  Maximum session time permitted in seconds before the checker takes
  action

## Value

Invisibly returns a status flag: `TRUE` if the elapsed run time for the
current session exceeds the tolerance, `FALSE` if it does not.

## Examples

``` r
check_sessiontime(action = "message")
```
