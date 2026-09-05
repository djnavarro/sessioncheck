
# sessionstate display helpers ------

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

# sessionstate methods ------

#' @rdname display_methods
#' @exportS3Method base::format
format.sessioncheck_sessionstate <- function(x, platform = NULL, locale = NULL, matrix = NULL, document = NULL, machine = NULL, git = NULL, timing = NULL, rng = NULL, packages = NULL, globalenv = NULL, globalenv_n = NULL, attachments = NULL, ...) {
  p <- x$platform
  loc <- x$locale
  mx <- x$matrix
  doc <- x$document
  m <- x$machine
  g <- x$git
  t <- x$timing
  r <- x$rng

  platform_all <- c(
    version = .bullet_line(sprintf("%-16s%s", "version", p$version)),
    os      = .bullet_line(sprintf("%-16s%s", "os", p$os)),
    system  = .bullet_line(sprintf("%-16s%s", "system", p$system)),
    ui      = .bullet_line(sprintf("%-16s%s", "ui", p$ui)),
    tz      = .bullet_line(sprintf("%-16s%s", "tz", p$tz)),
    date    = .bullet_line(sprintf("%-16s%s", "date", p$date))
  )
  platform <- .resolve_field_selection(platform, "sessionstate_platform", NULL)
  platform_fields <- .select_fields(names(platform_all), platform, "platform")
  platform_lines <- c(.rule("Platform"), platform_all[platform_fields])

  locale_all <- c(
    language = .bullet_line(sprintf("%-16s%s", "language", if (is.na(loc$language)) "(unset)" else loc$language)),
    collate  = .bullet_line(sprintf("%-16s%s", "collate", if (is.na(loc$collate)) "(unknown)" else loc$collate)),
    ctype    = .bullet_line(sprintf("%-16s%s", "ctype", if (is.na(loc$ctype)) "(unknown)" else loc$ctype))
  )
  locale <- .resolve_field_selection(locale, "sessionstate_locale", NULL)
  locale_fields <- .select_fields(names(locale_all), locale, "locale")
  locale_lines <- c(.rule("Locale"), locale_all[locale_fields])

  matrix_all <- c(
    blas   = .bullet_line(sprintf("%-16s%s", "BLAS", mx$blas)),
    lapack = .bullet_line(sprintf("%-16s%s", "LAPACK", mx$lapack))
  )
  matrix <- .resolve_field_selection(matrix, "sessionstate_matrix", NULL)
  matrix_fields <- .select_fields(names(matrix_all), matrix, "matrix")
  matrix_lines <- c(.rule("Matrix products"), matrix_all[matrix_fields])

  document_all <- c(
    pandoc = .bullet_line(sprintf("%-16s%s", "pandoc", if (is.na(doc$pandoc)) "(not found)" else doc$pandoc)),
    quarto = .bullet_line(sprintf("%-16s%s", "quarto", if (is.na(doc$quarto)) "(not found)" else doc$quarto))
  )
  document <- .resolve_field_selection(document, "sessionstate_document", NULL)
  document_fields <- .select_fields(names(document_all), document, "document")
  document_lines <- c(.rule("Document products"), document_all[document_fields])

  machine_all <- c(
    # "hostname" and "working directory" are used as the display labels
    # here (rather than the "nodename"/"cwd" field names) since they're
    # the more widely understood terms; the underlying field names are
    # unchanged and still what `machine = ` selects by
    nodename = .bullet_line(sprintf("%-20s%s", "hostname", m$nodename)),
    user     = .bullet_line(sprintf("%-20s%s", "user", m$user)),
    cwd      = .bullet_line(sprintf("%-20s%s", "working directory", m$cwd))
  )
  machine <- .resolve_field_selection(machine, "sessionstate_machine", NULL)
  machine_fields <- .select_fields(names(machine_all), machine, "machine")
  machine_lines <- c(.rule("Machine"), machine_all[machine_fields])

  git_all <- c(
    # "commit sha" (rather than the bare "sha") to match the descriptive
    # style used elsewhere (e.g. "seed hash" under RNG state)
    sha   = .bullet_line(sprintf("%-16s%s", "commit sha", if (is.na(g$sha)) "(not a git repository)" else g$sha)),
    dirty = .bullet_line(sprintf("%-16s%s", "dirty", if (is.na(g$dirty)) "(unknown)" else g$dirty))
  )
  git <- .resolve_field_selection(git, "sessionstate_git", NULL)
  git_fields <- .select_fields(names(git_all), git, "git")
  git_lines <- c(.rule("Git"), git_all[git_fields])

  timing_all <- c(
    captured_at = .bullet_line(sprintf("%-25s%s", "captured at", format(t$captured_at, usetz = TRUE))),
    elapsed_sec = .bullet_line(sprintf("%-25s%s", "session runtime (sec)", t$elapsed_sec))
  )
  timing <- .resolve_field_selection(timing, "sessionstate_timing", NULL)
  timing_fields <- .select_fields(names(timing_all), timing, "timing")
  timing_lines <- c(.rule("Timing"), timing_all[timing_fields])

  rng_all <- c(
    kind        = .bullet_line(sprintf("%-16s%s", "kind", r$kind)),
    normal_kind = .bullet_line(sprintf("%-16s%s", "normal kind", r$normal_kind)),
    sample_kind = .bullet_line(sprintf("%-16s%s", "sample kind", r$sample_kind)),
    seed_hash   = .bullet_line(sprintf("%-16s%s", "seed hash", if (is.na(r$seed_hash)) "(not set)" else r$seed_hash))
  )
  rng <- .resolve_field_selection(rng, "sessionstate_rng", NULL)
  rng_fields <- .select_fields(names(rng_all), rng, "rng")
  rng_lines <- c(.rule("RNG state"), rng_all[rng_fields])

  libpaths <- x$libpaths
  libpaths_lines <- c(
    .rule(sprintf("Library paths [n = %d]", length(libpaths))),
    .bullet_line(libpaths)
  )

  pkg_df <- x$packages
  packages <- .resolve_field_selection(
    packages, "sessionstate_packages",
    c("package", "attached", "loaded_version", "source")
  )
  pkg_cols <- .select_fields(names(pkg_df), packages, "packages")
  pkg_df <- pkg_df[, pkg_cols, drop = FALSE]
  if ("attached" %in% names(pkg_df)) pkg_df$attached <- ifelse(pkg_df$attached, "*", " ")
  pkg_lines <- c(
    .rule(sprintf("Packages [n = %d] (attached + loaded via namespace)", nrow(pkg_df))),
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
    .rule(sprintf("Global environment [n = %d]", n_total)),
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
    .rule(sprintf("Attached environments [n = %d]", nrow(att_df))),
    utils::capture.output(print(att_df, row.names = FALSE))
  )

  sections <- list(
    platform_lines, locale_lines, matrix_lines, document_lines, machine_lines, git_lines,
    timing_lines, rng_lines, libpaths_lines, pkg_lines, genv_lines, att_lines
  )
  paste(
    unlist(mapply(
      function(sec, i) if (i == 1L) sec else c("", sec),
      sections, seq_along(sections),
      SIMPLIFY = FALSE
    )),
    collapse = "\n"
  )
}

#' @rdname display_methods
#' @exportS3Method base::print
print.sessioncheck_sessionstate <- function(x, platform = NULL, locale = NULL, matrix = NULL, document = NULL, machine = NULL, git = NULL, timing = NULL, rng = NULL, packages = NULL, globalenv = NULL, globalenv_n = NULL, attachments = NULL, ...) {
  cat(
    format(
      x, platform = platform, locale = locale, matrix = matrix, document = document, machine = machine,
      git = git, timing = timing, rng = rng, packages = packages, globalenv = globalenv,
      globalenv_n = globalenv_n, attachments = attachments, ...
    ),
    "\n"
  )
  invisible(x)
}

#' @rdname coercion_methods
#' @exportS3Method base::as.data.frame
as.data.frame.sessioncheck_sessionstate <- function(x, row.names = NULL, optional = FALSE, which = "packages", ...) {
  which <- match.arg(which, c("packages", "globalenv", "attachments"))
  x[[which]]
}
