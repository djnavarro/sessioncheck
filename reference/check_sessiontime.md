# Check session run time

Individual session check function that inspects the session run time
information. Session checkers can produce errors, warnings, or messages
if requested.

## Usage

``` r
check_sessiontime(
  action = "warn",
  max_sessiontime = NULL,
  action_on_pass = "none"
)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- max_sessiontime:

  Maximum session time permitted in seconds before the checker takes
  action. The default is `max_sessiontime = 300`.

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
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md),
[`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)

## Examples

``` r
check_sessiontime(action = "message")

# a session that has run past the threshold: reports the elapsed time
# and the threshold together, both in human-readable units
check_sessiontime(action = "message", max_sessiontime = 0)
#> ✖ Session runtime (7.33 secs) exceeds threshold of 0 secs

# a session comfortably within the threshold: `action` only controls
# what happens when a problem *is* found, so use
# `action_on_pass = "message"` to confirm the clean result instead
check_sessiontime(action = "none", max_sessiontime = Inf, action_on_pass = "message")
#> ✔ Session runtime (7.33 secs) below threshold of Inf days
```
