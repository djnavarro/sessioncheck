
# class constructors -------

new_status <- function(status, type) {
  stopifnot("status objects must be logical vectors" = is.logical(status))
  stopifnot("status objects must be named" = !is.null(attr(status, "names")))
  structure(
    list(status = status, type = type), 
    class = "sessioncheck_status"
  )
}

new_sessioncheck <- function(...) {
  structure(list(...), class = "sessioncheck_sessioncheck")
}


# methods --------

#' Format and print sessioncheck objects
#'
#' @param x An object of class `sessioncheck_status` or `sessioncheck_sessioncheck`
#' @param ... Ignored
#'
#' @returns Character vector
#'
#' @name display_methods

#' @rdname display_methods
#' @exportS3Method base::format
format.sessioncheck_status <- function(x, ...) {
  if (x$type == "namespace")   prefix <- "Loaded namespaces:"
  if (x$type == "package")     prefix <- "Attached packages:"
  if (x$type == "globalenv")   prefix <- "Objects in global environment:"
  if (x$type == "attachment")  prefix <- "Attached environments:"
  if (x$type == "sessiontime") prefix <- "Session runtime:"
  if (x$type == "options")     prefix <- "Unexpected options:"
  if (x$type == "sysenv")      prefix <- "Unexpected system environment variables:"
  if (x$type == "locale")      prefix <- "Unexpected locale setttings:"
  .message_text(prefix, x$status)
}

#' @rdname display_methods
#' @exportS3Method base::format
format.sessioncheck_sessioncheck <- function(x, ...) {
  msg <- vapply(x, format, "")
  if (length(msg) > 0L) {
    msg <- paste("-", msg)
    msg <- paste(msg, collapse = "\n")
    msg <- paste("Session check results:", msg, sep = "\n")
  }
  msg
}

#' @rdname display_methods
#' @exportS3Method base::print
print.sessioncheck_status <- function(x, ...) {
  cat(format(x, ...))
  invisible(x)
}

#' @rdname display_methods
#' @exportS3Method base::print
print.sessioncheck_sessioncheck <- function(x, ...) {
  cat(format(x, ...))
  invisible(x)
}


#' Coerce session check object to a data frame
#'
#' @param x An object of class `sessioncheck_status` or `sessioncheck_sessioncheck`
#' @param row.names Ignored
#' @param optional Ignored
#' @param ... Ignored
#'
#' @returns A data frame
#' @name coercion_methods

#' @rdname coercion_methods
#' @exportS3Method base::as.data.frame
as.data.frame.sessioncheck_status <- function(x, row.names = NULL, optional = FALSE, ...) {
  data.frame(
    type = x$type,
    entity = names(x$status),
    status = unname(x$status)
  )
}

#' @rdname coercion_methods
#' @exportS3Method base::as.data.frame
as.data.frame.sessioncheck_sessioncheck <- function(x, row.names = NULL, optional = FALSE, ...) {
  dd <- lapply(x, as.data.frame)
  dd <- do.call(rbind, dd)
  rownames(dd) <- NULL
  dd
}


