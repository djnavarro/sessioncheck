
# argument validators ------

.validate_action <- function(action, allow_null = FALSE) {
  if (allow_null & is.null(action)) return(invisible(NULL))
  stopifnot(
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = length(action) == 1L,
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = is.character(action),
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = action %in% c("error", "warn", "message", "none")
  )
}

.validate_allow <- function(allow) {
  stopifnot("`allow` must be a character vector or NULL" = is.character(allow) | is.null(allow))
}

.validate_tol <- function(tol) {
  if (is.null(tol)) return(invisible(NULL))
  stopifnot("`tol` must be a single numeric value or NULL" = is.numeric(tol) & length(tol) == 1L)
}

.validate_settings <- function(settings) {
  stopifnot("`settings` must be a list or NULL" = is.list(settings) | is.null(settings))
}

.validate_checks <- function(checks) {
  if (is.null(checks)) return(invisible(NULL))
  valid <- c(
    "globalenv_objects", "attached_packages", "loaded_namespaces",
    "attached_environments", "sessiontime", "required_options",
    "required_locale", "required_sysenv"
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
