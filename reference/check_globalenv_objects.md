# Check global environment objects

Individual session check functions that inspect the contents of the
global environment and the names of attached non-package environments.
Session checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_globalenv_objects(action = "warn", allow_globalenv_objects = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- allow_globalenv_objects:

  Character vector containing names of objects that are "allowed", and
  will not trigger an action.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## Details

This checker inspects the state of the global environment and takes
action based on the objects found there. When
`allow_globalenv_objects = NULL`, variables in the global environment
will not trigger an action if the name starts with a dot. For example,
`.Random.seed` and `.Last.value` do not trigger actions by default.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md),
`check_globalenv_objects()`,
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_globalenv_objects(action = "message")
 
```
