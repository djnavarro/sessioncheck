
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

new_sessionstate <- function(platform, machine, git, timing, rng, packages, globalenv, attachments) {
  structure(
    list(
      platform = platform, machine = machine, git = git, timing = timing, rng = rng,
      packages = packages, globalenv = globalenv, attachments = attachments
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
#' `"system"`, `"ui"`, `"language"`, `"collate"`, `"ctype"`, `"tz"`, `"date"`,
#' `"blas"`, `"lapack"`, `"pandoc"`, `"quarto"`). Defaults to showing all
#' fields. Ignored for other classes. See Details for how the default is
#' resolved.
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
#' For `sessioncheck_sessionstate` objects, the `platform`/`machine`/`git`/
#' `timing`/`rng`/`packages`/`globalenv`/`globalenv_n`/`attachments`
#' arguments are resolved through the same precedence used elsewhere in the
#' package: an explicit argument always wins; otherwise,
#' `getOption("sessioncheck")` is checked for a `sessionstate_platform`,
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
    msg <- paste("-", msg)
    msg <- paste(msg, collapse = "\n")
    msg <- paste("Session check results:", msg, sep = "\n")
  }
  msg
}

#' @rdname display_methods
#' @exportS3Method base::format
format.sessioncheck_sessionstate <- function(x, platform = NULL, machine = NULL, git = NULL, timing = NULL, rng = NULL, packages = NULL, globalenv = NULL, globalenv_n = NULL, attachments = NULL, ...) {
  p <- x$platform
  m <- x$machine
  g <- x$git
  t <- x$timing
  r <- x$rng

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
    lapack   = sprintf("   LAPACK: %s", p$lapack),
    pandoc   = sprintf("   pandoc: %s", if (is.na(p$pandoc)) "(not found)" else p$pandoc),
    quarto   = sprintf("   quarto: %s", if (is.na(p$quarto)) "(not found)" else p$quarto)
  )
  platform <- .resolve_field_selection(platform, "sessionstate_platform", NULL)
  platform_fields <- .select_fields(names(platform_all), platform, "platform")
  # keep the "matrix products"/"document products" subheadings only when
  # their respective fields are shown, and always immediately above them
  # (their canonical position)
  matrix_fields <- intersect(c("blas", "lapack"), platform_fields)
  doc_fields <- intersect(c("pandoc", "quarto"), platform_fields)
  regular_fields <- setdiff(platform_fields, c(matrix_fields, doc_fields))
  platform_lines <- c("Platform:", platform_all[regular_fields])
  if (length(matrix_fields) > 0L) {
    platform_lines <- c(platform_lines, " matrix products", platform_all[matrix_fields])
  }
  if (length(doc_fields) > 0L) {
    platform_lines <- c(platform_lines, " document products", platform_all[doc_fields])
  }

  machine_all <- c(
    nodename = sprintf(" nodename        %s", m$nodename),
    user     = sprintf(" user            %s", m$user),
    cwd      = sprintf(" cwd             %s", m$cwd)
  )
  machine <- .resolve_field_selection(machine, "sessionstate_machine", NULL)
  machine_fields <- .select_fields(names(machine_all), machine, "machine")
  machine_lines <- c("Machine:", machine_all[machine_fields])

  git_all <- c(
    sha   = sprintf(" sha             %s", if (is.na(g$sha)) "(not a git repository)" else g$sha),
    dirty = sprintf(" dirty           %s", if (is.na(g$dirty)) "(unknown)" else g$dirty)
  )
  git <- .resolve_field_selection(git, "sessionstate_git", NULL)
  git_fields <- .select_fields(names(git_all), git, "git")
  git_lines <- c("Git:", git_all[git_fields])

  timing_all <- c(
    captured_at = sprintf(" captured at              %s", format(t$captured_at, usetz = TRUE)),
    elapsed_sec = sprintf(" session runtime (sec)    %s", t$elapsed_sec)
  )
  timing <- .resolve_field_selection(timing, "sessionstate_timing", NULL)
  timing_fields <- .select_fields(names(timing_all), timing, "timing")
  timing_lines <- c("Timing:", timing_all[timing_fields])

  rng_all <- c(
    kind        = sprintf(" kind            %s", r$kind),
    normal_kind = sprintf(" normal kind     %s", r$normal_kind),
    sample_kind = sprintf(" sample kind     %s", r$sample_kind),
    seed_hash   = sprintf(" seed hash       %s", if (is.na(r$seed_hash)) "(not set)" else r$seed_hash)
  )
  rng <- .resolve_field_selection(rng, "sessionstate_rng", NULL)
  rng_fields <- .select_fields(names(rng_all), rng, "rng")
  rng_lines <- c("RNG state:", rng_all[rng_fields])

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

  genv_df_full <- x$globalenv
  # largest objects first, independent of which columns end up displayed
  genv_df_full <- genv_df_full[order(-genv_df_full$size), , drop = FALSE]
  globalenv <- .resolve_field_selection(globalenv, "sessionstate_globalenv", NULL)
  genv_cols <- .select_fields(names(genv_df_full), globalenv, "globalenv")
  genv_df <- genv_df_full[, genv_cols, drop = FALSE]
  n_total <- nrow(genv_df)
  globalenv_n <- .resolve_field_selection(globalenv_n, "sessionstate_globalenv_n", 10L)
  if (!is.numeric(globalenv_n) || length(globalenv_n) != 1L) {
    stop("`globalenv_n` must be a single number", call. = FALSE)
  }
  n_shown <- min(globalenv_n, n_total)
  genv_df <- genv_df[seq_len(n_shown), , drop = FALSE]
  if ("size" %in% names(genv_df)) genv_df$size <- .format_object_size(genv_df$size)
  genv_lines <- c(
    sprintf("Global environment [n = %d]:", n_total),
    utils::capture.output(print(genv_df, row.names = FALSE))
  )
  if (n_shown < n_total) {
    genv_lines <- c(genv_lines, sprintf(" ... and %d more (see x$globalenv)", n_total - n_shown))
  }

  att_df <- x$attachments
  attachments <- .resolve_field_selection(attachments, "sessionstate_attachments", NULL)
  att_cols <- .select_fields(names(att_df), attachments, "attachments")
  att_df <- att_df[, att_cols, drop = FALSE]
  att_lines <- c(
    sprintf("Attached environments [n = %d]:", nrow(att_df)),
    utils::capture.output(print(att_df, row.names = FALSE))
  )

  paste(
    c(
      platform_lines, "", machine_lines, "", git_lines, "", timing_lines, "", rng_lines, "",
      pkg_lines, "", genv_lines, "", att_lines
    ),
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
print.sessioncheck_sessionstate <- function(x, platform = NULL, machine = NULL, git = NULL, timing = NULL, rng = NULL, packages = NULL, globalenv = NULL, globalenv_n = NULL, attachments = NULL, ...) {
  cat(
    format(
      x, platform = platform, machine = machine, git = git, timing = timing, rng = rng,
      packages = packages, globalenv = globalenv, globalenv_n = globalenv_n, attachments = attachments, ...
    ),
    "\n"
  )
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


