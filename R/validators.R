
# argument validators ------

.validate_action <- function(action, allow_null = FALSE) {
  if (allow_null & is.null(action)) return(invisible(NULL))
  stopifnot(
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = length(action) == 1L,
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = is.character(action),
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = action %in% c("error", "warn", "message", "none")
  )
}

# only "none" and "message" are admissible here: unlike .validate_action(),
# this governs behavior on a *clean* status, and "error"/"warn" on a passing
# check would be nonsensical (see #10)
.validate_action_on_pass <- function(action_on_pass, allow_null = FALSE) {
  if (allow_null & is.null(action_on_pass)) return(invisible(NULL))
  stopifnot(
    "`action_on_pass` must be one of 'none' or 'message'" = length(action_on_pass) == 1L,
    "`action_on_pass` must be one of 'none' or 'message'" = is.character(action_on_pass),
    "`action_on_pass` must be one of 'none' or 'message'" = action_on_pass %in% c("none", "message")
  )
}

.validate_allow <- function(allow) {
  stopifnot("`allow` must be a character vector or NULL" = is.character(allow) | is.null(allow))
}

.validate_tol <- function(tol) {
  if (is.null(tol)) return(invisible(NULL))
  stopifnot("`tol` must be a single numeric value or NULL" = is.numeric(tol) & length(tol) == 1L)
}

.validate_wd <- function(wd) {
  if (is.null(wd)) return(invisible(NULL))
  stopifnot(
    "`required_wd` must be a single character string or NULL" =
      is.character(wd) && length(wd) == 1L && !is.na(wd)
  )
}

.validate_settings <- function(settings) {
  stopifnot("`settings` must be a list or NULL" = is.list(settings) | is.null(settings))
}

.validate_checks <- function(checks) {
  if (is.null(checks)) return(invisible(NULL))
  valid <- c(
    "globalenv_objects", "attached_packages", "loaded_namespaces",
    "attached_environments", "sessiontime", "required_options",
    "required_locale", "required_sysenv", "working_directory"
  )
  stopifnot(
    "`checks` must be a character vector" = is.character(checks),
    "`checks` must contain valid check names" = all(checks %in% valid)
  )
}

.validate_required <- function(required) {
  stopifnot("`required` must be a list or NULL" = is.list(required) | is.null(required))
  if (!is.null(required) && length(required) > 0L) {
    stopifnot(
      "`required` must be a named list" = 
        !is.null(names(required)) && !any(names(required) == "")
    )
  }
}

# `label` names the offending argument in the error (e.g. "old"/"new" for
# compare_sessionstates()) so a mistaken sessioncheck() or bare list gets a
# message pointing at the specific argument rather than a generic complaint
.validate_sessionstate <- function(x, label) {
  if (!inherits(x, "sessioncheck_sessionstate")) {
    stop(
      sprintf(
        "`%s` must be an object of class 'sessioncheck_sessionstate' (see sessionstate())",
        label
      ),
      call. = FALSE
    )
  }
}
