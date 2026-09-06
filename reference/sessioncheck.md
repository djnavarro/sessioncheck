# Checks the overall status of the R session

`sessioncheck()` is the top-level orchestrator for this package's
individual session checks: it runs one or more `check_*()` functions
(e.g.
[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md))
in a single call and combines their results. Like the individual checks
it wraps, it can produce errors, warnings, or messages if requested.

## Usage

``` r
sessioncheck(action = NULL, checks = NULL, action_on_pass = NULL, ...)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". If the user does not specify
  an action, the default is `action = "warn"`.

- checks:

  Character vector listing the checks to run. If the user does not
  specify the checks, the default is to run
  `checks = c("globalenv_objects", "attached_packages", "attached_environments")`.

- action_on_pass:

  Behavior to take if the status is clean. Possible values are "message"
  and "none". If the user does not specify a value, the default is
  `action_on_pass = "none"`.

- ...:

  Arguments passed to individual checks.

## Value

Invisibly returns an object of class `sessioncheck_sessioncheck`.

## Details

The following arguments are recognized via `...`:

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

- `required_wd` is passed to
  [`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)

Other arguments are ignored.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md),
[`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)

## Examples

``` r
sessioncheck(action = "message")
#> Session check results:
#> ✔ No unexpected objects in global environment
#> ✖ Unexpected packages: sessioncheck
#> ✔ No unexpected environments attached

# a session with nothing flagged by the default checks: `action` only
# controls what happens when a problem *is* found, so pass
# `action_on_pass = "message"` to confirm the clean result instead
sessioncheck(
  action = "none",
  allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
  allow_attached_packages = .packages(),
  allow_attached_environments = search(),
  action_on_pass = "message"
)
#> Session check results:
#> ✔ No unexpected objects in global environment
#> ✔ No unexpected packages attached
#> ✔ No unexpected environments attached
 
```
