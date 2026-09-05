# Stress-test battery for sessionstate().
#
# Exploratory/dev script -- not part of the package or the formal test
# suite. Each case below pokes at one field of sessionstate() with an
# unusual-but-real session condition, checks the result, and restores
# whatever it touched (working directory, env vars, .libPaths(), RNG
# state, attached environments). Source interactively after
# devtools::load_all():
#
#   source("dev/stress-test-sessionstate.R")
#   report <- run_stress_tests()
#   report
#
# Cases that depend on external tools (git) or optional packages (R6) are
# skipped with a note if unavailable, rather than failing.

.stress_report <- new.env()
.stress_report$rows <- list()

.stress_record <- function(case, status, detail = "") {
  .stress_report$rows[[length(.stress_report$rows) + 1L]] <- data.frame(
    case = case, status = status, detail = detail, stringsAsFactors = FALSE
  )
}

# runs `expr`, records "PASS"/"FAIL"/"ERROR", and never throws -- so one
# broken case doesn't abort the rest of the battery
.stress_case <- function(label, expr) {
  result <- tryCatch(
    list(ok = isTRUE(expr), detail = ""),
    error = function(e) list(ok = NA, detail = conditionMessage(e))
  )
  status <- if (is.na(result$ok)) "ERROR" else if (result$ok) "PASS" else "FAIL"
  .stress_record(label, status, result$detail)
  invisible(result)
}

# 1. non-git working directory ------------------------------------------

case_non_git_dir <- function() {
  old_wd <- getwd()
  scratch <- file.path(tempdir(), paste0("stress-nogit-", Sys.getpid()))
  dir.create(scratch, showWarnings = FALSE)
  on.exit({ setwd(old_wd); unlink(scratch, recursive = TRUE) })
  setwd(scratch)

  x <- sessionstate()
  .stress_case(
    "git info is NA outside a git repo",
    is.na(x$git$sha) && is.na(x$git$dirty)
  )
}

# 2/3. clean vs. dirty git repo ------------------------------------------

case_git_repo <- function() {
  if (!nzchar(Sys.which("git"))) {
    .stress_record("git info in a clean repo", "SKIP", "git not installed")
    .stress_record("git info in a dirty repo", "SKIP", "git not installed")
    return(invisible())
  }

  old_wd <- getwd()
  repo <- file.path(tempdir(), paste0("stress-git-", Sys.getpid()))
  dir.create(repo, showWarnings = FALSE)
  on.exit({ setwd(old_wd); unlink(repo, recursive = TRUE) })
  setwd(repo)

  system2("git", c("init", "-q"))
  system2("git", c("config", "user.email", "stress@example.com"))
  system2("git", c("config", "user.name", "Stress Test"))
  writeLines("one", "file.txt")
  system2("git", c("add", "file.txt"))
  system2("git", c("commit", "-q", "-m", "init"))

  x_clean <- sessionstate()
  .stress_case(
    "git info in a clean repo",
    !is.na(x_clean$git$sha) && nchar(x_clean$git$sha) == 40L && identical(x_clean$git$dirty, FALSE)
  )

  writeLines("two", "file.txt")
  x_dirty <- sessionstate()
  .stress_case(
    "git info in a dirty repo",
    identical(x_dirty$git$sha, x_clean$git$sha) && identical(x_dirty$git$dirty, TRUE)
  )
}

# 4. pandoc & quarto both unresolvable ------------------------------------

case_missing_document_tools <- function() {
  old_path <- Sys.getenv("PATH")
  old_pandoc <- Sys.getenv("RSTUDIO_PANDOC", unset = NA)
  old_quarto <- Sys.getenv("QUARTO_PATH", unset = NA)
  empty_dir <- file.path(tempdir(), paste0("stress-empty-path-", Sys.getpid()))
  dir.create(empty_dir, showWarnings = FALSE)
  on.exit({
    Sys.setenv(PATH = old_path)
    if (is.na(old_pandoc)) Sys.unsetenv("RSTUDIO_PANDOC") else Sys.setenv(RSTUDIO_PANDOC = old_pandoc)
    if (is.na(old_quarto)) Sys.unsetenv("QUARTO_PATH") else Sys.setenv(QUARTO_PATH = old_quarto)
    unlink(empty_dir, recursive = TRUE)
  })

  Sys.unsetenv("RSTUDIO_PANDOC")
  Sys.unsetenv("QUARTO_PATH")
  Sys.setenv(PATH = empty_dir)

  x <- sessionstate()
  .stress_case(
    "pandoc/quarto both report NA when unresolvable",
    is.na(x$document$pandoc) && is.na(x$document$quarto)
  )
}

# 5. RNG state: untouched vs. touched ------------------------------------

case_rng_state <- function() {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  on.exit({
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
  })

  if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".Random.seed", envir = .GlobalEnv)
  }
  x_before <- sessionstate()
  .stress_case(
    "seed_hash is NA before any random draw",
    is.na(x_before$rng$seed_hash)
  )

  invisible(runif(1))
  x_after1 <- sessionstate()
  invisible(runif(1))
  x_after2 <- sessionstate()
  .stress_case(
    "seed_hash is a populated, changing fingerprint after draws",
    !is.na(x_after1$rng$seed_hash) &&
      nchar(x_after1$rng$seed_hash) == 32L &&
      !identical(x_after1$rng$seed_hash, x_after2$rng$seed_hash)
  )
}

# 6. library path that existed when set but is gone by capture time --------
#
# .libPaths()'s *setter* silently drops paths that don't exist on disk at
# the time they're set (confirmed empirically -- not documented behavior
# we should rely on elsewhere, but real here), so a genuinely nonexistent
# path can never enter .libPaths() in the first place. The realistic edge
# case is a path that existed when added but was deleted before capture;
# .libPaths()'s *getter* (which .get_libpaths_info() calls) does not
# re-check existence, so it should still be reported.

case_stale_libpath <- function() {
  old_libpaths <- .libPaths()
  on.exit(.libPaths(old_libpaths))

  stale <- file.path(tempdir(), paste0("stress-stale-lib-", Sys.getpid()))
  dir.create(stale)
  .libPaths(c(stale, old_libpaths))
  unlink(stale, recursive = TRUE)

  x <- sessionstate()
  .stress_case(
    "a library path deleted after being set is still reported (no re-check at read time)",
    stale %in% x$libpaths
  )
}

# 7. unusual global-environment object classes ----------------------------

case_unusual_globalenv_classes <- function() {
  nms <- c(
    ".stress_hidden", "stress_fun", "stress_env", "stress_factor",
    "stress_s4", "stress_matrix", "stress_long_char"
  )
  on.exit(rm(list = intersect(nms, ls(envir = .GlobalEnv, all.names = TRUE)), envir = .GlobalEnv))

  setClass("StressTestS4", representation(val = "numeric"))
  assign(".stress_hidden", 1L, envir = .GlobalEnv)
  assign("stress_fun", function(x) x + 1, envir = .GlobalEnv)
  assign("stress_env", new.env(), envir = .GlobalEnv)
  assign("stress_factor", factor(c("a", "b", "a")), envir = .GlobalEnv)
  assign("stress_s4", new("StressTestS4", val = 1), envir = .GlobalEnv)
  assign("stress_matrix", matrix(1:9, 3), envir = .GlobalEnv)
  assign("stress_long_char", paste(rep("x", 1e5), collapse = ""), envir = .GlobalEnv)

  x <- sessionstate()
  present <- nms %in% x$globalenv$name
  .stress_case(
    "unusual-class objects (S4, closure, environment, factor, matrix, dot-prefixed, long string) are all captured without error",
    all(present)
  )
}

# 8. huge object size formatting -------------------------------------------

case_huge_object <- function() {
  if (!exists("big_df", envir = .GlobalEnv, inherits = FALSE)) {
    .stress_record("huge global-env object is captured with a plausible size", "SKIP", "big_df not present in this session")
    return(invisible())
  }
  x <- sessionstate()
  row <- x$globalenv[x$globalenv$name == "big_df", ]
  .stress_case(
    "huge global-env object is captured with a plausible size",
    nrow(row) == 1L && row$size > 1e6
  )
}

# 9. non-package (environment) attachment ----------------------------------

case_non_package_attachment <- function() {
  on.exit(if ("stress_test_env" %in% search()) detach("stress_test_env"))
  attach(list(a = 1), name = "stress_test_env")

  x <- sessionstate()
  row <- x$attachments[x$attachments$name == "stress_test_env", ]
  .stress_case(
    "a non-package environment on the search path is typed as \"other\"",
    nrow(row) == 1L && identical(row$type, "other")
  )
}

# 10. package helper behavior for an unknown package name -------------------

case_unknown_package_name <- function() {
  bogus_pkg <- "zzz_stress_test_pkg_does_not_exist_zzz"
  .stress_case(
    "helpers degrade to NA/\"unknown\" for a package that isn't installed",
    is.na(sessioncheck:::.get_ondisk_path(bogus_pkg)) &&
      is.na(sessioncheck:::.get_loaded_path(bogus_pkg)) &&
      identical(sessioncheck:::.get_package_source(bogus_pkg), "unknown")
  )
}

# 11. version_mismatch / path_mismatch via mocked helpers -------------------
#
# Mocked rather than achieved via a real install: physically relocating or
# editing an installed package's files on disk to force a mismatch would be
# destructive to the user's real R library. Mocking the on-disk-facing
# helpers for one real, already-loaded package name isolates the flag logic
# in .get_package_inventory() without touching anything on disk.

case_mismatch_flags_mocked <- function() {
  target <- "stats" # base-priority, always loaded, never actually mismatched
  real_ondisk_path <- sessioncheck:::.get_ondisk_path
  real_loaded_version <- sessioncheck:::.get_loaded_version

  testthat::local_mocked_bindings(
    .get_ondisk_path = function(pkg) {
      if (identical(pkg, target)) return("/fake/relocated/lib/stats")
      real_ondisk_path(pkg)
    },
    .get_loaded_version = function(pkg) {
      if (identical(pkg, target)) return("999.99.99")
      real_loaded_version(pkg)
    },
    .package = "sessioncheck"
  )

  inv <- sessioncheck:::.get_package_inventory()
  row <- inv[inv$package == target, ]
  .stress_case(
    "mocked on-disk drift is surfaced as version_mismatch and path_mismatch",
    nrow(row) == 1L && isTRUE(row$version_mismatch) && isTRUE(row$path_mismatch)
  )
}

# 12. removed_from_disk via mocked helper -----------------------------------

case_removed_from_disk_mocked <- function() {
  target <- "stats"
  real_ondisk_path <- sessioncheck:::.get_ondisk_path

  testthat::local_mocked_bindings(
    .get_ondisk_path = function(pkg) {
      if (identical(pkg, target)) return(NA_character_)
      real_ondisk_path(pkg)
    },
    .package = "sessioncheck"
  )

  inv <- sessioncheck:::.get_package_inventory()
  row <- inv[inv$package == target, ]
  .stress_case(
    "a loaded namespace missing from disk is flagged removed_from_disk",
    nrow(row) == 1L && isTRUE(row$removed_from_disk)
  )
}

# runner -------------------------------------------------------------------

run_stress_tests <- function() {
  .stress_report$rows <- list()

  case_non_git_dir()
  case_git_repo()
  case_missing_document_tools()
  case_rng_state()
  case_stale_libpath()
  case_unusual_globalenv_classes()
  case_huge_object()
  case_non_package_attachment()
  case_unknown_package_name()
  case_mismatch_flags_mocked()
  case_removed_from_disk_mocked()

  report <- do.call(rbind, .stress_report$rows)
  rownames(report) <- NULL
  report
}
