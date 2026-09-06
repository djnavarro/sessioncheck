
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
  merged <- utils::modifyList(base, overrides)
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

test_that(".diff_globalenv() treats an unchanged hash as no modification", {
  old <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  new <- data.frame(name = "x", class = "numeric", size = 100, hash = "h1", stringsAsFactors = FALSE)
  diff <- .diff_globalenv(old, new)
  expect_identical(nrow(diff$modified), 0L)
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

test_that("print.sessioncheck_sessionstatediff() prints format() output invisibly", {
  old <- .mock_sessionstate()
  new <- .mock_sessionstate(list(timing = list(
    captured_at = as.POSIXct("2026-01-01 00:00:10", tz = "UTC"), elapsed_sec = 11
  )))
  diff <- compare_sessionstates(old, new)
  expect_invisible(print(diff))
  expect_output(print(diff), format(diff), fixed = TRUE)
})
