
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

new_sessionstatediff <- function(platform, locale, matrix, document, machine, git, timing, rng, libpaths, packages, globalenv, attachments) {
  structure(
    list(
      platform = platform, locale = locale, matrix = matrix, document = document, machine = machine,
      git = git, timing = timing, rng = rng, libpaths = libpaths, packages = packages,
      globalenv = globalenv, attachments = attachments
    ),
    class = "sessioncheck_sessionstatediff"
  )
}


# status message tables ------

# fail-state prefix and pass-state message for each check type, keyed so
# that a failing check always reads "Unexpected <thing>:" followed by its
# summary, and a passing check always reads "No unexpected <thing>"
# instead of the uninformative, one-size-fits-all "[no issues detected]"
# (see #5 follow-up discussion on message framing consistency)
.status_prefix <- c(
  namespace   = "Unexpected namespaces:",
  package     = "Unexpected packages:",
  globalenv   = "Unexpected objects in global environment:",
  attachment  = "Unexpected environments attached:",
  sessiontime = "Session runtime exceeded:",
  options     = "Unexpected options:",
  sysenv      = "Unexpected system environment variables:",
  locale      = "Unexpected locale settings:",
  working_directory = "Unexpected working directory:"
)

.status_clean_message <- c(
  namespace   = "No unexpected namespaces loaded",
  package     = "No unexpected packages attached",
  globalenv   = "No unexpected objects in global environment",
  attachment  = "No unexpected environments attached",
  sessiontime = "Session runtime within limits",
  options     = "No unexpected options detected",
  sysenv      = "No unexpected system environment variables detected",
  locale      = "No unexpected locale settings detected",
  working_directory = "Working directory as expected"
)

# methods --------

#' Format and print sessioncheck objects
#'
#' @description
#' S3 `format()`/`print()` methods for the three classes this package
#' defines. `sessioncheck_status`/`sessioncheck_sessioncheck` objects render
#' as a one-line-per-check status summary; `sessioncheck_sessionstate`
#' objects render as a multi-section report, and the arguments below let
#' that report be filtered down to specific fields or columns per section.
#'
#' @param x An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
#' `sessioncheck_sessionstate`, or `sessioncheck_sessionstatediff`
#' @param changed_only For `sessioncheck_sessionstatediff` objects, whether to
#' collapse sections/fields with no detected change down to a single "(no
#' changes)" line (`TRUE`, the default) or always show every field. Ignored
#' for other classes.
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
#' (from `"name"`, `"class"`, `"size"`, `"hash"`). Defaults to
#' `c("name", "class", "size")` (omitting `"hash"`, a long fingerprint
#' mainly useful programmatically -- see [compare_sessionstates()]).
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
#' `c("package", "attached", "loaded_version", "source")`,
#' `globalenv`, which defaults to `c("name", "class", "size")`, and
#' `globalenv_n`, which defaults to `10`). This selection only affects what
#' is displayed; it never changes the underlying object, so
#' [`as.data.frame()`][coercion_methods] always returns the full package
#' inventory, and `x$globalenv`/`x$attachments` always return their full
#' data frames, regardless of any selection in effect.
#'
#' @name display_methods

#' @rdname display_methods
#' @exportS3Method base::format
format.sessioncheck_status <- function(x, ...) {
  prefix <- .status_prefix[[x$type]]
  clean_message <- .status_clean_message[[x$type]]
  if (x$type %in% c("options", "sysenv", "locale")) {
    return(.message_text_detail(prefix, x$status, clean_message = clean_message))
  }
  if (x$type == "sessiontime") {
    return(.message_text_sessiontime(x$status, prefix, clean_message))
  }
  if (x$type == "working_directory") {
    return(.message_text_working_directory(x$status, prefix, clean_message))
  }
  .message_text(prefix, x$status, clean_message = clean_message)
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
#' @description
#' S3 `as.data.frame()` methods for the three classes this package defines,
#' letting each be dropped into ordinary data frame workflows (filtering,
#' joining, export) instead of only being inspected via `print()`/`format()`.
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
#' `sessioncheck_sessionstate` objects: [sessionstate()] captures more than
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
