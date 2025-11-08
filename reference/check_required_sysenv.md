# Check required values for system environment variables

Individual session check function that inspects system environment
variables. Session checkers can produce errors, warnings, or messages if
requested.

## Usage

``` r
check_required_sysenv(action = "warn", required_sysenv = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required_sysenv:

  A named list of required system environment variables. If any of these
  variables are missing or have different values to the required values,
  an action is triggered.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
`check_required_sysenv()`

## Examples

``` r
check_required_sysenv(action = "message", required_sysenv = list(R_TEST = "value"))
#> Unexpected system environment variables: R_TEST
```
