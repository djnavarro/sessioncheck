
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

new_sessionstate <- function(platform, locale, matrix, document, machine, git, timing, rng, libpaths, packages, globalenv, attachments) {
  structure(
    list(
      platform = platform, locale = locale, matrix = matrix, document = document, machine = machine,
      git = git, timing = timing, rng = rng, libpaths = libpaths, packages = packages,
      globalenv = globalenv, attachments = attachments
    ),
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
#' `"system"`, `"ui"`, `"tz"`, `"date"`). Defaults to showing all fields.
#' Ignored for other classes. See Details for how the default is resolved.
#' @param locale For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which locale fields to display (from `"language"`,
#' `"collate"`, `"ctype"`). Defaults to showing all fields. Ignored for
#' other classes. See Details for how the default is resolved.
#' @param matrix For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which matrix-products fields to display (from `"blas"`,
#' `"lapack"`). Defaults to showing all fields. Ignored for other classes.
#' See Details for how the default is resolved.
#' @param document For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which document-products fields to display (from
#' `"pandoc"`, `"quarto"`). Defaults to showing all fields. Ignored for
#' other classes. See Details for how the default is resolved.
#' @param machine For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which machine fields to display (from `"nodename"`,
#' `"user"`, `"cwd"`). Defaults to showing all fields. Ignored for other
#' classes. See Details for how the default is resolved.
#' @param git For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which git fields to display (from `"sha"`, `"dirty"`).
#' Defaults to showing all fields. Ignored for other classes. See Details for
#' how the default is resolved.
#' @param timing For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which timing fields to display (from `"captured_at"`,
#' `"elapsed_sec"`). Defaults to showing all fields. Ignored for other classes.
#' See Details for how the default is resolved.
#' @param rng For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which RNG fields to display (from `"kind"`,
#' `"normal_kind"`, `"sample_kind"`, `"seed_hash"`). Defaults to showing all
#' fields. Ignored for other classes. See Details for how the default is
#' resolved.
#' @param packages For `sessioncheck_sessionstate` objects, an optional character
#' vector selecting which package inventory columns to display (see
#' [sessionstate()] for the full list of columns). Defaults to
#' `c("package", "attached", "loaded_version", "source")`. Ignored for other
#' classes. See Details for how the default is resolved.
#' @param globalenv For `sessioncheck_sessionstate` objects, an optional
#' character vector selecting which global environment columns to display
#' (from `"name"`, `"class"`, `"size"`). Defaults to showing all columns.
#' Ignored for other classes. See Details for how the default is resolved,
#' and for how `globalenv_n` separately controls the number of rows shown.
#' @param globalenv_n For `sessioncheck_sessionstate` objects, an optional
#' single number giving the maximum number of `globalenv` rows to display,
#' largest objects first. Defaults to `10`. Ignored for other classes. See
#' Details for how the default is resolved.
#' @param attachments For `sessioncheck_sessionstate` objects, an optional
#' character vector selecting which attached-environment columns to display
#' (from `"name"`, `"type"`). Defaults to showing all columns. Ignored for
#' other classes. See Details for how the default is resolved.
#' @param ... Ignored
#'
#' @returns Character vector
#'
#' @details
#' For `sessioncheck_sessionstate` objects, the `platform`/`locale`/`matrix`/
#' `document`/`machine`/`git`/`timing`/`rng`/`packages`/`globalenv`/
#' `globalenv_n`/`attachments`
#' arguments are resolved through the same precedence used elsewhere in the
#' package: an explicit argument always wins; otherwise,
#' `getOption("sessioncheck")` is checked for a `sessionstate_platform`,
#' `sessionstate_locale`, `sessionstate_matrix`, `sessionstate_document`,
#' `sessionstate_machine`, `sessionstate_git`, `sessionstate_timing`,
#' `sessionstate_rng`, `sessionstate_packages`, `sessionstate_globalenv`,
#' `sessionstate_globalenv_n`, or `sessionstate_attachments` field
#' (respectively); if neither is set, a
#' built-in default is used (showing every field/column, except for
#' `packages`, which defaults to
#' `c("package", "attached", "loaded_version", "source")`, and
#' `globalenv_n`, which defaults to `10`). This selection only affects what
#' is displayed; it never changes the underlying object, so
#' `as.data.frame()` always returns the full package inventory, and
#' `x$globalenv`/`x$attachments` always return their full data frames,
#' regardless of any selection in effect.
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
    # no "- " list marker needed here: each element of msg already starts
    # with a tick/cross symbol from .message_text(), which now serves that
    # purpose
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
#' @param x An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
#' or `sessioncheck_sessionstate`
#' @param row.names Ignored
#' @param optional Ignored
#' @param which For `sessioncheck_sessionstate` objects, which tabular
#' component to return: one of `"packages"` (the default), `"globalenv"`,
#' or `"attachments"`. Ignored for other classes.
#' @param ... Ignored
#'
#' @returns A data frame
#'
#' @details
#' For `sessioncheck_status` and `sessioncheck_sessioncheck` objects, this
#' coercion is lossless: every entity and status recorded in `x` appears as a
#' row in the result. That guarantee does not extend to
#' `sessioncheck_sessionstate` objects: `sessionstate()` captures more than
#' any single rectangular table can hold, mixing scalar fields (`platform`,
#' `locale`, `matrix`, `document`, `machine`, `git`, `timing`, `rng`), a bare
#' character vector (`libpaths`), and three differently-shaped tables
#' (`packages`, `globalenv`, `attachments`). `as.data.frame()` returns
#' whichever one of those three tables `which` selects; none of the scalar
#' fields or `libpaths` are represented in the result. Use `x$platform`,
#' `x$machine`, `x$git`, `x$libpaths`, etc. (or `unclass(x)` for everything
#' at once) to access those directly.
#'
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
