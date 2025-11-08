# Check attached packages

Individual session check function that inspects the attached packages.
Session checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_attached_packages(action = "warn", allow_attached_packages = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- allow_attached_packages:

  Character vector containing names of packages that are "allowed", and
  will not trigger an action if attached to the search path.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## Details

This checker inspects the list of packages that have been attached to
the search path (e.g., via
[`library()`](https://rdrr.io/r/base/library.html)). Regardless of the
value of `allow`, R packages that have "base" priority (e.g., **base**,
**utils**, and **grDevices**) do not trigger an action. When
`allow = NULL` these are the only packages that will not trigger
actions.

## See also

`check_attached_packages()`,
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_attached_packages(action = "message")
#> Attached packages: sessioncheck
 
```
