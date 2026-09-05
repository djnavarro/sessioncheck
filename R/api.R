
#' @title Report the current state of the R session
#'
#' @description
#' `sessionstate()` captures a point-in-time, human-readable snapshot of the R
#' session: platform details, selected machine information, session timing,
#' an inventory of attached and loaded-namespace packages (including remote
#' source tracking for packages installed from GitHub), the contents of the
#' global environment, and the non-package entries on the search path. It is
#' intended as a companion to [sessioncheck()]: where `sessioncheck()` is
#' typically called at the *start* of a script to check for a clean session,
#' `sessionstate()` is intended to be called at the *end* of a script to
#' produce an audit log of the environment the script actually ran in.
#'
#' @returns An object of class `sessioncheck_sessionstate`, a list with
#' elements `platform`, `machine`, `timing`, `rng`, `packages`, `globalenv`,
#' and `attachments`.
#'
#' @details
#' The `machine` element includes the node name and user reported by
#' [Sys.info()], along with the working directory reported by [getwd()] at
#' capture time (`cwd`) -- useful for a reproducibility audit since relative
#' paths used elsewhere in a script only resolve correctly relative to this
#' directory. Because this can reveal a hostname, local username, or
#' directory structure, be mindful about where `sessionstate()` output is
#' stored or shared. The same caution applies to the `ondisk_path`/
#' `loaded_path` columns of `packages`, since library paths often embed a
#' home directory.
#'
#' The `rng` element records [RNGkind()] (as `kind`, `normal_kind`, and
#' `sample_kind`) together with `seed_hash`, an MD5 fingerprint of
#' `.Random.seed` (via [tools::md5sum()], since base R has no in-memory
#' hashing function). `seed_hash` is `NA` if the RNG hasn't been used yet
#' this session (nothing has consumed a random draw, so `.Random.seed`
#' doesn't exist); `sessionstate()` never forces this into existence, since
#' doing so would itself consume a draw as a side effect of an audit call.
#' The hash exists to make RNG state comparable across renders without
#' printing the seed itself: for example, comparing `seed_hash` between two
#' rendered versions of the same Quarto/R Markdown document shows whether
#' an edit changed the RNG state anywhere upstream, without having to
#' inspect or store the (long, not directly meaningful) seed value.
#'
#' The `packages` element covers every package that is either attached to
#' the search path or loaded via namespace (i.e., `union(.packages(),
#' loadedNamespaces())`). It has columns `package`, `attached`,
#' `ondisk_version` (the version recorded in the installed package's
#' `DESCRIPTION` file), `loaded_version` (the version of the namespace
#' actually loaded into memory), `version_mismatch` (`TRUE` when the two
#' disagree, e.g. because the package was updated on disk after this
#' session loaded it), `ondisk_path` and `loaded_path` (the library paths a
#' package currently resolves to versus where its loaded namespace actually
#' came from), `path_mismatch` (`TRUE` when both exist but disagree, e.g.
#' after a `.libPaths()` change mid-session), `removed_from_disk` (`TRUE`
#' when the namespace is loaded but no longer found on disk at all), and
#' `source`, which classifies each package as `"base"`, `"CRAN (R x.y.z)"`,
#' `"Github (user/repo@sha)"`, another remote type, or `"local"` when no
#' remote metadata is available.
#'
#' The `globalenv` element is a data frame with one row per object in
#' `.GlobalEnv` (including dot-prefixed objects), with columns `name`,
#' `class`, and `size` (in bytes, as reported by [utils::object.size()]). Only
#' object names, classes, and sizes are captured, never values. Because a
#' long-running script can accumulate many objects, the default display shows
#' only the largest few (see below); the captured object itself always holds
#' every object.
#'
#' The `platform` element's `pandoc` and `quarto` fields record the versions
#' of those two document-rendering tools, if found (`NA` otherwise). Both
#' checks prefer the IDE-provided location over whatever happens to be on
#' `PATH` (`RSTUDIO_PANDOC` for pandoc, `QUARTO_PATH` for quarto), since
#' RStudio/Positron bundle their own copies that may differ from a
#' separately installed one. Deliberately not tracked: other system
#' dependencies (e.g. LaTeX, Hugo, spatial libraries) are package-specific
#' rather than session-wide, and tracking them well would mean tracking
#' many of them; `pandoc`/`quarto` are included because they, like
#' BLAS/LAPACK, are already tracked by [utils::sessionInfo()] or
#' [sessioninfo::session_info()].
#'
#' The `attachments` element is a data frame with one row per entry on the
#' search path (as returned by [search()]), with columns `name` and `type`
#' (`"package"` or `"other"`). This surfaces non-package attachments (e.g.
#' `tools:rstudio`, or environments added via [attach()]) that aren't
#' reflected in `packages`.
#'
#' `sessionstate()` itself always captures every field in full (`globalenv`
#' is never truncated at capture time). To display only a subset when
#' printing, pass `platform`/`machine`/`timing`/`rng`/`packages`/`globalenv`/
#' `attachments` arguments to `print()` or `format()` on the result, or set
#' defaults via `options(sessioncheck = list(sessionstate_packages = ...))`
#' (see [display_methods] for the full precedence rules and option names).
#' The `globalenv_n` argument separately controls how many rows of
#' `globalenv` are shown (largest objects first), independent of which
#' columns are selected. None of this affects the underlying object, so
#' `as.data.frame()` always returns the full package inventory, and
#' `x$globalenv`/`x$attachments` always return their full data frames.
#'
#' @examples
#' sessionstate()
#'
#' @seealso [sessioncheck()]
#'
#' @export
sessionstate <- function() {
  new_sessionstate(
    platform    = .get_platform_info(),
    machine     = .get_machine_info(),
    timing      = .get_timing_info(),
    rng         = .get_rng_info(),
    packages    = .get_package_inventory(),
    globalenv   = .get_globalenv_info(),
    attachments = .get_search_path_info()
  )
}

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
#' @param ... Arguments passed to individual checks.
#'
#' @returns Invisibly returns an object of class `sessioncheck_sessioncheck`.
#'  
#' @examples
#' sessioncheck(action = "message")
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
#' 
#' Other arguments are ignored.
#' @export
sessioncheck <- function(
  action = NULL, 
  checks = NULL,
  ...
) {
  args <- .parse_args(action = action, checks = checks, ...)
  .validate_action(args$action, allow_null = TRUE)
  .validate_checks(args$checks)
  if (is.null(args$action)) args$action <- "warn"
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
  .action(args$action, do.call(new_sessioncheck, results))
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
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_attached_packages(action = "message")
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
#' @param action Behavior to take if the status is not clean. Possible values are 
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
#' @param action Behavior to take if the status is not clean. Possible values are 
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
#' @param action Behavior to take if the status is not clean. Possible values are 
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
#' @param action Behavior to take if the status is not clean. Possible values are 
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
#' @param action Behavior to take if the status is not clean. Possible values are 
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
#' @param action Behavior to take if the status is not clean. Possible values are 
#' "error", "warn", "message", and "none". The default is `action = "warn"`.
#' @param required_locale A named list of required locale settings. If any of these 
#' are missing or have different values to the required values, an action is triggered.
#'
#' @returns Invisibly returns an object of class `sessioncheck_status`. 
#'  
#' @examples
#' check_required_locale(action = "message", required_locale = list(LC_TIME = "en_US.UTF-8"))
#' 
#' @seealso 
#' [check_attached_packages()],
#' [check_loaded_namespaces()],
#' [check_globalenv_objects()],
#' [check_attached_environments()],
#' [check_sessiontime()],
#' [check_required_options()],
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
#' @param action Behavior to take if the status is not clean. Possible values are 
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
#' [check_required_locale()]
#' 
#' @export
check_required_sysenv <- function(action = "warn", required_sysenv = NULL) {
  .validate_action(action)
  .validate_required(required_sysenv)
  status <- .get_sysenv_status(required_sysenv)
  .action(action, status)
}
