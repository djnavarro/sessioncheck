# Check session run time

Individual session check function that inspects the session run time
information. Session checkers can produce errors, warnings, or messages
if requested.

## Usage

``` r
check_sessiontime(action = "warn", max_sessiontime = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- max_sessiontime:

  Maximum session time permitted in seconds before the checker takes
  action

## Value

Invisibly returns an object of class `sessioncheck_status`.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
`check_sessiontime()`,
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_sessiontime(action = "message")
```
