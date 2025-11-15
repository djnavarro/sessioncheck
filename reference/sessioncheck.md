# Checks the overall status of the R session

Individual session check functions that each inspect one way in which an
R session could be considered not to be "clean". Session checkers can
produce errors, warnings, or messages if requested.

## Usage

``` r
sessioncheck(action = NULL, checks = NULL, ...)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". If the user does not specify
  an action the default to set `action = "warn"`.

- checks:

  Character vector listing the checks to run. If the user does not
  specify the checks, the default is to run
  `checks = c("globalenv_objects", "attached_packages", "attached_environments")`.

- ...:

  Arguments passed to individual checks.

## Value

Invisibly returns an object of class `sessioncheck_sessioncheck`.

## Details

`sessioncheck()` allows the user to apply multiple session checks in a
single function. The following arguments are recognised via `...`:

- `allow_globalenv_objects` is passed to
  [`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)

- `allow_attached_packages` is passed to
  [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)

- `allow_attached_environments` is passed to
  [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)

- `allow_loaded_namespaces` is passed to
  [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)

- `max_sessiontime` is passed to
  [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md)

- `required_options` is passed to
  [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md)

- `required_locale` is passed to
  [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md)

- `required_sysenv` is passed to
  [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

Other arguments are ignored.

## Examples

``` r
sessioncheck(action = "message")
#> Session check results:
#> - Objects in global environment: [no issues]
#> - Attached packages: sessioncheck
#> - Attached environments: [no issues]
 
```
