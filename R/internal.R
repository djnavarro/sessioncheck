
.validate_action <- function(action) {
  stopifnot(
    "`action` must be one of 'error', 'warn', or 'message'" = length(action) == 1L,
    "`action` must be one of 'error', 'warn', or 'message'" = is.character(action),
    "`action` must be one of 'error', 'warn', or 'message'" = action %in% c("error", "warn", "message")
  )
}

.validate_ignore <- function(ignore) {
  stopifnot("`ignore` must be a character vector or NULL" = is.character(ignore) | is.null(ignore))
}

.get_environment_status <- function(envir, ignore) {
  obj <- ls(envir = envir, all.names = TRUE)
  if (is.null(ignore)) ignore <- obj[grepl(pattern = "^\\.", x = obj)]
  status <- obj %in% ignore
  names(status) <- obj
  status
}

.get_package_status <- function(ignore) {
  if (is.null(ignore)) ignore <- "sessioncheck"
  status <- vapply(
    loadedNamespaces(), 
    function(x) identical(utils::packageDescription(x)$Priority, "base") | x %in% ignore, 
    logical(1L)
  )
  status
}

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

