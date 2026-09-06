
#' @title Checks the overall status of the R session
#' 
#' @description
#' Individual session check functions that each inspect one way in which an R
#' session could be considered not to be "clean". Session checkers can produce
#' errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". If the user does not specify an action 
#' the default to set `action = "warn"`.
#' @param checks Character vector listing the checks to run. If the user does not 
#' specify the checks, the default is to run
#' `checks = c("globalenv_objects", "attached_packages", "attached_environments")`.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". If the user does not specify a value, the default
#' is `action_on_pass = "none"`.
#' @param ... Arguments passed to individual checks.
#'
#' @returns Invisibly returns an object of class `sessioncheck_sessioncheck`.
#'  
#' @examples
#' sessioncheck(action = "message")
#' 
#' # a session with nothing flagged by the default checks: `action` only
#' # controls what happens when a problem *is* found, so pass
#' # `action_on_pass = "message"` to confirm the clean result instead
#' sessioncheck(
#'   action = "none",
#'   allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
#'   allow_attached_packages = .packages(),
#'   allow_attached_environments = search(),
#'   action_on_pass = "message"
#' )
#'  
#' @details
#' `sessioncheck()` allows the user to apply multiple session checks in a single function. 
#' The following arguments are recognized via `...`:
#' 
#' - `allow_globalenv_objects` is passed to `check_globalenv_objects()`
#' - `allow_attached_packages` is passed to `check_attached_packages()`
#' - `allow_attached_environments` is passed to `check_attached_environments()`
#' - `allow_loaded_namespaces` is passed to `check_loaded_namespaces()`
#' - `max_sessiontime` is passed to `check_sessiontime()`
#' - `required_options` is passed to `check_required_options()`
#' - `required_locale` is passed to `check_required_locale()`
#' - `required_sysenv` is passed to `check_required_sysenv()`
#' - `required_wd` is passed to `check_working_directory()`
#' 
#' Other arguments are ignored.
#' @export
sessioncheck <- function(
  action = NULL, 
  checks = NULL,
  action_on_pass = NULL,
  ...
) {
  args <- .parse_args(action = action, checks = checks, action_on_pass = action_on_pass, ...)
  .validate_action(args$action, allow_null = TRUE)
  .validate_action_on_pass(args$action_on_pass, allow_null = TRUE)
  .validate_checks(args$checks)
  if (is.null(args$action)) args$action <- "warn"
  if (is.null(args$action_on_pass)) args$action_on_pass <- "none"
  if (is.null(args$checks)) args$checks <- c("globalenv_objects", "attached_packages", "attached_environments")

  results <- list()
  if ("globalenv_objects" %in% args$checks) results$globalenv <- .get_globalenv_status(args$allow_globalenv_objects)
  if ("attached_packages" %in% args$checks) results$packages <- .get_package_status(args$allow_attached_packages)
  if ("loaded_namespaces" %in% args$checks) results$namespaces <- .get_namespace_status(args$allow_loaded_namespaces)
  if ("attached_environments" %in% args$checks) results$attachments <- .get_attachment_status(args$allow_attached_environments)
  if ("sessiontime" %in% args$checks) results$sessiontime <- .get_sessiontime_status(args$max_sessiontime)
  if ("required_options" %in% args$checks) results$options <- .get_options_status(args$required_options)
  if ("required_locale" %in% args$checks) results$locale <- .get_locale_status(args$required_locale)
  if ("required_sysenv" %in% args$checks) results$sysenv <- .get_sysenv_status(args$required_sysenv) 
  if ("working_directory" %in% args$checks) results$working_directory <- .get_working_directory_status(args$required_wd)
  .action(args$action, do.call(new_sessioncheck, results), action_on_pass = args$action_on_pass)
}

#' @title Check attached packages
#' 
#' @description
#' Individual session check function that inspects the attached packages. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_attached_packages Character vector containing names of packages that 
#' are "allowed", and will not trigger an action if attached to the search path.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_attached_packages(action = "message")
#' 
#' # a session with no unexpected packages attached: `action` only controls
#' # what happens when a problem *is* found, so use `action_on_pass = "message"`
#' # to confirm the clean result instead
#' check_attached_packages(
#'   action = "none",
#'   allow_attached_packages = .packages(),
#'   action_on_pass = "message"
#' )
#'  
#' @details
#' This checker inspects the list of packages that have been
#' attached to the search path (e.g., via `library()`). Regardless of the value of 
#' `allow_attached_packages`, R packages that have "base" priority (e.g., **base**, **utils**, and 
#' **grDevices**) do not trigger an action. When `allow_attached_packages = NULL` these are the only
#' packages that will not trigger actions. 
#' 
#' @seealso 
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_attached_packages <- function(action = "warn", allow_attached_packages = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_allow(allow_attached_packages)
  status <- .get_package_status(allow_attached_packages)
  .action(action, status, action_on_pass = action_on_pass)
}


#' @title Check loaded namespaces
#' 
#' @description
#' Individual session check function that inspects the loaded namespaces. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_loaded_namespaces Character vector containing names of packages that 
#' are "allowed", and will not trigger an action if loaded via namespace.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_loaded_namespaces(action = "message")
#' 
#' # a session with no unexpected namespaces loaded: `action` only controls
#' # what happens when a problem *is* found, so use `action_on_pass = "message"`
#' # to confirm the clean result instead
#' check_loaded_namespaces(
#'   action = "none",
#'   allow_loaded_namespaces = loadedNamespaces(),
#'   action_on_pass = "message"
#' )
#'  
#' @details
#' This checker inspects the list of loaded namespaces 
#' (packages that have been loaded but not attached). Regardless of the value of 
#' `allow_loaded_namespaces`, R packages that have "base" priority (e.g., **base**, **utils**, and 
#' **grDevices**) do not trigger an action, nor does the **sessioncheck** package itself,
#' since the package namespace must be loaded in order to call the function.
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_loaded_namespaces <- function(action = "warn", allow_loaded_namespaces = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_allow(allow_loaded_namespaces)
  status <- .get_namespace_status(allow_loaded_namespaces)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check global environment objects
#' 
#' @description
#' Individual session check functions that inspect the contents of the global 
#' environment and the names of attached non-package environments. Session checkers 
#' can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_globalenv_objects Character vector containing names of objects
#' that are "allowed", and will not trigger an action.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_globalenv_objects(action = "message")
#' 
#' # a session with no unexpected objects in the global environment:
#' # `action` only controls what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_globalenv_objects(
#'   action = "none",
#'   allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
#'   action_on_pass = "message"
#' )
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
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_globalenv_objects <- function(action = "warn", allow_globalenv_objects = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_allow(allow_globalenv_objects)
  status <- .get_globalenv_status(allow_globalenv_objects)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check environments attached to the search path
#' 
#' @description
#' Individual session check function that inspects the names of attached non-package 
#' environments. Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param allow_attached_environments Character vector containing names of environments
#' that are "allowed", and will not trigger an action if attached to the search path.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_attached_environments(action = "message")
#' 
#' # a session with no unexpected environments attached: `action` only
#' # controls what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_attached_environments(
#'   action = "none",
#'   allow_attached_environments = search(),
#'   action_on_pass = "message"
#' )
#'  
#' @details
#' This checker inspects all environments on the search path. This includes attached 
#' packages, anything added using `attach()`, and the global environment. When 
#' `allow_attached_environments = NULL`, package environments do not trigger an
#' action, nor do "tools:rstudio", "tools:positron", "tools:callr", or "Autoloads". 
#' The global environment and the package environment for the **base** package 
#' never trigger actions.
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_attached_environments <- function(action = "warn", allow_attached_environments = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_allow(allow_attached_environments)
  status <- .get_attachment_status(allow_attached_environments)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check session run time
#' 
#' @description
#' Individual session check function that inspects the session run time information. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param max_sessiontime Maximum session time permitted in seconds before the checker 
#' takes action
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_sessiontime(action = "message")
#' 
#' # a session that has run past the threshold: reports the elapsed time
#' # and the threshold together, both in human-readable units
#' check_sessiontime(action = "message", max_sessiontime = 0)
#' 
#' # a session comfortably within the threshold: `action` only controls
#' # what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_sessiontime(action = "none", max_sessiontime = Inf, action_on_pass = "message")
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_sessiontime <- function(action = "warn", max_sessiontime = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_tol(max_sessiontime)
  status <- .get_sessiontime_status(max_sessiontime)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check required values for options
#' 
#' @description
#' Individual session check function that inspects the options. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_options A named list of required options. If any of these options are 
#' missing or have different values to the required values, an action is triggered. The
#' default is `required_options = NULL`, which means there is nothing to compare
#' against, so the check always passes.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_options(action = "message", required_options = list(scipen = 0L, max.print = 50L))
#' 
#' # a required option that is present, but has a different value: reports
#' # the expected and actual values
#' old <- options(scipen = 0L)
#' check_required_options(action = "message", required_options = list(scipen = 100L))
#' options(old)
#' 
#' # a required option that is not set at all: reported as missing, rather
#' # than lumped in with the mismatched-value case above
#' check_required_options(
#'   action = "message",
#'   required_options = list(a_totally_unset_option = TRUE)
#' )
#' 
#' # a long vector value is summarized rather than printed in full
#' old <- options(scipen = 0L)
#' check_required_options(action = "message", required_options = list(scipen = 1:5000))
#' options(old)
#' 
#' # non-atomic values (e.g. lists) are described by role -- "user-supplied"
#' # vs. "a different" -- rather than by content, since two unequal lists
#' # would otherwise both print as the uninformative "<list>"
#' old <- options(sessioncheck_example = list(a = 1))
#' check_required_options(
#'   action = "message",
#'   required_options = list(sessioncheck_example = list(b = 2))
#' )
#' options(old)
#' 
#' # a required option matching its current value: `action` only controls
#' # what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_required_options(
#'   action = "none",
#'   required_options = list(digits = getOption("digits")),
#'   action_on_pass = "message"
#' )
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_locale()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_required_options <- function(action = "warn", required_options = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_required(required_options)
  status <- .get_options_status(required_options)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check required values for locale settings
#' 
#' @description
#' Individual session check function that inspects the locale settings. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_locale A named list of required locale settings. If any of these 
#' are missing or have different values to the required values, an action is triggered.
#' The default is `required_locale = NULL`, which means there is nothing to compare
#' against, so the check always passes.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_locale(action = "message", required_locale = list(LC_TIME = "en_US.UTF-8"))
#' 
#' # a required locale setting that is present, but has a different value:
#' # reports the expected and actual values
#' check_required_locale(action = "message", required_locale = list(LC_CTYPE = "not-a-real-locale"))
#' 
#' # a required locale setting that isn't part of the current locale at
#' # all: reported as missing, rather than lumped in with the
#' # mismatched-value case above
#' check_required_locale(action = "message", required_locale = list(LC_MADEUP = "en_US.UTF-8"))
#' 
#' # a required locale setting matching its current value: `action` only
#' # controls what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_required_locale(
#'   action = "none",
#'   required_locale = list(LC_COLLATE = Sys.getlocale("LC_COLLATE")),
#'   action_on_pass = "message"
#' )
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_sysenv()],
#' [check_working_directory()]
#' 
#' @export
check_required_locale <- function(action = "warn", required_locale = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_required(required_locale)
  status <- .get_locale_status(required_locale)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check required values for system environment variables
#' 
#' @description
#' Individual session check function that inspects system environment variables. 
#' Session checkers can produce errors, warnings, or messages if requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_sysenv A named list of required system environment variables. 
#' If any of these variables are missing or have different values to the required 
#' values, an action is triggered. The default is `required_sysenv = NULL`, which
#' means there is nothing to compare against, so the check always passes.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_sysenv(action = "message", required_sysenv = list(R_TEST = "value"))
#' 
#' # a required variable that is present, but has a different value: reports
#' # the expected and actual values (R_HOME is set by R itself, so this is
#' # reliably a mismatch rather than a missing variable)
#' check_required_sysenv(action = "message", required_sysenv = list(R_HOME = "not-the-real-path"))
#' 
#' # a required variable that is not set at all: reported as missing,
#' # rather than lumped in with the mismatched-value case above
#' check_required_sysenv(
#'   action = "message",
#'   required_sysenv = list(SESSIONCHECK_EXAMPLE_UNSET_VAR = "value")
#' )
#' 
#' # a required variable matching its current value: `action` only
#' # controls what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_required_sysenv(
#'   action = "none",
#'   required_sysenv = list(R_HOME = Sys.getenv("R_HOME")),
#'   action_on_pass = "message"
#' )
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
#' [check_required_locale()],
#' [check_working_directory()]
#' 
#' @export
check_required_sysenv <- function(action = "warn", required_sysenv = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_required(required_sysenv)
  status <- .get_sysenv_status(required_sysenv)
  .action(action, status, action_on_pass = action_on_pass)
}

#' @title Check the working directory
#' 
#' @description
#' Individual session check function that inspects the current working
#' directory. Session checkers can produce errors, warnings, or messages if
#' requested.
#' 
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_wd A single character path giving the working directory the
#' session is expected to be in. If any other directory is currently in use,
#' an action is triggered. The default is `required_wd = NULL`, which means
#' there is nothing to compare against, so the check always passes.
#' @param action_on_pass Behavior to take if the status is clean. Possible values
#' are "message" and "none". The default is `action_on_pass = "none"`.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_working_directory(action = "message")
#' 
#' # a working directory that does not match the required path: reports both
#' # the actual and required paths
#' check_working_directory(action = "message", required_wd = tempdir())
#' 
#' # a working directory matching the required path: `action` only controls
#' # what happens when a problem *is* found, so use
#' # `action_on_pass = "message"` to confirm the clean result instead
#' check_working_directory(
#'   action = "none",
#'   required_wd = getwd(),
#'   action_on_pass = "message"
#' )
#'  
#' @details
#' This checker compares the current working directory (`getwd()`) against
#' `required_wd`. Both paths are passed through `normalizePath()` before
#' comparison, so differences in trailing slashes or relative vs. absolute
#' form do not trigger a false positive. When `required_wd = NULL` (the
#' default), there is nothing to compare against, so the check always passes;
#' the current working directory is still reported in the message.
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
check_working_directory <- function(action = "warn", required_wd = NULL, action_on_pass = "none") {
  .validate_action(action)
  .validate_action_on_pass(action_on_pass)
  .validate_wd(required_wd)
  status <- .get_working_directory_status(required_wd)
  .action(action, status, action_on_pass = action_on_pass)
}

# status checkers: packages and namespaces ------

.get_namespace_status <- function(allow) {
  if (is.null(allow)) allow <- character(0L)
  allow <- union(allow, "sessioncheck")
  status <- vapply(
    loadedNamespaces(), 
    function(x) !(identical(utils::packageDescription(x)$Priority, "base") | x %in% allow), 
    logical(1L)
  )
  new_status(status, type = "namespace")
}

.get_package_status <- function(allow) {
  if (is.null(allow)) allow <- character(0L)
  status <- vapply(
    .packages(), 
    function(x) !(identical(utils::packageDescription(x)$Priority, "base") | x %in% allow), 
    logical(1L)
  )
  new_status(status, type = "package")
}

# status checkers: global environment and attachments ------

.get_globalenv_status <- function(allow) {
  obj <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (is.null(allow)) allow <- obj[grepl(pattern = "^\\.", x = obj)]
  status <- !(obj %in% allow)
  names(status) <- obj
  new_status(status, type = "globalenv")
}

.get_attachment_status <- function(allow) {
  if (is.null(allow)) allow <- c("tools:rstudio", "tools:positron", "tools:callr", "Autoloads")
  allow <- union(".GlobalEnv", allow)
  attached <- search()
  is_pkg <- vapply(
    seq_along(attached),
    function(ind) !is.null(attr(as.environment(ind), "path")) | ind == length(attached),
    logical(1L)
  )
  status <- !(is_pkg | attached %in% allow)
  names(status) <- attached
  new_status(status, type = "attachment")
}

# status checkers: session time ------

.get_sessiontime_status <- function(tol) {
  if (is.null(tol)) tol <- 300
  pt <- proc.time()
  elapsed <- unname(pt["elapsed"])
  status <- elapsed > tol
  names(status) <- paste(elapsed, "sec elapsed")
  # attaches the raw elapsed/threshold values as attributes (additive only
  # -- the status vector's own value/name are unchanged) so
  # .message_text_sessiontime() can report both with nicer units than the
  # raw "elapsed" name alone
  attr(status, "elapsed") <- elapsed
  attr(status, "threshold") <- tol
  new_status(status, type = "sessiontime")
}

# status checkers: options, locale, and system env variables ------

.get_options_status <- function(required) {
  if (is.null(required)) required <- list()
  opts <- options()
  status <- .get_xiny_status(x = required, y = opts)
  new_status(status, type = "options")
}

.get_sysenv_status <- function(required) {
  if (is.null(required)) required <- list()
  env <- as.list(Sys.getenv())
  status <- .get_xiny_status(x = required, y = env)
  new_status(status, type = "sysenv")
}

.get_locale_status <- function(required) {
  if (is.null(required)) required <- list()
  lc <- .get_locale_list()
  status <- .get_xiny_status(x = required, y = lc)
  new_status(status, type = "locale")
}

# status checkers: working directory ------

.get_working_directory_status <- function(required) {
  actual <- getwd()
  if (is.null(required)) {
    status <- FALSE
    names(status) <- actual
    attr(status, "actual") <- actual
    attr(status, "required") <- NULL
    return(new_status(status, type = "working_directory"))
  }
  required_norm <- normalizePath(required, winslash = "/", mustWork = FALSE)
  actual_norm <- normalizePath(actual, winslash = "/", mustWork = FALSE)
  status <- !identical(required_norm, actual_norm)
  names(status) <- actual
  attr(status, "actual") <- actual
  attr(status, "required") <- required
  new_status(status, type = "working_directory")
}

# actions and messages ------

.message_text <- function(prefix, status, max_len = 4L, clean_message = paste(prefix, "[no issues detected]")) {
  lst <- names(status[status])
  len <- length(lst)
  symbol <- .colored_symbol(if (len == 0L) "tick" else "cross")
  if (len == 0L) return(paste(symbol, clean_message))
  if (len <= max_len) {
    txt <- paste(lst, collapse = ", ")
  } else {
    lst <- lst[1:max_len]
    txt <- paste(lst, collapse = ", ")
    txt <- paste0(txt, ", and ", len - max_len, " more")
  }
  paste(symbol, prefix, txt)
}

.action <- function(action, status, action_on_pass = "none") {
  if (inherits(status, "sessioncheck_status")) {
    is_ok <- !any(status$status)
  } else if (inherits(status, "sessioncheck_sessioncheck")) {
    is_ok <- all(vapply(status, function(s) !any(s$status), logical(1L)))
  } else {
    stop("unexpected status class: ", paste(class(status), collapse = ", "), call. = FALSE)
  }
  if (is_ok) {
    # action_on_pass is orthogonal to `action`: it governs whether a clean
    # status is confirmed, regardless of what `action` would have done on
    # an unclean one (see #10)
    if (identical(action_on_pass, "message")) message(format(status))
    return(invisible(status))
  }
  if (action == "none") return(invisible(status))
  msg <- format(status)
  if (action == "message") {
    message(msg)
    return(invisible(status))
  } 
  if (action == "warn") {
    warning(msg, call. = FALSE)
    return(invisible(status))
  }
  stop(msg, call. = FALSE)
}

.parse_args <- function(...) {
  args <- list(...)
  opts_args <- getOption("sessioncheck")
  .validate_settings(opts_args)
  if (is.list(opts_args)) {
    if (is.null(args$action)) args$action <- opts_args$action
    if (is.null(args$action_on_pass)) args$action_on_pass <- opts_args$action_on_pass
    if (is.null(args$checks)) args$checks <- opts_args$checks
    if (is.null(args$allow_globalenv_objects)) args$allow_globalenv_objects <- opts_args$allow_globalenv_objects
    if (is.null(args$allow_attached_packages)) args$allow_attached_packages <- opts_args$allow_attached_packages
    if (is.null(args$allow_loaded_namespaces)) args$allow_loaded_namespaces <- opts_args$allow_loaded_namespaces
    if (is.null(args$allow_attached_environments)) args$allow_attached_environments <- opts_args$allow_attached_environments
    if (is.null(args$max_sessiontime)) args$max_sessiontime <- opts_args$max_sessiontime
    if (is.null(args$required_options)) args$required_options <- opts_args$required_options
    if (is.null(args$required_locale)) args$required_locale <- opts_args$required_locale
    if (is.null(args$required_sysenv)) args$required_sysenv <- opts_args$required_sysenv 
    if (is.null(args$required_wd)) args$required_wd <- opts_args$required_wd
  }
  args
}
