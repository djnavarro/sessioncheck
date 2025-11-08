# Check required values for locale settings

Individual session check function that inspects the locale settings.
Session checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_required_locale(action = "warn", required_locale = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required_locale:

  A named list of required locale settings. If any of these are missing
  or have different values to the required values, an action is
  triggered.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
`check_required_locale()`,
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_required_locale(action = "message", required = list(LC_TIME = "en_US.UTF-8"))
#> Unexpected locale setttings: LC_TIME
```
