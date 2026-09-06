# Check environments attached to the search path

Individual session check function that inspects the names of attached
non-package environments. Session checkers can produce errors, warnings,
or messages if requested.

## Usage

``` r
check_attached_environments(
  action = "warn",
  allow_attached_environments = NULL,
  action_on_pass = "none"
)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- allow_attached_environments:

  Character vector containing names of environments that are "allowed",
  and will not trigger an action if attached to the search path. The
  default is `allow_attached_environments = NULL`, in which case package
  environments and a set of known IDE-injected environments (e.g.
  "tools:rstudio") are allowed.

- action_on_pass:

  Behavior to take if the status is clean. Possible values are "message"
  and "none". The default is `action_on_pass = "none"`.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## Details

This checker inspects all environments on the search path. This includes
attached packages, anything added using
[`attach()`](https://rdrr.io/r/base/attach.html), and the global
environment. When `allow_attached_environments = NULL`, package
environments do not trigger an action, nor do "tools:rstudio",
"tools:positron", "tools:callr", or "Autoloads". The global environment
and the package environment for the **base** package never trigger
actions.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md),
[`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)

## Examples

``` r
check_attached_environments(action = "message")

# a session with no unexpected environments attached: `action` only
# controls what happens when a problem *is* found, so use
# `action_on_pass = "message"` to confirm the clean result instead
check_attached_environments(
  action = "none",
  allow_attached_environments = search(),
  action_on_pass = "message"
)
#> ✔ No unexpected environments attached
 
```
