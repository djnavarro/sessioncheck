
#' 
#' @title Check aspects to the R session
#' 
#' @description
#' Individual session check functions that each inspect one way in which an R
#' session could be considered not to be "clean". Session checkers can produce
#' errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param ignore Character vector containing names of objects, packages, environment
#' names that will not trigger an action. Some entities will never trigger actions
#' (see details).
#'
#' @returns Invisibly returns a status vector, a logical vector with names referring
#' to a detected entity (e.g., object, package, environment). Values are `TRUE` if 
#' the entity is ignored, `FALSE` if it triggers an action.
#'  
#' @examples
#' check_packages(action = "message")
#' check_namespaces(action = "message")
#' check_globalenv(action = "message")
#' check_attachments(action = "message")
#'  
#' @details
#' The default behaviour of the `ignore` argument is slightly for each checker:
#' 
#' - `check_globalenv()`: This checker inspects the state of the global environment
#' and takes action based on the objects found there. When `ignore = NULL`, variables 
#' in the global environment will be ignored if the name starts with a dot. For 
#' example, `.Random.seed` and `.Last.value` no not trigger actions by default.
#' 
#' - `check_packages()`: This checker inspects the list of packages that have been
#' attached to the search path (e.g., via `library()`). Regardless of the value of 
#' ignore, R packages that have "base" priority (e.g., **base**, **utils**, and 
#' **grDevices**) do not trigger an action. When `ignore = NULL` these are the only
#' packages that are ignored.
#' 
#' - `check_namespaces()`: This checker inspects the list of loaded namespaces (e.g.
#' packages that have been loaded but not attached). The `ignore` argument for this
#' checker is almost identical to `check_packages()`: the only difference is that 
#' the **sessioncheck** package is never flagged, since the namespace must be loaded
#' in order to call the function.
#' 
#' - `check_attachments()`: This checker inspects all environments on the search
#' path. This includes attached packages, anything added using `attach()`, and the
#' global environment. When `ignore = NULL`, package environents do not trigger an
#' action, nor do "tools:rstudio", "tools:positron", or "Autoloads". The global 
#' environment and the package environment for the **base** package never trigger
#' actions.
#' 
#' @name sessionchecks
NULL

#' @export
#' @rdname sessionchecks
check_globalenv <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_globalenv_status(ignore)
  msg  <- .message_text("Found objects:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname sessionchecks
check_packages <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_package_status(ignore)
  msg <- .message_text("Found packages:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname sessionchecks
check_namespaces <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_namespace_status(ignore)
  msg <- .message_text("Found namespaces:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname sessionchecks
check_attachments <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_attachment_status(ignore)
  msg <- .message_text("Found attachments:", status)
  .action(action, status, msg)
}
