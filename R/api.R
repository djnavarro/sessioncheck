
#' @title Checks the overall status of the R session
#' 
#' @description
#' Individual session check functions that each inspect one way in which an R
#' session could be considered not to be "clean". Session checkers can produce
#' errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param checks Character vector listing the checks to run. The default is to run
#' `checks = c("globalenv_objects", "attached_packages", "attached_environments")`
#' @param ... Arguments passed to individual checks
#'
#' @returns Invisibly returns a status object, a list of a named logical vectors. Each vector
#' has names that refer to detected entities for each specific check. Values are `TRUE` if 
#' that entity triggers an action, `FALSE` if it does not.
#'  
#' @examples
#' sessioncheck(action = "message")
#'  
#' @details
#' `sessioncheck()` allows the user to apply multiple session checks in a single function. 
#' The following arguments are recognised via `...`:
#' 
#' - `allow_globalenv_objects` is passed to `check_globalenv_objects()`
#' - `allow_attached_packages` is passed to `check_attached_packages()`
#' - `allow_attached_environments` is passed to `check_attached_environments()`
#' - `allow_loaded_namespaces` is passed to `check_loaded_namespaces()`
#' - `max_sessiontime` is passed to `check_sessiontime()`
#' - `required_options` is passed to `check_required_options()`
#' - `required_locale` is passed to `check_required_locale()`
#' - `required_sysenv` is passed to `check_required_sysenv()`
#' 
#' Other arguments are ignored.
#' @export
sessioncheck <- function(
  action = "warn", 
  checks = c("globalenv_objects", "attached_packages", "attached_environments"),
  ...
) {
  .validate_action(action)
  settings <- list(...)
  results <- list()
  if ("globalenv_objects" %in% checks) results$globalenv <- .get_globalenv_status(settings$allow_globalenv_objects)
  if ("attached_packages" %in% checks) results$packages <- .get_package_status(settings$allow_attached_packages)
  if ("loaded_namespaces" %in% checks) results$namespaces <- .get_namespace_status(settings$allow_loaded_namespaces)
  if ("attached_environments" %in% checks) results$attachments <- .get_attachment_status(settings$allow_attached_environments)
  if ("sessiontime" %in% checks) results$sessiontime <- .get_sessiontime_status(settings$max_sessiontime)
  if ("required_options" %in% checks) results$options <- .get_sessiontime_status(settings$required_options)
  if ("required_locale" %in% checks) results$options <- .get_sessiontime_status(settings$required_locale)
  if ("required_sysenv" %in% checks) results$options <- .get_sessiontime_status(settings$required_sysenv) 
  .action(action, do.call(new_sessioncheck, args = results))
}

#' @title Check attached packages
#' 
#' @description
#' Individual session check function that inspects the attached packages. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_attached_packages Character vector containing names of packages that 
#' are "allowed", and will not trigger an action if attached to the search path.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_attached_packages(action = "message")
#'  
#' @details
#' This checker inspects the list of packages that have been
#' attached to the search path (e.g., via `library()`). Regardless of the value of 
#' `allow`, R packages that have "base" priority (e.g., **base**, **utils**, and 
#' **grDevices**) do not trigger an action. When `allow = NULL` these are the only
#' packages that will not trigger actions. 
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_attached_packages <- function(action = "warn", allow_attached_packages = NULL) {
  .validate_action(action)
  .validate_allow(allow_attached_packages)
  status <- .get_package_status(allow_attached_packages)
  .action(action, status)
}


#' @title Check loaded namespaces
#' 
#' @description
#' Individual session check function that inspects the loaded namespaces. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_loaded_namespaces Character vector containing names of packages that 
#' are "allowed", and will not trigger an action if loaded via namespace.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_loaded_namespaces(action = "message")
#'  
#' @details
# 'This checker inspects the list of loaded namespaces 
#' (packages that have been loaded but not attached). Regardless of the value of 
#' `allow_loaded_namespaces`, R packages that have "base" priority (e.g., **base**, **utils**, and 
#' **grDevices**) do not trigger an action, nor does the **sessioncheck** package itself,
#' since the package namespace must be loaded in order to call the function.
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_loaded_namespaces <- function(action = "warn", allow_loaded_namespaces = NULL) {
  .validate_action(action)
  .validate_allow(allow_loaded_namespaces)
  status <- .get_namespace_status(allow_loaded_namespaces)
  .action(action, status)
}

#' @title Check global environment objects
#' 
#' @description
#' Individual session check functions that inspect the contents of the global 
#' environment and the names of attached non-package environments. Session checkers 
#' can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_globalenv_objects Character vector containing names of objects
#' that are "allowed", and will not trigger an action.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_globalenv_objects(action = "message")
#'  
#' @details
#' This checker inspects the state of the global environment and takes action based 
#' on the objects found there. When `allow_globalenv_objects = NULL`, variables 
#' in the global environment will not trigger an action if the name starts with a dot. 
#' For example, `.Random.seed` and `.Last.value` do not trigger actions by default.
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_globalenv_objects <- function(action = "warn", allow_globalenv_objects = NULL) {
  .validate_action(action)
  .validate_allow(allow_globalenv_objects)
  status <- .get_globalenv_status(allow_globalenv_objects)
  .action(action, status)
}

#' @title Check environments attached to the search path
#' 
#' @description
#' Individual session check function that inspects the names of attached non-package 
#' environments. Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_attached_environments Character vector containing names of environments
#' that are "allowed", and will not trigger an action if attached to the search path.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_attached_environments(action = "message")
#'  
#' @details
#' This checker inspects all environments on the search path. This includes attached 
#' packages, anything added using `attach()`, and the global environment. When 
#' `allow_attached_environments = NULL`, package environents do not trigger an
#' action, nor do "tools:rstudio", "tools:positron", "tools:callr", or "Autoloads". 
#' The global environment and the package environment for the **base** package 
#' never trigger actions.
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_attached_environments <- function(action = "warn", allow_attached_environments = NULL) {
  .validate_action(action)
  .validate_allow(allow_attached_environments)
  status <- .get_attachment_status(allow_attached_environments)
  .action(action, status)
}

#' @title Check session run time
#' 
#' @description
#' Individual session check function that inspects the session run time information. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param max_sessiontime Maximum session time permitted in seconds before the checker 
#' takes action
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_sessiontime(action = "message")
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_sessiontime <- function(action = "warn", max_sessiontime = NULL) {
  .validate_action(action)
  .validate_tol(max_sessiontime)
  status <- .get_sessiontime_status(max_sessiontime)
  .action(action, status)
}

#' @title Check required values for options
#' 
#' @description
#' Individual session check function that inspects the options. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_options A named list of required options. If any of these options are 
#' missing or have different values to the required values, an action is triggered.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_options(action = "message", required_options = list(scipen = 0L, max.print = 50L))
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_required_options <- function(action = "warn", required_options = NULL) {
  .validate_action(action)
  .validate_required(required_options)
  status <- .get_options_status(required_options)
  .action(action, status)
}

#' @title Check required values for locale settings
#' 
#' @description
#' Individual session check function that inspects the locale settings. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_locale A named list of required locale settings. If any of these 
#' are missing or have different values to the required values, an action is triggered.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_locale(action = "message", required = list(LC_TIME = "en_US.UTF-8"))
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_required_locale <- function(action = "warn", required_locale = NULL) {
  .validate_action(action)
  .validate_required(required_locale)
  status <- .get_locale_status(required_locale)
  .action(action, status)
}

#' @title Check required values for system environment variables
#' 
#' @description
#' Individual session check function that inspects system environment variables. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behaviour to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_sysenv A named list of required system environment variables. 
#' If any of these variables are missing or have different values to the required 
#' values, an action is triggered.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_sysenv(action = "message", required_sysenv = list(R_TEST = "value"))
#' 
#' @seealso 
#' [check_attached_packages()], 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()]
#' 
#' @export
check_required_sysenv <- function(action = "warn", required_sysenv = NULL) {
  .validate_action(action)
  .validate_required(required_sysenv)
  status <- .get_sysenv_status(required_sysenv)
  .action(action, status)
}
