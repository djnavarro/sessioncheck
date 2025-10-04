
# argument validators ------

.validate_action <- function(action) {
  stopifnot(
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = length(action) == 1L,
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = is.character(action),
    "`action` must be one of 'error', 'warn', 'message', or 'none'" = action %in% c("error", "warn", "message", "none")
  )
}

.validate_ignore <- function(ignore) {
  stopifnot("`ignore` must be a character vector or NULL" = is.character(ignore) | is.null(ignore))
}

# status checkers ------

.get_environment_status <- function(envir, ignore) {
  obj <- ls(envir = envir, all.names = TRUE)
  if (is.null(ignore)) ignore <- obj[grepl(pattern = "^\\.", x = obj)]
  status <- obj %in% ignore
  names(status) <- obj
  status
}

.get_namespace_status <- function(ignore) {
  if (is.null(ignore)) ignore <- "sessioncheck"
  status <- vapply(
    loadedNamespaces(), 
    function(x) identical(utils::packageDescription(x)$Priority, "base") | x %in% ignore, 
    logical(1L)
  )
  status
}

.get_package_status <- function(ignore) {
  if (is.null(ignore)) ignore <- "sessioncheck"
  status <- vapply(
    .packages(), 
    function(x) identical(utils::packageDescription(x)$Priority, "base") | x %in% ignore, 
    logical(1L)
  )
  status
}

.get_attachment_status <- function(ignore) {
  if (is.null(ignore)) ignore <- c("tools:rstudio", "tools:positron", "Autoloads")
  ignore <- union(".GlobalEnv", ignore)
  attached <- search()
  is_pkg <- vapply(
    seq_along(attached),
    function(ind) !is.null(attr(as.environment(ind), "path")) | ind == length(attached),
    logical(1L)
  )
  status <- is_pkg | attached %in% ignore
  names(status) <- attached
  status
}

# actions and messages ------

.message_text <- function(prefix, status, max_len = 4L) {
  lst <- names(status[!status])
  len <- length(lst)
  if (len == 0L) return(NULL)
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
  if (!any(!status)) return(invisible(status))
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

