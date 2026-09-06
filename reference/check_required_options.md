# Check required values for options

Individual session check function that inspects the options. Session
checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_required_options(action = "warn", required_options = NULL)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required_options:

  A named list of required options. If any of these options are missing
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
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_required_options(action = "message", required_options = list(scipen = 0L, max.print = 50L))
#> ✖ Unexpected options:
#>     max.print: expected 50, got 99999

# a required option that is present, but has a different value: reports
# the expected and actual values
old <- options(scipen = 0L)
check_required_options(action = "message", required_options = list(scipen = 100L))
#> ✖ Unexpected options:
#>     scipen: expected 100, got 0
options(old)

# a required option that is not set at all: reported as missing, rather
# than lumped in with the mismatched-value case above
check_required_options(
  action = "message",
  required_options = list(a_totally_unset_option = TRUE)
)
#> ✖ Unexpected options:
#>     a_totally_unset_option: missing (expected TRUE)

# a long vector value is summarized rather than printed in full
old <- options(scipen = 0L)
check_required_options(action = "message", required_options = list(scipen = 1:5000))
#> ✖ Unexpected options:
#>     scipen: expected c(1, 2, 3, 4, 5, ... [5000 total]), got 0
options(old)

# non-atomic values (e.g. lists) are described by role -- "user-supplied"
# vs. "a different" -- rather than by content, since two unequal lists
# would otherwise both print as the uninformative "<list>"
old <- options(sessioncheck_example = list(a = 1))
check_required_options(
  action = "message",
  required_options = list(sessioncheck_example = list(b = 2))
)
#> ✖ Unexpected options:
#>     sessioncheck_example: expected user-supplied <list>, got a different <list>
options(old)

# a required option matching its current value: a passing check is
# always silent regardless of `action`, so print() the returned status
# directly to see the "no issues" wording
print(check_required_options(action = "none", required_options = list(digits = getOption("digits"))))
#> ✔ No unexpected options detected
```
