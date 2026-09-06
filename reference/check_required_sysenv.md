# Check required values for system environment variables

Individual session check function that inspects system environment
variables. Session checkers can produce errors, warnings, or messages if
requested.

## Usage

``` r
check_required_sysenv(
  action = "warn",
  required_sysenv = NULL,
  action_on_pass = "none"
)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required_sysenv:

  A named list of required system environment variables. If any of these
  variables are missing or have different values to the required values,
  an action is triggered. The default is `required_sysenv = NULL`, which
  means there is nothing to compare against, so the check always passes.

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
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)

## Examples

``` r
check_required_sysenv(action = "message", required_sysenv = list(R_TEST = "value"))
#> ✖ Unexpected system environment variables:
#>     R_TEST: missing (expected value)

# a required variable that is present, but has a different value: reports
# the expected and actual values (R_HOME is set by R itself, so this is
# reliably a mismatch rather than a missing variable)
check_required_sysenv(action = "message", required_sysenv = list(R_HOME = "not-the-real-path"))
#> ✖ Unexpected system environment variables:
#>     R_HOME: expected not-the-real-path, got /opt/R/4.6.1/lib/R

# a required variable that is not set at all: reported as missing,
# rather than lumped in with the mismatched-value case above
check_required_sysenv(
  action = "message",
  required_sysenv = list(SESSIONCHECK_EXAMPLE_UNSET_VAR = "value")
)
#> ✖ Unexpected system environment variables:
#>     SESSIONCHECK_EXAMPLE_UNSET_VAR: missing (expected value)

# a required variable matching its current value: `action` only
# controls what happens when a problem *is* found, so use
# `action_on_pass = "message"` to confirm the clean result instead
check_required_sysenv(
  action = "none",
  required_sysenv = list(R_HOME = Sys.getenv("R_HOME")),
  action_on_pass = "message"
)
#> ✔ No unexpected system environment variables detected
```
