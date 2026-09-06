
# fixtures ------

.mock_sessionstate <- function(overrides = list()) {
  base <- list(
    platform = list(version = "R 1.0", os = "TestOS", system = "x86_64", ui = "unknown", tz = "UTC", date = "2026-01-01"),
    locale = list(language = NA_character_, collate = "C", ctype = "C"),
    matrix = list(blas = "libblas", lapack = "liblapack"),
    document = list(pandoc = NA_character_, quarto = NA_character_),
    machine = list(nodename = "host", user = "danielle", cwd = "/tmp/proj"),
    git = list(sha = "abc123", dirty = FALSE),
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"), elapsed_sec = 1),
    rng = list(kind = "Mersenne-Twister", normal_kind = "Inversion", sample_kind = "Rejection", seed_hash = "h1"),
    libpaths = c("/lib/a", "/lib/b"),
    packages = data.frame(
      package = c("base", "pkgA"), attached = c(TRUE, TRUE),
      ondisk_version = c("1.0", "1.0"), loaded_version = c("1.0", "1.0"),
      source = c("base", "CRAN"), stringsAsFactors = FALSE
    ),
    globalenv = data.frame(
      name = c("x", "y"), class = c("numeric", "character"), size = c(56, 48),
      hash = c("hx1", "hy1"), stringsAsFactors = FALSE
    ),
    attachments = data.frame(name = c(".GlobalEnv", "package:base"), type = c("other", "package"), stringsAsFactors = FALSE)
  )
  # deliberately not utils::modifyList(): it recurses into data frames
  # (they're lists too) and merges them column-by-column, which silently
  # breaks whenever an override table has a different number of rows than
  # the base fixture. Overrides here are always meant to fully replace a
  # top-level section, so a plain loop is both simpler and correct.
  merged <- base
  for (nm in names(overrides)) merged[[nm]] <- overrides[[nm]]
  structure(merged, class = "sessioncheck_sessionstate")
}

# .diff_record() ------

test_that(".diff_record() flags only fields that differ", {
  old <- list(a = "x", b = "y", c = 1)
  new <- list(a = "x", b = "z", c = 1)
  df <- .diff_record(old, new)
  expect_named(df, c("field", "old", "new", "changed"))
  expect_identical(df$changed, c(FALSE, TRUE, FALSE))
  expect_identical(df$new[df$field == "b"], "z")
})

test_that(".diff_display_value() comma-joins a multi-element value", {
  expect_identical(.diff_display_value(c(1, 2, 3)), "1, 2, 3")
})

test_that(".diff_record() uses identical(), not string comparison", {
  old <- list(a = 1L)
  new <- list(a = "1")
  df <- .diff_record(old, new)
  expect_true(df$changed)
})

test_that(".diff_record() displays NA as NA_character_ rather than the value itself", {
  old <- list(a = NA_character_)
  new <- list(a = "value")
  df <- .diff_record(old, new)
  expect_true(is.na(df$old[df$field == "a"]))
  expect_identical(df$new[df$field == "a"], "value")
})

# .diff_timing() ------

test_that(".diff_timing() reports both timestamps and both deltas", {
  old <- list(captured_at = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"), elapsed_sec = 1)
  new <- list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11)
  diff <- .diff_timing(old, new)
  expect_equal(diff$wall_elapsed, 10)
  expect_equal(diff$uptime_elapsed, 10)
})

test_that(".diff_timing() surfaces a mismatch between wall-clock and uptime deltas", {
  old <- list(captured_at = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"), elapsed_sec = 1)
  new <- list(captured_at = as.POSIXct("2026-01-01 00:01:00", tz = "UTC"), elapsed_sec = 11)
  diff <- .diff_timing(old, new)
  expect_equal(diff$wall_elapsed, 60)
  expect_equal(diff$uptime_elapsed, 10)
})

# .diff_vector() ------

test_that(".diff_vector() reports added/removed but ignores reordering", {
  diff <- .diff_vector(c("/a", "/b"), c("/b", "/a"))
  expect_length(diff$added, 0L)
  expect_length(diff$removed, 0L)

  diff2 <- .diff_vector(c("/a", "/b"), c("/b", "/c"))
  expect_identical(diff2$added, "/c")
  expect_identical(diff2$removed, "/a")
})

# .validate_unique_key() ------

test_that(".validate_unique_key() is silent when keys are unique", {
  df <- data.frame(package = c("a", "b"), stringsAsFactors = FALSE)
  expect_silent(.validate_unique_key(df, "package", "packages", "old"))
})

test_that(".validate_unique_key() errors informatively on duplicate keys", {
  df <- data.frame(package = c("a", "a", "b"), stringsAsFactors = FALSE)
  expect_error(
    .validate_unique_key(df, "package", "packages", "old"),
    "`old`'s `packages` table has duplicate `package` value\\(s\\): a"
  )
})

# .diff_table_added_removed() / duplicate-key propagation ------

test_that(".diff_table_added_removed() rejects duplicate keys in old_df", {
  old <- data.frame(package = c("a", "a"), stringsAsFactors = FALSE)
  new <- data.frame(package = "a", stringsAsFactors = FALSE)
  expect_error(.diff_table_added_removed(old, new, "package", "packages"), "duplicate")
})

test_that(".diff_table_added_removed() rejects duplicate keys in new_df", {
  old <- data.frame(package = "a", stringsAsFactors = FALSE)
  new <- data.frame(package = c("a", "a"), stringsAsFactors = FALSE)
  expect_error(.diff_table_added_removed(old, new, "package", "packages"), "duplicate")
})

test_that(".diff_packages() rejects duplicate package keys", {
  old <- data.frame(
    package = c("pkgA", "pkgA"), attached = TRUE, ondisk_version = "1.0",
    loaded_version = "1.0", source = "CRAN", stringsAsFactors = FALSE
  )
  new <- data.frame(
    package = "pkgA", attached = TRUE, ondisk_version = "1.0",
    loaded_version = "1.0", source = "CRAN", stringsAsFactors = FALSE
  )
  expect_error(.diff_packages(old, new), "`old`'s `packages` table has duplicate")
})

test_that(".diff_attachments() rejects duplicate name keys", {
  old <- data.frame(name = c("a", "a"), type = "package", stringsAsFactors = FALSE)
  new <- data.frame(name = "a", type = "package", stringsAsFactors = FALSE)
  expect_error(.diff_attachments(old, new), "`old`'s `attachments` table has duplicate")
})

test_that(".diff_globalenv() rejects duplicate name keys", {
  old <- data.frame(
    name = c("x", "x"), class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE
  )
  new <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  expect_error(.diff_globalenv(old, new), "`old`'s `globalenv` table has duplicate")
})

test_that("compare_sessionstates() rejects duplicate keys end to end", {
  old <- .mock_sessionstate(list(
    packages = data.frame(
      package = c("base", "base"), attached = TRUE, ondisk_version = "1.0",
      loaded_version = "1.0", source = "base", stringsAsFactors = FALSE
    )
  ))
  new <- .mock_sessionstate()
  expect_error(compare_sessionstates(old, new), "duplicate")
})

# .diff_packages() ------

test_that(".diff_packages() detects added, removed, and modified packages", {
  old <- data.frame(
    package = c("base", "pkgA", "pkgB"), attached = c(TRUE, TRUE, FALSE),
    ondisk_version = c("1.0", "1.0", "2.0"), loaded_version = c("1.0", "1.0", "2.0"),
    source = c("base", "CRAN", "CRAN"), stringsAsFactors = FALSE
  )
  new <- data.frame(
    package = c("base", "pkgA", "pkgC"), attached = c(TRUE, FALSE, TRUE),
    ondisk_version = c("1.0", "1.1", "1.0"), loaded_version = c("1.0", "1.1", "1.0"),
    source = c("base", "CRAN", "CRAN"), stringsAsFactors = FALSE
  )
  diff <- .diff_packages(old, new)
  expect_identical(diff$added$package, "pkgC")
  expect_identical(diff$removed$package, "pkgB")
  expect_true("pkgA" %in% diff$modified$package)
  expect_true(all(c("attached", "ondisk_version", "loaded_version") %in% diff$modified$field[diff$modified$package == "pkgA"]))
  expect_false("base" %in% diff$modified$package)
})

test_that(".diff_packages() modified table is empty (not erroring) when nothing changed", {
  df <- data.frame(
    package = "pkgA", attached = TRUE, ondisk_version = "1.0", loaded_version = "1.0",
    source = "CRAN", stringsAsFactors = FALSE
  )
  diff <- .diff_packages(df, df)
  expect_identical(nrow(diff$added), 0L)
  expect_identical(nrow(diff$removed), 0L)
  expect_identical(nrow(diff$modified), 0L)
})

# .diff_attachments() ------

test_that(".diff_attachments() reports only added/removed", {
  old <- data.frame(name = c("a", "b"), type = c("package", "other"), stringsAsFactors = FALSE)
  new <- data.frame(name = c("a", "c"), type = c("package", "other"), stringsAsFactors = FALSE)
  diff <- .diff_attachments(old, new)
  expect_identical(diff$added$name, "c")
  expect_identical(diff$removed$name, "b")
  expect_null(diff$modified)
})

# .diff_globalenv() ------

test_that(".diff_globalenv() flags a hash mismatch as verified modification", {
  old <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "numeric", size = 100, hash = "h2", stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 1L)
  expect_true(diff$modified$verified)
})

test_that(".diff_globalenv() falls back to class/size and marks unverified when a hash is NA", {
  old <- data.frame(name = "x", class = "numeric", size = 100, hash = NA_character_, stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "numeric", size = 200, hash = NA_character_, stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 1L)
  expect_false(diff$modified$verified)
})

test_that(".diff_globalenv() with an unverifiable hash and no class/size change is not modified", {
  old <- data.frame(name = "x", class = "numeric", size = 100, hash = NA_character_, stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "numeric", size = 100, hash = NA_character_, stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 0L)
})

test_that(".diff_globalenv() reports class and size fields alongside a verified hash change", {
  old <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "character", size = 200, hash = "h2", stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 3L)
  expect_setequal(diff$modified$field, c("hash", "class", "size"))
  expect_true(all(diff$modified$verified))
})

test_that(".diff_globalenv() treats an unchanged hash as no modification", {
  old <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 0L)
})

test_that(".diff_globalenv() falls back to class/size (without erroring) when a hash column is entirely missing", {
  old <- data.frame(name = "x", class = "numeric", size = 100, stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 0L)

  new_bigger <- data.frame(name = "x", class = "numeric", size = 200, hash = "h1", stringsAsFactors = FALSE)
  diff2 <- .diff_globalenv(old, new_bigger)
  expect_identical(nrow(diff2$modified), 1L)
  expect_identical(diff2$modified$field, "size")
  expect_false(diff2$modified$verified)
})

test_that(".diff_globalenv() reports added/removed objects", {
  old <- data.frame(name = "x", class = "numeric", size = 1, hash = "h1", stringsAsFactors = FALSE)
  new <- data.frame(name = "y", class = "numeric", size = 1, hash = "h2", stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(diff$added$name, "y")
  expect_identical(diff$removed$name, "x")
})

# compare_sessionstates() ------

test_that("compare_sessionstates() validates its arguments", {
  x <- .mock_sessionstate()
  expect_error(compare_sessionstates(list(), x), "must be an object of class 'sessioncheck_sessionstate'")
  expect_error(compare_sessionstates(x, list()), "must be an object of class 'sessioncheck_sessionstate'")
})

test_that("compare_sessionstates() warns when new looks earlier than old", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2025-01-01", tz = "UTC"), elapsed_sec = 1
  )))
  expect_warning(compare_sessionstates(old, new), "captured before")
})

test_that("compare_sessionstates() does not warn for forward-in-time snapshots", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  expect_no_warning(compare_sessionstates(old, new))
})

test_that("compare_sessionstates() returns a well-formed sessioncheck_sessionstatediff object", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    machine = list(nodename = "host", user = "danielle", cwd = "/tmp/other")
  ))
  diff <- compare_sessionstates(old, new)
  expect_s3_class(diff, "sessioncheck_sessionstatediff")
  expect_named(
    diff,
    c("platform", "locale", "matrix", "document", "machine", "git", "timing", "rng", "libpaths", "packages", "globalenv", "attachments")
  )
  expect_true(diff$machine$changed[diff$machine$field == "cwd"])
  expect_false(any(diff$platform$changed))
})

test_that("compare_sessionstates() integrates with real sessionstate() snapshots", {
  old <- sessionstate()
  assign("sc_test_diff_obj", 1:10, envir = .GlobalEnv)
  on.exit(rm(sc_test_diff_obj, envir = .GlobalEnv), add = TRUE)
  new <- sessionstate()

  diff <- compare_sessionstates(old, new)
  expect_s3_class(diff, "sessioncheck_sessionstatediff")
  expect_true("sc_test_diff_obj" %in% diff$globalenv$added$name)
})

# format/print methods ------

test_that("format.sessioncheck_sessionstatediff() collapses unchanged sections by default", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "\\(no changes\\)", fixed = FALSE)
})

test_that("format.sessioncheck_sessionstatediff() shows changed fields with old -> new", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    machine = list(nodename = "host", user = "danielle", cwd = "/tmp/other")
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "/tmp/proj -> /tmp/other", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() honors sessionstatediff_changed_only set via options(sessioncheck = ...)", {
  old_opt <- options(sessioncheck = list(sessionstatediff_changed_only = FALSE))
  on.exit(options(old_opt), add = TRUE)
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "TestOS", fixed = TRUE)
})

test_that("an explicit changed_only argument overrides options(sessioncheck = ...)", {
  old_opt <- options(sessioncheck = list(sessionstatediff_changed_only = FALSE))
  on.exit(options(old_opt), add = TRUE)
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff, changed_only = TRUE)
  expect_no_match(txt, "TestOS", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() with changed_only = FALSE shows unchanged fields too", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff, changed_only = FALSE)
  expect_match(txt, "TestOS", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() always reports timing in full", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "wall clock elapsed", fixed = TRUE)
  expect_match(txt, "session uptime delta", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() hides wide packages columns on added/removed by default", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = data.frame(
      package = c("base", "pkgA", "pkgC"), attached = c(TRUE, TRUE, TRUE),
      ondisk_version = c("1.0", "1.0", "1.0"), loaded_version = c("1.0", "1.0", "1.0"),
      ondisk_path = c("/lib/base", "/lib/pkgA", "/lib/pkgC"),
      source = c("base", "CRAN", "CRAN"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_no_match(txt, "ondisk_path", fixed = TRUE)
  expect_match(txt, "pkgC", fixed = TRUE)
})

test_that("an explicit packages argument selects added/removed columns for the diff", {
  pkgs_with_path <- function(pkgs) {
    data.frame(
      package = pkgs, attached = TRUE, ondisk_version = "1.0", loaded_version = "1.0",
      ondisk_path = paste0("/lib/", pkgs), source = "CRAN", stringsAsFactors = FALSE
    )
  }
  old <- .mock_sessionstate(list(packages = pkgs_with_path(c("base", "pkgA"))))
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = pkgs_with_path(c("base", "pkgC"))
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff, packages = c("package", "ondisk_path"))
  expect_match(txt, "ondisk_path", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() hides globalenv hash column on added/removed by default", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    globalenv = data.frame(
      name = c("x", "y", "z"), class = c("numeric", "character", "list"), size = c(56, 48, 10),
      hash = c("hx1", "hy1", "hz1-should-not-print"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_no_match(txt, "hz1-should-not-print", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() truncates added/removed/modified blocks at max_rows", {
  old <- .mock_sessionstate(list(
    packages = data.frame(
      package = "base", attached = TRUE, ondisk_version = "1.0", loaded_version = "1.0",
      source = "base", stringsAsFactors = FALSE
    )
  ))
  new_pkgs <- data.frame(
    package = c("base", paste0("pkg", 1:5)), attached = TRUE,
    ondisk_version = "1.0", loaded_version = "1.0", source = "CRAN", stringsAsFactors = FALSE
  )
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = new_pkgs
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff, max_rows = 2)
  expect_match(txt, "Added \\[n = 5\\]", fixed = FALSE)
  expect_match(txt, "\\.\\.\\. and 3 more", fixed = FALSE)
  expect_no_match(txt, "pkg4", fixed = TRUE)
  expect_no_match(txt, "pkg5", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() honors sessionstatediff_max_rows/packages/globalenv set via options(sessioncheck = ...)", {
  old_opt <- options(sessioncheck = list(
    sessionstatediff_max_rows = 1,
    sessionstatediff_packages = c("package", "ondisk_path")
  ))
  on.exit(options(old_opt), add = TRUE)
  old_pkgs <- data.frame(
    package = "base", attached = TRUE, ondisk_version = "1.0", loaded_version = "1.0",
    ondisk_path = "/lib/base", source = "base", stringsAsFactors = FALSE
  )
  old <- .mock_sessionstate(list(packages = old_pkgs))
  new_pkgs <- data.frame(
    package = c("base", "pkgA", "pkgB"), attached = TRUE, ondisk_version = "1.0",
    loaded_version = "1.0", ondisk_path = c("/lib/base", "/lib/pkgA", "/lib/pkgB"),
    source = "CRAN", stringsAsFactors = FALSE
  )
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = new_pkgs
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "ondisk_path", fixed = TRUE)
  expect_match(txt, "\\.\\.\\. and 1 more", fixed = FALSE)
})

test_that("explicit packages/max_rows arguments override options(sessioncheck = ...)", {
  old_opt <- options(sessioncheck = list(sessionstatediff_max_rows = 1))
  on.exit(options(old_opt), add = TRUE)
  old <- .mock_sessionstate()
  new_pkgs <- data.frame(
    package = c("base", "pkgA", "pkgB"), attached = TRUE, ondisk_version = "1.0",
    loaded_version = "1.0", source = "CRAN", stringsAsFactors = FALSE
  )
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = new_pkgs
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff, max_rows = 10)
  expect_no_match(txt, "more", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() errors informatively on an unknown packages column", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  ), packages = data.frame(
    package = "pkgC", attached = TRUE, ondisk_version = "1.0", loaded_version = "1.0",
    source = "CRAN", stringsAsFactors = FALSE
  )))
  diff <- compare_sessionstates(old, new)
  expect_error(format(diff, packages = "bogus_column"), "Unknown")
})

test_that("format.sessioncheck_sessionstatediff() column selection never affects the modified block's own columns", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = data.frame(
      package = c("base", "pkgA"), attached = c(TRUE, TRUE),
      ondisk_version = c("1.0", "2.0"), loaded_version = c("1.0", "2.0"),
      source = c("base", "CRAN"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff, packages = "package")
  expect_match(txt, "Modified \\[n = ", fixed = FALSE)
  expect_match(txt, "ondisk_version", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() reports added/removed/modified packages", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = data.frame(
      package = c("base", "pkgA"), attached = c(TRUE, TRUE),
      ondisk_version = c("1.0", "2.0"), loaded_version = c("1.0", "2.0"),
      source = c("base", "CRAN"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "Modified \\[n = ", fixed = FALSE)
  expect_match(txt, "pkgA", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() reports added and removed packages without any modified", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = data.frame(
      package = c("base", "pkgC"), attached = c(TRUE, TRUE),
      ondisk_version = c("1.0", "1.0"), loaded_version = c("1.0", "1.0"),
      source = c("base", "CRAN"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "Added \\[n = 1\\]", fixed = FALSE)
  expect_match(txt, "Removed \\[n = 1\\]", fixed = FALSE)
  expect_no_match(txt, "Modified \\[n = ", fixed = FALSE)
  expect_match(txt, "pkgC", fixed = TRUE)
  expect_match(txt, "pkgA", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstatediff() reports added and removed library paths", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    libpaths = c("/lib/a", "/lib/c")
  ))
  diff <- compare_sessionstates(old, new)
  txt <- format(diff)
  expect_match(txt, "Added:", fixed = TRUE)
  expect_match(txt, "/lib/c", fixed = TRUE)
  expect_match(txt, "Removed:", fixed = TRUE)
  expect_match(txt, "/lib/b", fixed = TRUE)
})

# as.data.frame.sessioncheck_sessionstatediff() ------

test_that("as.data.frame.sessioncheck_sessionstatediff() defaults to a long-format packages table", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    packages = data.frame(
      package = c("base", "pkgA", "pkgC"), attached = c(TRUE, FALSE, TRUE),
      ondisk_version = c("1.0", "1.1", "1.0"), loaded_version = c("1.0", "1.1", "1.0"),
      source = c("base", "CRAN", "CRAN"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  df <- as.data.frame(diff)
  expect_identical(df, as.data.frame(diff, which = "packages"))
  expect_named(df, c("package", "change", "field", "old", "new"))

  added_rows <- df[df$package == "pkgC" & df$change == "added", ]
  expect_setequal(added_rows$field, c("attached", "ondisk_version", "loaded_version", "source"))
  expect_true(all(is.na(added_rows$old)))
  expect_false(any(is.na(added_rows$new)))

  modified_rows <- df[df$package == "pkgA" & df$change == "modified", ]
  expect_true(all(c("attached", "ondisk_version", "loaded_version") %in% modified_rows$field))
})

test_that("as.data.frame.sessioncheck_sessionstatediff() reports globalenv with a verified column", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    globalenv = data.frame(
      name = c("x", "z"), class = c("numeric", "character"), size = c(56, 10),
      hash = c("hx2", "hz1"), stringsAsFactors = FALSE
    )
  ))
  diff <- compare_sessionstates(old, new)
  df <- as.data.frame(diff, which = "globalenv")
  expect_named(df, c("name", "change", "field", "old", "new", "verified"))

  added_rows <- df[df$name == "z" & df$change == "added", ]
  expect_true(all(is.na(added_rows$verified)))

  removed_rows <- df[df$name == "y" & df$change == "removed", ]
  expect_identical(nrow(removed_rows), 3L)
  expect_true(all(is.na(removed_rows$verified)))

  modified_rows <- df[df$name == "x" & df$change == "modified", ]
  expect_identical(modified_rows$field, "hash")
  expect_true(all(modified_rows$verified))
})

test_that("as.data.frame.sessioncheck_sessionstatediff() attachments has no modified rows", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(
    timing = list(captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11),
    attachments = data.frame(name = c(".GlobalEnv", "package:pkgD"), type = c("other", "package"), stringsAsFactors = FALSE)
  ))
  diff <- compare_sessionstates(old, new)
  df <- as.data.frame(diff, which = "attachments")
  expect_named(df, c("name", "change", "field", "old", "new"))
  expect_false("modified" %in% df$change)
  expect_true(all(df$field == "type"))
})

test_that("as.data.frame.sessioncheck_sessionstatediff() returns zero-row tables with correct columns when nothing changed", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)

  df_pkg <- as.data.frame(diff, which = "packages")
  expect_named(df_pkg, c("package", "change", "field", "old", "new"))
  expect_identical(nrow(df_pkg), 0L)

  df_genv <- as.data.frame(diff, which = "globalenv")
  expect_named(df_genv, c("name", "change", "field", "old", "new", "verified"))
  expect_identical(nrow(df_genv), 0L)

  df_att <- as.data.frame(diff, which = "attachments")
  expect_named(df_att, c("name", "change", "field", "old", "new"))
  expect_identical(nrow(df_att), 0L)
})

test_that("as.data.frame.sessioncheck_sessionstatediff() errors informatively on an unknown which value", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  expect_error(as.data.frame(diff, which = "bogus"))
})

test_that("as.data.frame.sessioncheck_sessionstatediff() integrates with a real sessionstate() diff", {
  old <- sessionstate()
  assign("sc_test_diff_df_obj", 1:10, envir = .GlobalEnv)
  on.exit(rm(sc_test_diff_df_obj, envir = .GlobalEnv), add = TRUE)
  new <- sessionstate()

  diff <- compare_sessionstates(old, new)
  df <- as.data.frame(diff, which = "globalenv")
  added_rows <- df[df$name == "sc_test_diff_df_obj" & df$change == "added", ]
  expect_setequal(added_rows$field, c("class", "size", "hash"))
  expect_true(all(is.na(added_rows$old)))
})

test_that("print.sessioncheck_sessionstatediff() prints format() output invisibly", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  expect_invisible(print(diff))
  expect_output(print(diff), format(diff), fixed = TRUE)
})
