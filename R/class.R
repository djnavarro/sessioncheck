
# class constructors -------

new_status <- function(status, type) {
  stopifnot("status objects must be logical vectors" = is.logical(status))
  stopifnot("status objects must be named" = !length(status) | !is.null(attr(status, "names")))
  structure(
    list(status = status, type = type), 
    class = "sessioncheck_status"
  )
}

new_sessioncheck <- function(...) {
  structure(list(...), class = "sessioncheck_sessioncheck")
}

new_sessionstate <- function(platform, machine, timing, packages) {
  structure(
    list(platform = platform, machine = machine, timing = timing, packages = packages),
    class = "sessioncheck_sessionstate"
  )
}


# methods --------

#' Format and print sessioncheck objects
#'
#' @param x An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
#' or `sessioncheck_sessionstate`
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
  if (x$type == "locale")      prefix <- "Unexpected locale settings:"
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
#' @exportS3Method base::format
format.sessioncheck_sessionstate <- function(x, ...) {
  p <- x$platform
  m <- x$machine
  t <- x$timing

  platform_lines <- c(
    "Platform:",
    sprintf(" version         %s", p$version),
    sprintf(" os              %s", p$os),
    sprintf(" system          %s", p$system),
    sprintf(" ui              %s", p$ui),
    sprintf(" language        %s", if (is.na(p$language)) "(unset)" else p$language),
    sprintf(" collate         %s", p$collate),
    sprintf(" ctype           %s", p$ctype),
    sprintf(" tz              %s", p$tz),
    sprintf(" date            %s", p$date),
    " matrix products",
    sprintf("   BLAS:   %s", p$blas),
    sprintf("   LAPACK: %s", p$lapack)
  )

  machine_lines <- c(
    "Machine:",
    sprintf(" nodename        %s", m$nodename),
    sprintf(" user            %s", m$user)
  )

  timing_lines <- c(
    "Timing:",
    sprintf(" captured at     %s", format(t$captured_at)),
    sprintf(" elapsed (sec)   %s", t$elapsed_sec)
  )

  pkg_df <- x$packages
  pkg_df$attached <- ifelse(pkg_df$attached, "*", " ")
  pkg_lines <- c(
    sprintf("Packages [n = %d] (attached + loaded via namespace):", nrow(pkg_df)),
    utils::capture.output(print(pkg_df, row.names = FALSE))
  )

  paste(
    c(platform_lines, "", machine_lines, "", timing_lines, "", pkg_lines),
    collapse = "\n"
  )
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

#' @rdname display_methods
#' @exportS3Method base::print
print.sessioncheck_sessionstate <- function(x, ...) {
  cat(format(x, ...), "\n")
  invisible(x)
}


#' Coerce session check object to a data frame
#'
#' @param x An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
#' or `sessioncheck_sessionstate`
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

#' @rdname coercion_methods
#' @exportS3Method base::as.data.frame
as.data.frame.sessioncheck_sessionstate <- function(x, row.names = NULL, optional = FALSE, ...) {
  x$packages
}


