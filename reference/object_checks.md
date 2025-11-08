# Check global environment and attached environments

Individual session check functions that inspect the contents of the
global environment and the names of attached non-package environments.
Session checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_globalenv(action = "warn", allow = NULL)

check_attachments(action = "warn", allow = NULL)
```

## Arguments

- action:

  Behaviour to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- allow:

  Character vector containing names of objects or environments that are
  "allowed", and will not trigger an action.

## Value

Invisibly returns a status flag vector, a logical vector with names
referring to a detected entity (object in the global environment, or a
non-package environment attached to the search path). Values are `TRUE`
if the entity triggers an action, `FALSE` if it does not.

## Details

The default behaviour of the `allow` argument is slightly for each
checker:

- `check_globalenv()`: This checker inspects the state of the global
  environment and takes action based on the objects found there. When
  `allow = NULL`, variables in the global environment will not trigger
  an action if the name starts with a dot. For example, `.Random.seed`
  and `.Last.value` do not trigger actions by default.

- `check_attachments()`: This checker inspects all environments on the
  search path. This includes attached packages, anything added using
  [`attach()`](https://rdrr.io/r/base/attach.html), and the global
  environment. When `allow = NULL`, package environents do not trigger
  an action, nor do "tools:rstudio", "tools:positron", "tools:callr", or
  "Autoloads". The global environment and the package environment for
  the **base** package never trigger actions.

## Examples

``` r
check_globalenv(action = "message")
check_attachments(action = "message")
 
```
