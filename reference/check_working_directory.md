# Check the working directory

Individual session check function that inspects the current working
directory. Session checkers can produce errors, warnings, or messages if
requested.

## Usage

``` r
check_working_directory(
  action = "warn",
  required_wd = NULL,
  action_on_pass = "none"
)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- required_wd:

  A single character path giving the working directory the session is
  expected to be in. If any other directory is currently in use, an
  action is triggered. The default is `required_wd = NULL`, which means
  there is nothing to compare against, so the check always passes.

- action_on_pass:

  Behavior to take if the status is clean. Possible values are "message"
  and "none". The default is `action_on_pass = "none"`.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## Details

This checker compares the current working directory
([`getwd()`](https://rdrr.io/r/base/getwd.html)) against `required_wd`.
Both paths are passed through
[`normalizePath()`](https://rdrr.io/r/base/normalizePath.html) before
comparison, so differences in trailing slashes or relative vs. absolute
form do not trigger a false positive. When `required_wd = NULL` (the
default), there is nothing to compare against, so the check always
passes; the current working directory is still reported in the message.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_working_directory(action = "message")

# a working directory that does not match the required path: reports both
# the actual and required paths
check_working_directory(action = "message", required_wd = tempdir())
#> ✖ Working directory (/home/runner/work/sessioncheck/sessioncheck/docs/reference) does not match required path (/tmp/RtmpCFtUAe)

# a working directory matching the required path: `action` only controls
# what happens when a problem *is* found, so use
# `action_on_pass = "message"` to confirm the clean result instead
check_working_directory(
  action = "none",
  required_wd = getwd(),
  action_on_pass = "message"
)
#> ✔ Working directory matches required path (/home/runner/work/sessioncheck/sessioncheck/docs/reference)
 
```
