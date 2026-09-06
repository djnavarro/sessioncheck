
# sessionstatediff display helpers ------

# renders a single display value, treating NA (from .diff_display_value())
# as an explicit "(NA)" rather than the bare string "NA", matching the
# "(unset)"/"(unknown)"-style placeholders used elsewhere in
# format.sessioncheck_sessionstate()
.na_display <- function(x) ifelse(is.na(x), "(NA)", x)

# renders one "record" section (platform/locale/matrix/document/machine/
# git/rng): a data frame with columns field/old/new/changed, as built by
# .diff_record(). When changed_only is TRUE, unchanged fields are omitted
# entirely, and a section with no changed fields collapses to a single
# "(no changes)" line
.render_record_section <- function(title, df, changed_only) {
  show_df <- if (changed_only) df[df$changed, , drop = FALSE] else df
  if (nrow(show_df) == 0L) {
    return(c(.rule(title), .bullet_line("(no changes)")))
  }
  lines <- vapply(
    seq_len(nrow(show_df)),
    function(i) {
      row <- show_df[i, ]
      if (isTRUE(row$changed)) {
        sprintf("%-20s%s -> %s", row$field, .na_display(row$old), .na_display(row$new))
      } else {
        sprintf("%-20s%s", row$field, .na_display(row$old))
      }
    },
    character(1L)
  )
  c(.rule(title), .bullet_line(lines))
}

# renders `timing`: always shown in full (see .diff_timing()'s docs for why
# it has no changed/unchanged concept to collapse)
.render_timing_section <- function(diff) {
  lines <- c(
    sprintf("%-22s%s", "captured at (old)", format(diff$captured_at_old, usetz = TRUE)),
    sprintf("%-22s%s", "captured at (new)", format(diff$captured_at_new, usetz = TRUE)),
    sprintf("%-22s%s", "wall clock elapsed", .format_duration(diff$wall_elapsed)),
    sprintf("%-22s%s", "session uptime delta", .format_duration(diff$uptime_elapsed))
  )
  c(.rule("Timing"), .bullet_line(lines))
}

# renders `libpaths`: a list(added, removed) rather than a data frame
.render_libpaths_section <- function(diff) {
  if (length(diff$added) == 0L && length(diff$removed) == 0L) {
    return(c(.rule("Library paths"), .bullet_line("(no changes)")))
  }
  lines <- character(0L)
  if (length(diff$added) > 0L) lines <- c(lines, "Added:", .bullet_line(diff$added))
  if (length(diff$removed) > 0L) lines <- c(lines, "Removed:", .bullet_line(diff$removed))
  c(.rule("Library paths"), lines)
}

# renders a keyed-table section (packages/globalenv/attachments): each of
# added/removed/modified is its own sub-block, omitted when empty;
# `modified` is NULL for attachments, which has no modified concept
.render_table_section <- function(title, added, removed, modified = NULL) {
  has_changes <- nrow(added) > 0L || nrow(removed) > 0L || (!is.null(modified) && nrow(modified) > 0L)
  if (!has_changes) {
    return(c(.rule(title), .bullet_line("(no changes)")))
  }
  lines <- character(0L)
  if (nrow(added) > 0L) {
    lines <- c(lines, sprintf("Added [n = %d]", nrow(added)), utils::capture.output(print(added, row.names = FALSE)))
  }
  if (nrow(removed) > 0L) {
    lines <- c(lines, sprintf("Removed [n = %d]", nrow(removed)), utils::capture.output(print(removed, row.names = FALSE)))
  }
  if (!is.null(modified) && nrow(modified) > 0L) {
    lines <- c(lines, sprintf("Modified [n = %d]", nrow(modified)), utils::capture.output(print(modified, row.names = FALSE)))
  }
  c(.rule(title), lines)
}

# sessionstatediff methods ------

#' @rdname display_methods
#' @exportS3Method base::format
format.sessioncheck_sessionstatediff <- function(x, changed_only = TRUE, ...) {
  sections <- list(
    .render_record_section("Platform", x$platform, changed_only),
    .render_record_section("Locale", x$locale, changed_only),
    .render_record_section("Matrix products", x$matrix, changed_only),
    .render_record_section("Document products", x$document, changed_only),
    .render_record_section("Machine", x$machine, changed_only),
    .render_record_section("Git", x$git, changed_only),
    .render_timing_section(x$timing),
    .render_record_section("RNG state", x$rng, changed_only),
    .render_libpaths_section(x$libpaths),
    .render_table_section("Packages", x$packages$added, x$packages$removed, x$packages$modified),
    .render_table_section("Global environment", x$globalenv$added, x$globalenv$removed, x$globalenv$modified),
    .render_table_section("Attached environments", x$attachments$added, x$attachments$removed)
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
print.sessioncheck_sessionstatediff <- function(x, changed_only = TRUE, ...) {
  cat(format(x, changed_only = changed_only, ...), "\n")
  invisible(x)
}
