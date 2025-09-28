
#' Check if an environment is clean
#'
#' @param action Behaviour to take if environment is not clean. Possible values 
#' are "error", "warn", and "message".
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

#' Check if list of loaded packages is clean
#'
#' @param action Behaviour to take if environment is not clean. Possible values
#' are "error", "warn", and "message".
#' @param ignore Character vector containing names of non-base packages that 
#' will not trigger an action. If NULL, only the base packages and sessioncheck 
#' itself are permitted.
#'
#' @returns Invisibly returns a logical vector with names corresponding to 
#' loaded namespaces. Values are TRUE if the package is ignored, FALSE if not.
#' @export
#' @examples
#' check_packages(action = "message")
#'  
check_packages <- function(action = "warn", ignore = NULL) {
  .validate_action(action)
  .validate_ignore(ignore)
  status <- .get_package_status(ignore)
  msg <- .message_text("Found loaded packages:", status)
  .action(action, status, msg)
}

