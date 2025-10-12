

#' @title Checks the overall status of the R session
#' 
#' @description
#' Individual session check functions that each inspect one way in which an R
#' session could be considered not to be "clean". Session checkers can produce
#' errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param checks Character vector listing the checks to run. The
#' default is to run `checks = c("globalenv", "packages", "attachments")`
#' @param settings A list specifying the rules applied for individual checks
#'
#' @returns Invisibly returns a status object, a list of a named logical vectors. Each vector
#' has names that refer to detected entities for each specific check. Values are `TRUE` if 
#' that entity triggers an action, `FALSE` if it does not.
#'  
#' @examples
#' sessioncheck(action = "message")
#'  
#' @details
#' `sessioncheck()` allows the user to apply multiple session checks in a single function
#' 
#' @export
#' 
sessioncheck <- function(
  action = "warn", 
  checks = c("globalenv", "packages", "attachments"),
  settings = getOption("sessioncheck.settings")
) {
  .validate_action(action)
  .validate_settings(settings)

  check_globalenv   <- "globalenv" %in% checks
  check_packages    <- "packages" %in% checks
  check_namespaces  <- "namespaces" %in% checks
  check_attachments <- "attachments" %in% checks
  check_sessiontime <- "sessiontime" %in% checks

  status <- list()
  if (check_globalenv)   status$globalenv   <- .get_globalenv_status(settings$globalenv)
  if (check_packages)    status$packages    <- .get_package_status(settings$packages)
  if (check_namespaces)  status$namespaces  <- .get_namespace_status(settings$namespaces)
  if (check_attachments) status$attachments <- .get_attachment_status(settings$attachment)
  if (check_sessiontime) status$sessiontime <- .get_sessiontime_status(settings$sessiontime)

  msg <- list()
  if (check_globalenv)   msg$globalenv   <- .message_text("- Objects in global environment:", status$globalenv)
  if (check_packages)    msg$packages    <- .message_text("- Attached packages:", status$packages)
  if (check_namespaces)  msg$namespaces  <- .message_text("- Loaded namespaces:", status$namespaces)
  if (check_attachments) msg$attachments <- .message_text("- Attached non-package environments:", status$attachments)
  if (check_sessiontime) msg$sessiontime <- .message_text("- Session runtime:", status$sessiontime)
  
  if (length(msg) > 0L) {
    msg <- paste(unlist(msg), collapse = "\n")
    msg <- paste("sessioncheck() detected the following issues:", msg, sep = "\n")
    if (action == "error") {
      msg <- paste(msg, "It may be necessary to restart R", sep = "\n")
    }
  }

  .action(action, status, msg)
}


#' @title Check loaded namespaces and attached packages
#' 
#' @description
#' Individual session check functions that examine attached packages and loaded
#' namespaces. Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow Character vector containing names of packages that are "allowed", 
#' and will not trigger an action. Base priority packages are always allowed and will 
#' never trigger actions (see details).
#'
#' @returns Invisibly returns a status flag vector, a logical vector with names referring
#' to a detected package. Values are `TRUE` if the package triggers an action, `FALSE` 
#' if it does not.
#'  
#' @examples
#' check_packages(action = "message")
#' check_namespaces(action = "message")
#'  
#' @details
#' The default behaviour of the `allow` argument is slightly for each checker:
#' 
#' - `check_packages()`: This checker inspects the list of packages that have been
#' attached to the search path (e.g., via `library()`). Regardless of the value of 
#' `allow`, R packages that have "base" priority (e.g., **base**, **utils**, and 
#' **grDevices**) do not trigger an action. When `allow = NULL` these are the only
#' packages that will not trigger actions. 
#' 
#' - `check_namespaces()`: This checker inspects the list of loaded namespaces 
#' (packages that have been loaded but not attached). The `allow` argument for this
#' checker is almost identical to `check_packages()`: the only difference is that 
#' the **sessioncheck** package is always allowed as a loaded namespace, since the 
#' package namespace must be loaded in order to call the function itself.
#' 
#' @name package_checks
NULL

#' @export
#' @rdname package_checks
check_packages <- function(action = "warn", allow = NULL) {
  .validate_action(action)
  .validate_allow(allow)
  status <- .get_package_status(allow)
  msg <- .message_text("Detected attached packages:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname package_checks
check_namespaces <- function(action = "warn", allow = NULL) {
  .validate_action(action)
  .validate_allow(allow)
  status <- .get_namespace_status(allow)
  msg <- .message_text("Dectected loaded namespaces:", status)
  .action(action, status, msg)
}

#' @title Check global environment and attached environments
#' 
#' @description
#' Individual session check functions that inspect the contents of the global 
#' environment and the names of attached non-package environments. Session checkers 
#' can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow Character vector containing names of objects or environments
#' that are "allowed", and will not trigger an action.
#'
#' @returns Invisibly returns a status flag vector, a logical vector with names 
#' referring to a detected entity (object in the global environment, or a non-package
#' environment attached to the search path). Values are `TRUE` if the entity triggers 
#' an action, `FALSE` if it does not.
#'  
#' @examples
#' check_globalenv(action = "message")
#' check_attachments(action = "message")
#'  
#' @details
#' The default behaviour of the `allow` argument is slightly for each checker:
#' 
#' - `check_globalenv()`: This checker inspects the state of the global environment
#' and takes action based on the objects found there. When `allow = NULL`, variables 
#' in the global environment will not trigger an action if the name starts with a dot. 
#' For example, `.Random.seed` and `.Last.value` do not trigger actions by default.
#'  
#' - `check_attachments()`: This checker inspects all environments on the search
#' path. This includes attached packages, anything added using `attach()`, and the
#' global environment. When `allow = NULL`, package environents do not trigger an
#' action, nor do "tools:rstudio", "tools:positron", "tools:callr", or "Autoloads". 
#' The global environment and the package environment for the **base** package 
#' never trigger actions.
#' 
#' @name object_checks
NULL

#' @export
#' @rdname object_checks
check_globalenv <- function(action = "warn", allow = NULL) {
  .validate_action(action)
  .validate_allow(allow)
  status <- .get_globalenv_status(allow)
  msg  <- .message_text("Detected objects:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname object_checks
check_attachments <- function(action = "warn", allow = NULL) {
  .validate_action(action)
  .validate_allow(allow)
  status <- .get_attachment_status(allow)
  msg <- .message_text("Detected attached environments:", status)
  .action(action, status, msg)
}



#' @title Check session run time
#' 
#' @description
#' Individual session check functions that inspect the session run time information. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param tol Maximum session time permitted in seconds before the checker takes action
#'
#' @returns Invisibly returns a status flag: `TRUE` if the elapsed run time for the 
#' current session exceeds the tolerance, `FALSE` if it does not.
#'  
#' @examples
#' check_sessiontime(action = "message")
#' 
#' @name sessiontime_checks
NULL

#' @export
#' @rdname sessiontime_checks
check_sessiontime <- function(action = "warn", tol = NULL) {
  .validate_action(action)
  .validate_tol(tol)
  status <- .get_sessiontime_status(tol)
  msg <- .message_text("Session runtime:", status)
  .action(action, status, msg)
}

#' @title Check required values for options, locale, and environment
#' 
#' @description
#' Individual session check functions that inspect the session options, locale, 
#' or system environment variables. Session checkers can produce errors, warnings, 
#' or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required A named list of required options, locale settings, or environment
#' variables. If any of these values are missing, or have different values, an
#' action is triggered.
#'
#' @returns Invisibly returns a status flag vector, a logical vector with names 
#' that match those in `required`. If the session value matches the required 
#' value, no action is triggered and the status flag is `FALSE`. For mismatches
#' or absent values, the flag is `TRUE`.
#'  
#' @examples
#' check_options(action = "message", required = list(scipen = 0L, max.print = 50L))
#' 
#' @name value_checks
NULL

#' @export
#' @rdname value_checks
check_options <- function(action = "warn", required = NULL) {
  .validate_action(action)
  #.validate_require(required)
  status <- .get_options_status(required)
  msg <- .message_text("Option mismatches:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname value_checks
check_sysenv <- function(action = "warn", required = NULL) {
  .validate_action(action)
  #.validate_require(required)
  status <- .get_sysenv_status(required)
  msg <- .message_text("Environment variable mismatches:", status)
  .action(action, status, msg)
}

#' @export
#' @rdname value_checks
check_locale <- function(action = "warn", required = NULL) {
  .validate_action(action)
  #.validate_require(required)
  status <- .get_locale_status(required)
  msg <- .message_text("Locale mismatches:", status)
  .action(action, status, msg)
}
