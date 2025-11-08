# Checks the overall status of the R session

Individual session check functions that each inspect one way in which an
R session could be considered not to be "clean". Session checkers can
produce errors, warnings, or messages if requested.

## Usage

``` r
sessioncheck(
  action = "warn",
  checks = c("globalenv_objects", "attached_packages", "attached_environments"),
  ...
)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- checks:

  Character vector listing the checks to run. The default is to run
  `checks = c("globalenv_objects", "attached_packages", "attached_environments")`

- ...:

  Arguments passed to individual checks

## Value

Invisibly returns a status object, a list of a named logical vectors.
Each vector has names that refer to detected entities for each specific
check. Values are `TRUE` if that entity triggers an action, `FALSE` if
it does not.

## Details

`sessioncheck()` allows the user to apply multiple session checks in a
single function

## Examples

``` r
sessioncheck(action = "message")
#> Session check results:
#> - Objects in global environment: [no issues]
#> - Attached packages: sessioncheck
#> - Attached environments: [no issues]
 
```
