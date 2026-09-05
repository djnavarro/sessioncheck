
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

# resolves a print/format field-selection argument through the same
# precedence tiering used elsewhere in the package: explicit arg >
# options(sessioncheck = list(<option_name> = ...)) > hard-coded default
# (which may itself be NULL, meaning "show everything")
.resolve_field_selection <- function(explicit, option_name, hardcoded_default) {
  if (!is.null(explicit)) return(explicit)
  opts <- getOption("sessioncheck")
  if (is.list(opts) && !is.null(opts[[option_name]])) return(opts[[option_name]])
  hardcoded_default
}

# selects and validates a subset of named fields (e.g. for print/format
# display filtering), preserving canonical order rather than the order the
# user requested; returns all_names unchanged when requested is NULL
.select_fields <- function(all_names, requested, label) {
  if (is.null(requested)) return(all_names)
  if (!is.character(requested)) {
    stop(sprintf("`%s` must be a character vector or NULL", label), call. = FALSE)
  }
  unknown <- setdiff(requested, all_names)
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        "Unknown %s field(s): %s. Valid fields are: %s",
        label, paste(unknown, collapse = ", "), paste(all_names, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  all_names[all_names %in% requested]
}

# formats raw byte counts (as captured by .get_globalenv_info()) into
# human-readable units for display, reusing base R's object_size formatting
# rather than hand-rolling KB/MB thresholds
.format_object_size <- function(bytes) {
  vapply(
    bytes,
    function(b) format(structure(b, class = "object_size"), units = "auto"),
    character(1L)
  )
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
  elapsed <- pt["elapsed"]
  status <- elapsed > tol
  names(status) <- paste(elapsed, "sec elapsed")
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

# actions and messages ------

.message_text <- function(prefix, status, max_len = 4L) {
  lst <- names(status[status])
  len <- length(lst)
  if (len == 0L) return(paste(prefix, "[no issues detected]"))
  if (len <= max_len) {
    txt <- paste(lst, collapse = ", ")
  } else {
    lst <- lst[1:max_len]
    txt <- paste(lst, collapse = ", ")
    txt <- paste0(txt, ", and ", len - max_len, " more")
  }
  paste(prefix, txt)
}

.action <- function(action, status) {
  if (action == "none") return(invisible(status)) 
  if (inherits(status, "sessioncheck_status")) {
    is_ok <- !any(status$status)
  } else if (inherits(status, "sessioncheck_sessioncheck")) {
    is_ok <- all(vapply(status, function(s) !any(s$status), logical(1L)))
  } else {
    stop("unexpected status class: ", paste(class(status), collapse = ", "), call. = FALSE)
  }
  if (is_ok) return(invisible(status))
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

