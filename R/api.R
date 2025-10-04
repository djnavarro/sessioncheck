
#' Check if an environment is clean
#'
#' @param action Behaviour to take if environment is not clean. Possible values 
#' are "error", "warn", "message", and "none".
#' @param ignore Character vector containing names of variables that will not 
#' trigger an action. If NULL, variables that start with a dot are ignored.
#' @param envir Environment to be checked.
#'
#' @returns Invisibly returns a logical vector with names corresponding to 
#' object names in the environment. Values are TRUE if the object is ignored, 
#' FALSE if not
#' @export
#' @examples
#' check_environment(action = "message")
#'  
check_environment <- function(action = "warn", ignore = NULL, envir = .GlobalEnv) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_environment_status(envir, ignore)
  msg  <- .message_text("Found variables:", status)
  .action(action, status, msg)
}

#' Check if package/namespace status is clean
#'
#' @param action Behaviour to take if package/namespace status is not clean. 
#' Possible values are "error", "warn", "message", and "none".
#' @param ignore Character vector containing names of non-base packages that 
#' will not trigger an action. If NULL, only the base packages and sessioncheck 
#' itself are permitted.
#'
#' @returns Invisibly returns a logical vector with names corresponding to 
#' loaded namespaces for `check_namespaces()`, or names of attached packages
#' for `check_packages()`. Values are TRUE if the package is ignored, FALSE if not.
#' 
#' @examples
#' check_packages(action = "message")
#' check_namespaces(action = "message")
#'  
#' @name check_packages
#' @aliases check_namespaces
NULL

#' @export
#' @rdname check_packages
check_packages <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_package_status(ignore)
  msg <- .message_text("Found attached packages:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname check_packages
check_namespaces <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_namespace_status(ignore)
  msg <- .message_text("Found loaded namespaces:", status)
  .action(action, status, msg)
}

#' Check the search path for non-standard attachments
#'
#' @param action Behaviour to take if package/namespace status is not clean. 
#' Possible values are "error", "warn", "message", and "none".
#' @param ignore Character vector containing names of attached environments that 
#' will not trigger an action. The global environment never triggers an action.
#' If `ignore=NULL` the following environment names are ignored: "tools:rstudio",
#' "tools:positron", "Autoloads"
#'
#' @returns Invisibly returns a logical vector with names correspond to the searched
#' environments as returned by `search()`. Values are always set to `TRUE` for package
#' environments and the global environment. For all other environments, the values 
#' are `FALSE` unless the environment belongs to the `ignore` list. 
#' 
#' @export
#' 
#' @examples
#' check_attachments(action = "message")
check_attachments <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_attachment_status(ignore)
  msg <- .message_text("Found attached environments:", status)
  .action(action, status, msg)
}
