# Check required values for locale settings

Individual session check function that inspects the locale settings.
Session checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_required_locale(
  action = "warn",
  required_locale = NULL,
  action_on_pass = "none"
)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required_locale:

  A named list of required locale settings. If any of these are missing
  or have different values to the required values, an action is
  triggered. The default is `required_locale = NULL`, which means there
  is nothing to compare against, so the check always passes.

- action_on_pass:

  Behavior to take if the status is clean. Possible values are "message"
  and "none". The default is `action_on_pass = "none"`.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md),
[`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)

## Examples

``` r
check_required_locale(action = "message", required_locale = list(LC_TIME = "en_US.UTF-8"))
#> ✖ Unexpected locale settings:
#>     LC_TIME: expected en_US.UTF-8, got C.UTF-8

# a required locale setting that is present, but has a different value:
# reports the expected and actual values
check_required_locale(action = "message", required_locale = list(LC_CTYPE = "not-a-real-locale"))
#> ✖ Unexpected locale settings:
#>     LC_CTYPE: expected not-a-real-locale, got C.UTF-8

# a required locale setting that isn't part of the current locale at
# all: reported as missing, rather than lumped in with the
# mismatched-value case above
check_required_locale(action = "message", required_locale = list(LC_MADEUP = "en_US.UTF-8"))
#> ✖ Unexpected locale settings:
#>     LC_MADEUP: missing (expected en_US.UTF-8)

# a required locale setting matching its current value: `action` only
# controls what happens when a problem *is* found, so use
# `action_on_pass = "message"` to confirm the clean result instead
check_required_locale(
  action = "none",
  required_locale = list(LC_COLLATE = Sys.getlocale("LC_COLLATE")),
  action_on_pass = "message"
)
#> ✔ No unexpected locale settings detected
```
