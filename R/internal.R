
# argument validators ------

.validate_action <- function(action) {
  stopifnot(
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = length(action) == 1L,
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = is.character(action),
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = action %in% c("error", "warn", "message", "none")
  )
}

.validate_allow <- function(allow) {
  stopifnot("`allow` must be a character vector or NULL" = is.character(allow) | is.null(allow))
}

.validate_settings <- function(settings) {
  stopifnot("`settings` must be a list or NULL" = is.list(settings) | is.null(settings))
}

# status checkers ------

.get_globalenv_status <- function(allow) {
  obj <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (is.null(allow)) allow <- obj[grepl(pattern = "^\\.", x = obj)]
  status <- obj %in% allow
  names(status) <- obj
  status
}

.get_namespace_status <- function(allow) {
  if (is.null(allow)) allow <- character(0L)
  allow <- union(allow, "sessioncheck")
  status <- vapply(
    loadedNamespaces(), 
    function(x) identical(utils::packageDescription(x)$Priority, "base") | x %in% allow, 
    logical(1L)
  )
  status
}

.get_package_status <- function(allow) {
  if (is.null(allow)) allow <- character(0L)
  status <- vapply(
    .packages(), 
    function(x) identical(utils::packageDescription(x)$Priority, "base") | x %in% allow, 
    logical(1L)
  )
  status
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
  status <- is_pkg | attached %in% allow
  names(status) <- attached
  status
}

# actions and messages ------

.message_text <- function(prefix, status, max_len = 4L) {
  lst <- names(status[!status])
  len <- length(lst)
  if (len == 0L) return(paste(prefix, "[no issues]"))
  if (len <= max_len) {
    txt <- paste(lst, collapse = ", ")
  } else {
    lst <- lst[1:max_len]
    txt <- paste(lst, collapse = ", ")
    txt <- paste0(txt, ", and ", len - max_len, " more")
  }
  paste(prefix, txt)
}

.action <- function(action, status, message = NULL) {
  if (action == "none") return(invisible(status)) 
  if (is.atomic(status) && !any(!status)) return(invisible(status))
  if (!is.atomic(status)) {
    is_ok <- vapply(status, function(s) !any(!s), logical(1L))
    if (all(is_ok)) return(invisible(status))
  }
  if (action == "message") {
    message(message)
    return(invisible(status))
  } 
  if (action == "warn") {
    warning(message, call. = FALSE)
    return(invisible(status))
  }
  stop(message, call. = FALSE)
}

