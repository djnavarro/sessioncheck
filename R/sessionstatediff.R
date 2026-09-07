
#' @title Compare two session state snapshots
#'
#' @description
#' `compare_sessionstates()` reports how two [sessionstate()] snapshots
#' differ. This is the comparison counterpart to `sessionstate()`'s
#' point-in-time capture: take a snapshot with `sessionstate()`, do some
#' work, take a second snapshot, and pass both to `compare_sessionstates()`
#' to see what changed.
#'
#' @param old A `sessioncheck_sessionstate` object (from [sessionstate()]),
#' treated as the baseline.
#' @param new A `sessioncheck_sessionstate` object (from [sessionstate()]),
#' treated as the later snapshot.
#'
#' @returns An object of class `sessioncheck_sessionstatediff`, a list with
#' the same 12 elements as [sessionstate()] (`platform`, `locale`, `matrix`,
#' `document`, `machine`, `git`, `timing`, `rng`, `libpaths`, `packages`,
#' `globalenv`, `attachments`), each holding a diff rather than a raw
#' snapshot. See Details for the shape of each element.
#'
#' @details
#' `sessionstate()`'s 12 elements fall into four shapes, and each is
#' diffed differently:
#'
#' - **Record** elements (`platform`, `locale`, `matrix`, `document`,
#'   `machine`, `git`, `rng`) are named lists of scalar fields. Each is
#'   diffed field-by-field via [identical()], producing a data frame with
#'   columns `field`, `old`, `new`, and `changed`.
#' - **`timing`** is a record element, but `captured_at`/`elapsed_sec`
#'   necessarily differ between any two calls to `sessionstate()`, so
#'   flagging them as "changed" the way other fields are would be noise
#'   every time. Instead `timing` reports `captured_at_old`,
#'   `captured_at_new`, `wall_elapsed` (the difference between the two
#'   capture times, in seconds), and `uptime_elapsed` (the difference
#'   between the two `elapsed_sec` values). The two are usually equal; a
#'   mismatch (e.g. the machine slept between snapshots) is itself worth
#'   noticing.
#' - **`libpaths`** is a plain character vector, diffed via [setdiff()] in
#'   both directions: `list(added = ..., removed = ...)`. Paths present in
#'   both snapshots but reordered are not reported as a change.
#' - **Keyed table** elements (`packages`, `globalenv`, `attachments`) are
#'   data frames. Each is diffed into `list(added = <data frame>, removed =
#'   <data frame>, modified = <data frame>)` (`attachments` has no
#'   `modified` table -- a `type` change for the same search-path entry
#'   isn't a realistic scenario). `added`/`removed` are rows present in only
#'   one snapshot (keyed by `package`/`name`/`name` respectively);
#'   `modified` covers rows present in both where a tracked column
#'   differs, in a long format with one row per changed field
#'   (`package`/`name`, `field`, `old`, `new` for `packages`; see below for
#'   `globalenv`'s slightly different `modified` columns).
#'
#' Keyed-table diffing assumes each key (`package` for `packages`; `name`
#' for `globalenv`/`attachments`) appears at most once per snapshot -- true
#' for anything [sessionstate()] itself produces. `old`/`new` are checked
#' for this on every keyed-table section, and `compare_sessionstates()`
#' errors with an informative message identifying the offending snapshot,
#' section, and duplicated value(s) if it doesn't hold (e.g. for a
#' hand-constructed or corrupted `sessioncheck_sessionstate` object).
#'
#' Keyed-table diffing is purely key-based: it has no way to detect a
#' rename. A package or global environment object that is renamed but
#' otherwise unchanged between `old` and `new` (e.g. `pkgA` reinstalled
#' under a new name, or `x` renamed to `y` via `assign()`) is reported as
#' one `removed` row (the old key) plus one `added` row (the new key),
#' never as a single "renamed" entry -- there is no general way to tell a
#' rename apart from an unrelated removal-plus-addition that happens to
#' involve similar values. This is inherent to any key-based diff, not a
#' bug to be fixed.
#'
#' `globalenv`'s `modified` table relies on the `hash` column
#' `sessionstate()` records for each object (an MD5 fingerprint of the
#' object's serialized value). When both snapshots have a non-`NA` hash for
#' an object, a hash mismatch is what marks it modified (`verified = TRUE`);
#' when either side's hash is `NA` (the object couldn't be serialized --
#' see [sessionstate()]'s Global environment section), the comparison falls
#' back to `class`/`size` only, and the row is marked `verified = FALSE` to
#' be explicit that a value change could have gone undetected. If an
#' object's hash goes from `NA` to non-`NA` or vice versa between snapshots
#' -- e.g. it shrank below `sessionstate_hash_max_size`, or started/stopped
#' failing to serialize -- that is reported as its own `"hash"` row (with
#' `verified = FALSE`), even when `class`/`size` are unchanged, since the
#' object's verifiability itself changed.
#'
#' `verified = TRUE` means the hash comparison itself is trustworthy as far
#' as R's serialization can see -- it does not mean every possible kind of
#' change is detectable. For an object that is a thin wrapper around state
#' living outside R's memory (e.g. a database connection, an Arrow
#' `Table`/`RecordBatchReader`, a magick image; see [sessionstate()]'s
#' Global environment section), `hash` fingerprints the R-level wrapper,
#' typically a fixed placeholder for the underlying pointer, not the
#' external data. A `verified = TRUE`, unchanged-hash result for such an
#' object means "unchanged as far as R can observe", not "definitely
#' unchanged" -- the external state could have changed without the R-level
#' object being reassigned. This is inherent to hashing via R-level
#' serialization, not a defect in the comparison logic.
#'
#' A related, opposite-direction limitation: [serialize()]'s traversal of
#' an environment's bindings is order-dependent, not purely
#' content-dependent (see [sessionstate()]'s Global environment section).
#' For an object that is, or contains, an environment -- an R6 object, a
#' closure, a reference class instance -- this can produce a hash mismatch,
#' and so a false `modified` row here, even when the object's actual
#' contents are unchanged. `verified = TRUE` does not rule this out.
#'
#' A warning is issued if `new$timing$captured_at` is earlier than
#' `old$timing$captured_at`, since that usually means the two arguments
#' were passed in the wrong order; the comparison is still computed either
#' way.
#'
#' @examples
#' baseline <- sessionstate()
#' # assign() into .GlobalEnv explicitly (rather than `x <- 1:10`) so this
#' # example is correct wherever it's evaluated: sessionstate() specifically
#' # inspects .GlobalEnv, but some example/doc runners (e.g. pkgdown) do not
#' # evaluate example code there
#' assign("sessioncheck_example_obj", 1:10, envir = .GlobalEnv)
#' current <- sessionstate()
#' compare_sessionstates(baseline, current)
#' rm(sessioncheck_example_obj, envir = .GlobalEnv)
#'
#' @seealso [sessionstate()]
#'
#' @export
compare_sessionstates <- function(old, new) {
  .validate_sessionstate(old, "old")
  .validate_sessionstate(new, "new")

  if (new$timing$captured_at < old$timing$captured_at) {
    warning(
      "`new` was captured before `old`; check whether the arguments are in the intended order",
      call. = FALSE
    )
  }

  new_sessionstatediff(
    platform    = .diff_record(old$platform, new$platform),
    locale      = .diff_record(old$locale, new$locale),
    matrix      = .diff_record(old$matrix, new$matrix),
    document    = .diff_record(old$document, new$document),
    machine     = .diff_record(old$machine, new$machine),
    git         = .diff_record(old$git, new$git),
    timing      = .diff_timing(old$timing, new$timing),
    rng         = .diff_record(old$rng, new$rng),
    libpaths    = .diff_vector(old$libpaths, new$libpaths),
    packages    = .diff_packages(old$packages, new$packages),
    globalenv   = .diff_globalenv(old$globalenv, new$globalenv),
    attachments = .diff_attachments(old$attachments, new$attachments)
  )
}

# sessionstate diff helpers ------

# renders a single scalar field value for display in a diff table; NULL/NA
# both collapse to NA_character_ (rather than the string "NA") so
# .na_display() (in sessionstatediff-format.R) can special-case them
# uniformly, and multi-element values (there are none among current record
# fields, but this stays defensive against future ones) are comma-joined
# rather than erroring
.diff_display_value <- function(v) {
  if (is.null(v) || (length(v) == 1L && is.na(v))) return(NA_character_)
  if (length(v) == 1L) return(as.character(v))
  paste(format(v), collapse = ", ")
}

# generic diff for a "record" section: a named list of scalar fields
# (platform, locale, matrix, document, machine, git, rng). Compares by
# identical() rather than the display strings, so e.g. numeric vs. character
# "same-looking" values are not treated as equal
.diff_record <- function(old, new) {
  fields <- union(names(old), names(new))
  changed <- vapply(fields, function(f) !identical(old[[f]], new[[f]]), logical(1L))
  old_chr <- vapply(fields, function(f) .diff_display_value(old[[f]]), character(1L))
  new_chr <- vapply(fields, function(f) .diff_display_value(new[[f]]), character(1L))
  df <- data.frame(
    field = fields, old = old_chr, new = new_chr, changed = unname(changed),
    stringsAsFactors = FALSE
  )
  rownames(df) <- NULL
  df
}

# bespoke diff for `timing`: captured_at/elapsed_sec differ by construction
# between any two sessionstate() calls, so there is no "changed" concept
# here -- just the two raw values and the two derived deltas (see
# compare_sessionstates()'s @details for why they might disagree)
.diff_timing <- function(old, new) {
  list(
    captured_at_old = old$captured_at,
    captured_at_new = new$captured_at,
    wall_elapsed    = as.numeric(difftime(new$captured_at, old$captured_at, units = "secs")),
    uptime_elapsed  = new$elapsed_sec - old$elapsed_sec
  )
}

# diff for `libpaths`: a bare character vector, not a keyed table. Order
# changes are deliberately not reported -- the same paths being searched in
# a different order is not treated as a change
.diff_vector <- function(old, new) {
  list(added = setdiff(new, old), removed = setdiff(old, new))
}

# shared added/removed logic for the three keyed-table sections
# (packages/globalenv/attachments), keyed by `key` (package/name/name
# respectively). `section` names the calling section (e.g. "packages")
# for .validate_unique_key()'s error message. Validating uniqueness here,
# before the added/removed split, means every downstream keyed-table
# consumer (.diff_modified_table(), .diff_globalenv()'s own inline
# modified logic) is protected too, since each of .diff_packages()/
# .diff_attachments()/.diff_globalenv() calls this first
.diff_table_added_removed <- function(old_df, new_df, key, section) {
  .validate_unique_key(old_df, key, section, "old")
  .validate_unique_key(new_df, key, section, "new")
  added <- new_df[!(new_df[[key]] %in% old_df[[key]]), , drop = FALSE]
  removed <- old_df[!(old_df[[key]] %in% new_df[[key]]), , drop = FALSE]
  rownames(added) <- NULL
  rownames(removed) <- NULL
  list(added = added, removed = removed)
}

# builds the long-format "modified" table used by .diff_packages(): one row
# per (key, changed field) pair, comparing `compare_cols` via identical().
# .diff_globalenv() has its own bespoke, hash-aware implementation instead
# (see below) rather than calling this one, since its notion of "changed"
# depends on hash verifiability rather than a flat list of compare_cols
.diff_modified_table <- function(old_df, new_df, key, compare_cols) {
  common <- intersect(old_df[[key]], new_df[[key]])
  rows <- lapply(common, function(kk) {
    o <- old_df[old_df[[key]] == kk, , drop = FALSE]
    n <- new_df[new_df[[key]] == kk, , drop = FALSE]
    changed_cols <- compare_cols[vapply(compare_cols, function(cc) !identical(o[[cc]], n[[cc]]), logical(1L))]
    if (length(changed_cols) == 0L) return(NULL)
    data.frame(
      key = kk,
      field = changed_cols,
      old = vapply(changed_cols, function(cc) .diff_display_value(o[[cc]]), character(1L)),
      new = vapply(changed_cols, function(cc) .diff_display_value(n[[cc]]), character(1L)),
      stringsAsFactors = FALSE
    )
  })
  rows <- rows[!vapply(rows, is.null, logical(1L))]
  if (length(rows) == 0L) {
    out <- data.frame(key = character(), field = character(), old = character(), new = character(), stringsAsFactors = FALSE)
  } else {
    out <- do.call(rbind, rows)
    rownames(out) <- NULL
  }
  names(out)[names(out) == "key"] <- key
  out
}

.diff_packages <- function(old, new) {
  ar <- .diff_table_added_removed(old, new, "package", "packages")
  modified <- .diff_modified_table(
    old, new, "package",
    compare_cols = c("attached", "ondisk_version", "loaded_version", "source")
  )
  list(added = ar$added, removed = ar$removed, modified = modified)
}

.diff_attachments <- function(old, new) {
  ar <- .diff_table_added_removed(old, new, "name", "attachments")
  list(added = ar$added, removed = ar$removed)
}

# globalenv's "modified" logic differs from .diff_modified_table()'s generic
# shape because the notion of "changed" depends on whether a trustworthy
# `hash` is available on both sides. When it is, a hash mismatch is
# authoritative: if the hash is unchanged, serialize() must have produced
# byte-identical output, so class/size cannot have changed either and no
# further comparison is needed; if the hash *did* change, a "hash" field
# row is always emitted (the definitive evidence something changed), plus
# "class"/"size" rows for whichever of those also happened to differ. When
# a trustworthy hash isn't available on both sides (an object that failed
# to serialize -- see .hash_object()), the comparison falls back to
# class/size only, and every row is marked verified = FALSE so that
# fallback stays visible rather than silently indistinguishable from a
# hash-verified result. A hash *becoming* computable (NA -> a value) or
# *ceasing* to be computable (a value -> NA) is itself surfaced as a "hash"
# field row -- even when class/size didn't change -- since it means the
# object's verifiability changed (e.g. it shrank below
# `sessionstate_hash_max_size`, or started/stopped failing to serialize);
# silently reporting "no change" in that situation would hide the fact that
# hash-based verification is no longer (or is now) possible for this
# object. This only applies when both snapshots actually have a `hash`
# column -- an old-format snapshot missing the column entirely is a schema
# difference, not an availability change, and keeps falling back to
# class/size unmarked. The resulting shape -- one row per (name, changed
# field), in `field`/`old`/`new` form -- deliberately matches
# .diff_packages()'s modified table, so both the print method and
# as.data.frame() can treat "modified" uniformly across sections
.diff_globalenv <- function(old, new) {
  ar <- .diff_table_added_removed(old, new, "name", "globalenv")
  common <- intersect(old$name, new$name)
  rows <- lapply(common, function(nm) {
    o <- old[old$name == nm, , drop = FALSE]
    n <- new[new$name == nm, , drop = FALSE]
    o_has_hash <- "hash" %in% names(o)
    n_has_hash <- "hash" %in% names(n)
    hash_verifiable <- o_has_hash && n_has_hash && !is.na(o$hash) && !is.na(n$hash)
    hash_availability_changed <- o_has_hash && n_has_hash &&
      (is.na(o$hash) != is.na(n$hash))
    if (hash_verifiable) {
      if (identical(o$hash, n$hash)) return(NULL)
      fields <- "hash"
      if (!identical(o$class, n$class)) fields <- c(fields, "class")
      if (!identical(o$size, n$size)) fields <- c(fields, "size")
    } else {
      class_changed <- !identical(o$class, n$class)
      size_changed <- !identical(o$size, n$size)
      if (!class_changed && !size_changed && !hash_availability_changed) return(NULL)
      fields <- c(
        if (hash_availability_changed) "hash",
        if (class_changed) "class",
        if (size_changed) "size"
      )
    }
    data.frame(
      name = nm,
      field = fields,
      old = vapply(fields, function(f) .diff_display_value(o[[f]]), character(1L)),
      new = vapply(fields, function(f) .diff_display_value(n[[f]]), character(1L)),
      verified = hash_verifiable,
      stringsAsFactors = FALSE
    )
  })
  rows <- rows[!vapply(rows, is.null, logical(1L))]
  modified <- if (length(rows) == 0L) {
    data.frame(
      name = character(), field = character(), old = character(), new = character(),
      verified = logical(), stringsAsFactors = FALSE
    )
  } else {
    out <- do.call(rbind, rows)
    rownames(out) <- NULL
    out
  }
  list(added = ar$added, removed = ar$removed, modified = modified)
}
