
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
#' @param platform For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which platform fields to display (from `"version"`, `"os"`,
#' `"system"`, `"ui"`, `"language"`, `"collate"`, `"ctype"`, `"tz"`, `"date"`,
#' `"blas"`, `"lapack"`). Defaults to showing all fields. Ignored for other
#' classes. See Details for how the default is resolved.
#' @param machine For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which machine fields to display (from `"nodename"`, `"user"`).
#' Defaults to showing all fields. Ignored for other classes. See Details for
#' how the default is resolved.
#' @param timing For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which timing fields to display (from `"captured_at"`,
#' `"elapsed_sec"`). Defaults to showing all fields. Ignored for other classes.
#' See Details for how the default is resolved.
#' @param packages For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which package inventory columns to display (see
#' [sessionstate()] for the full list of columns). Defaults to
#' `c("package", "attached", "loaded_version", "source")`. Ignored for other
#' classes. See Details for how the default is resolved.
#' @param ... Ignored
#'
#' @returns Character vector
#'
#' @details
#' For `sessioncheck_sessionstate` objects, the `platform`/`machine`/`timing`/
#' `packages` arguments are resolved through the same precedence used
#' elsewhere in the package: an explicit argument always wins; otherwise,
#' `getOption("sessioncheck")` is checked for a `sessionstate_platform`,
#' `sessionstate_machine`, `sessionstate_timing`, or `sessionstate_packages`
#' field (respectively); if neither is set, a built-in default is used
#' (showing every field, except for `packages`, which defaults to
#' `c("package", "attached", "loaded_version", "source")`). This selection
#' only affects what is displayed; it never changes the underlying object, so
#' `as.data.frame()` always returns the full package inventory regardless of
#' any selection in effect.
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
format.sessioncheck_sessionstate <- function(x, platform = NULL, machine = NULL, timing = NULL, packages = NULL, ...) {
  p <- x$platform
  m <- x$machine
  t <- x$timing

  platform_all <- c(
    version  = sprintf(" version         %s", p$version),
    os       = sprintf(" os              %s", p$os),
    system   = sprintf(" system          %s", p$system),
    ui       = sprintf(" ui              %s", p$ui),
    language = sprintf(" language        %s", if (is.na(p$language)) "(unset)" else p$language),
    collate  = sprintf(" collate         %s", p$collate),
    ctype    = sprintf(" ctype           %s", p$ctype),
    tz       = sprintf(" tz              %s", p$tz),
    date     = sprintf(" date            %s", p$date),
    blas     = sprintf("   BLAS:   %s", p$blas),
    lapack   = sprintf("   LAPACK: %s", p$lapack)
  )
  platform <- .resolve_field_selection(platform, "sessionstate_platform", NULL)
  platform_fields <- .select_fields(names(platform_all), platform, "platform")
  # keep the "matrix products" subheading only when blas/lapack are shown,
  # and always immediately above them (their canonical position)
  matrix_fields <- intersect(c("blas", "lapack"), platform_fields)
  regular_fields <- setdiff(platform_fields, matrix_fields)
  platform_lines <- c("Platform:", platform_all[regular_fields])
  if (length(matrix_fields) > 0L) {
    platform_lines <- c(platform_lines, " matrix products", platform_all[matrix_fields])
  }

  machine_all <- c(
    nodename = sprintf(" nodename        %s", m$nodename),
    user     = sprintf(" user            %s", m$user)
  )
  machine <- .resolve_field_selection(machine, "sessionstate_machine", NULL)
  machine_fields <- .select_fields(names(machine_all), machine, "machine")
  machine_lines <- c("Machine:", machine_all[machine_fields])

  timing_all <- c(
    captured_at = sprintf(" captured at              %s", format(t$captured_at, usetz = TRUE)),
    elapsed_sec = sprintf(" session runtime (sec)    %s", t$elapsed_sec)
  )
  timing <- .resolve_field_selection(timing, "sessionstate_timing", NULL)
  timing_fields <- .select_fields(names(timing_all), timing, "timing")
  timing_lines <- c("Timing:", timing_all[timing_fields])

  pkg_df <- x$packages
  packages <- .resolve_field_selection(
    packages, "sessionstate_packages",
    c("package", "attached", "loaded_version", "source")
  )
  pkg_cols <- .select_fields(names(pkg_df), packages, "packages")
  pkg_df <- pkg_df[, pkg_cols, drop = FALSE]
  if ("attached" %in% names(pkg_df)) pkg_df$attached <- ifelse(pkg_df$attached, "*", " ")
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
print.sessioncheck_sessionstate <- function(x, platform = NULL, machine = NULL, timing = NULL, packages = NULL, ...) {
  cat(format(x, platform = platform, machine = machine, timing = timing, packages = packages, ...), "\n")
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


