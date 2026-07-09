---
name: add-check-function
description: Step-by-step recipe for adding a new check_*() function to the sessioncheck R package. Use when asked to add, create, or implement a new session check.
---

# Adding a New `check_*()` Function

New checks require changes to three files (`internal.R`, `api.R`, and a test file) and one verification step. Follow the steps below in order.

## Step 1 — Add the status checker to `internal.R`

Add a `.get_<name>_status()` function. Choose the parameter type that fits the new check:

- **`allow`** (character vector) — for checks that flag items by name
- **`tol`** (single numeric) — for checks against a threshold
- **`required`** (named list) — for checks that require specific values

```r
# status checkers: <section heading> ------

.get_<name>_status <- function(allow) {  # or tol / required
  if (is.null(allow)) allow <- character(0L)
  # Inspect session state. Return a named logical vector where
  # TRUE means "this item is a problem".
  status <- # ... named logical(n)
  new_status(status, type = "<name>")
}
```

If the new check needs a validator not already in `internal.R` (see existing `.validate_allow()`, `.validate_tol()`, `.validate_required()`), add it to the validators section at the top of `internal.R`.

## Step 2 — Add the public function to `api.R`

Add the exported function at the end of `api.R`. Match the parameter name to the validator type:

| Parameter type | Parameter name pattern | Validator |
|---|---|---|
| allowlist | `allow_<name>` | `.validate_allow()` |
| threshold | `max_<name>` | `.validate_tol()` |
| required values | `required_<name>` | `.validate_required()` |

```r
#' @title Check <description>
#'
#' @description
#' Individual session check function that inspects <what it checks>.
#' Session checkers can produce errors, warnings, or messages if requested.
#'
#' @param action Behavior to take if the status is not clean. Possible values are
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_<name> Character vector containing names of <items> that are
#' "allowed", and will not trigger an action.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`.
#'
#' @examples
#' check_<name>(action = "message")
#'
#' @details
#' <Explain what is checked and what the default behavior is when allow = NULL.>
#'
#' @seealso
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_<name>()]
#'
#' @export
check_<name> <- function(action = "warn", allow_<name> = NULL) {
  .validate_action(action)
  .validate_allow(allow_<name>)        # match to parameter type
  status <- .get_<name>_status(allow_<name>)
  .action(action, status)
}
```

Note: individual `check_*()` functions do **not** call `.parse_args()` — that is only done inside `sessioncheck()`.

## Step 3 — Wire into `sessioncheck()`

In `sessioncheck()` in `api.R`, make three additions:

**3a.** Add a line to the `results` dispatch block:

```r
if ("<name>" %in% args$checks) results$<name> <- .get_<name>_status(args$allow_<name>)
```

**3b.** Add the argument to the `@details` list in the `sessioncheck()` roxygen block:

```r
#' - `allow_<name>` is passed to `check_<name>()`
```

**3c.** If the new check should run by default, add `"<name>"` to the default `checks` vector:

```r
if (is.null(args$checks)) args$checks <- c("globalenv_objects", "attached_packages", "attached_environments", "<name>")
```

Adding a check to the default set is a user-visible change — confirm with the user before doing so.

## Step 4 — Add tests

Add tests to `tests/testthat/test-api.R` (and `test-sessioncheckers.R` for the internal helper if it has non-trivial logic). Use `local_mocked_bindings()` to isolate the test from actual session state. Cover:

- Normal operation when no problems are detected
- Normal operation when a problem is detected
- Each value of `action`: `"error"`, `"warn"`, `"message"`, `"none"`
- The `allow_<name>` argument suppresses flagging of allowed items
- Invalid argument values are rejected by the validator

## Step 5 — Verify

```r
devtools::document()   # regenerates man/ and NAMESPACE from roxygen2
devtools::test()       # all tests must pass
devtools::check()      # must be clean (0 errors, 0 warnings)
```

If snapshot tests fail after an intentional output change, review diffs with `testthat::snapshot_review()` before accepting.
