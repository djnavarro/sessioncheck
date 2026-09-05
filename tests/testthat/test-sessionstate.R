test_that("sessionstate() returns a well-formed sessioncheck_sessionstate object", {
  x <- sessionstate()
  expect_s3_class(x, "sessioncheck_sessionstate")
  expect_named(
    x,
    c(
      "platform", "locale", "matrix", "document", "machine", "git", "timing", "rng", "libpaths",
      "packages", "globalenv", "attachments"
    )
  )
  expect_true(is.list(x$platform))
  expect_true(is.list(x$locale))
  expect_true(is.list(x$matrix))
  expect_true(is.list(x$document))
  expect_true(is.list(x$machine))
  expect_true(is.list(x$timing))
  expect_true(is.list(x$rng))
  expect_true(is.list(x$git))
  expect_identical(x$machine$cwd, getwd())
  expect_true(is.character(x$libpaths))
  expect_identical(x$libpaths, .libPaths())
  expect_s3_class(x$packages, "data.frame")
  expect_s3_class(x$globalenv, "data.frame")
  expect_s3_class(x$attachments, "data.frame")
})

test_that(".get_libpaths_info() returns .libPaths()", {
  expect_identical(.get_libpaths_info(), .libPaths())
})

test_that("format.sessioncheck_sessionstate() lists every library path", {
  local_mocked_bindings(.get_libpaths_info = function() c("/lib/one", "/lib/two"))
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "Library paths \\[n = 2\\]:", fixed = FALSE)
  expect_match(txt, "1  /lib/one", fixed = TRUE)
  expect_match(txt, "2  /lib/two", fixed = TRUE)
})

test_that(".get_rng_info() reports RNGkind() and a seed hash", {
  set.seed(4821)
  info <- .get_rng_info()
  expect_named(info, c("kind", "normal_kind", "sample_kind", "seed_hash"))
  expect_identical(unname(unlist(info[c("kind", "normal_kind", "sample_kind")])), RNGkind())
  expect_identical(info$seed_hash, .hash_random_seed())
})

test_that(".hash_random_seed() is stable for an unchanged seed and changes after a draw", {
  set.seed(9137)
  h1 <- .hash_random_seed()
  h2 <- .hash_random_seed()
  expect_identical(h1, h2)
  runif(1)
  h3 <- .hash_random_seed()
  expect_false(identical(h1, h3))
})

test_that(".hash_random_seed() is reproducible after resetting the same seed", {
  set.seed(9137)
  h1 <- .hash_random_seed()
  runif(1)
  set.seed(9137)
  h2 <- .hash_random_seed()
  expect_identical(h1, h2)
})

test_that(".hash_random_seed() returns NA when .Random.seed doesn't exist", {
  local_mocked_bindings(exists = function(...) FALSE, .package = "base")
  expect_identical(.hash_random_seed(), NA_character_)
})

test_that(".get_globalenv_info() captures every object in .GlobalEnv, never values", {
  assign("sc_test_obj_a", 1:10, envir = .GlobalEnv)
  assign("sc_test_obj_b", "some string", envir = .GlobalEnv)
  on.exit(rm(list = c("sc_test_obj_a", "sc_test_obj_b"), envir = .GlobalEnv), add = TRUE)

  df <- .get_globalenv_info()
  expect_named(df, c("name", "class", "size"))
  expect_true(all(c("sc_test_obj_a", "sc_test_obj_b") %in% df$name))
  expect_identical(df$class[df$name == "sc_test_obj_a"], "integer")
  expect_identical(df$class[df$name == "sc_test_obj_b"], "character")
  expect_true(is.numeric(df$size))
  expect_false(any(grepl("some string", unlist(df), fixed = TRUE)))
})

test_that(".get_search_path_info() classifies packages vs. other attachments", {
  df <- .get_search_path_info()
  expect_named(df, c("name", "type"))
  expect_identical(df$name, search())
  expect_true(all(df$type[grepl("^package:", df$name)] == "package"))
  # the base package sits last on the search path and is always a package,
  # even though (unlike other packages) it carries no "path" attribute
  expect_identical(df$type[length(df$type)], "package")
})

test_that("as.data.frame.sessioncheck_sessionstate() defaults to the package inventory", {
  x <- sessionstate()
  df <- as.data.frame(x)
  expect_identical(df, as.data.frame(x, which = "packages"))
  expect_s3_class(df, "data.frame")
  expect_named(
    df,
    c(
      "package", "attached", "ondisk_version", "loaded_version", "version_mismatch",
      "ondisk_path", "loaded_path", "path_mismatch", "removed_from_disk", "source"
    )
  )
  expect_true("base" %in% df$package)
  expect_true("sessioncheck" %in% df$package)
  expect_true(is.logical(df$attached))
  expect_true(is.logical(df$version_mismatch))
  expect_true(is.logical(df$path_mismatch))
  expect_true(is.logical(df$removed_from_disk))
  # sessioncheck itself is loaded via devtools::load_all() during testing,
  # so its on-disk/loaded versions and paths should agree in this session
  expect_false(any(df$version_mismatch, na.rm = TRUE))
  expect_false(any(df$path_mismatch, na.rm = TRUE))
  expect_false(any(df$removed_from_disk, na.rm = TRUE))
})

test_that("as.data.frame.sessioncheck_sessionstate() can return the globalenv table", {
  x <- sessionstate()
  df <- as.data.frame(x, which = "globalenv")
  expect_identical(df, x$globalenv)
  expect_named(df, c("name", "class", "size"))
})

test_that("as.data.frame.sessioncheck_sessionstate() can return the attachments table", {
  x <- sessionstate()
  df <- as.data.frame(x, which = "attachments")
  expect_identical(df, x$attachments)
  expect_named(df, c("name", "type"))
})

test_that("as.data.frame.sessioncheck_sessionstate() errors informatively on an unknown which value", {
  x <- sessionstate()
  expect_error(as.data.frame(x, which = "machine"))
})

test_that("format.sessioncheck_sessionstate() produces a single string with expected sections", {
  x <- sessionstate()
  txt <- format(x)
  expect_type(txt, "character")
  expect_length(txt, 1L)
  expect_match(txt, "Platform:", fixed = TRUE)
  expect_match(txt, "Machine:", fixed = TRUE)
  expect_match(txt, "Timing:", fixed = TRUE)
  expect_match(txt, "Packages \\[n = ", fixed = FALSE)
})

test_that("print.sessioncheck_sessionstate() prints and returns its input invisibly", {
  x <- sessionstate()
  expect_output(ret <- withVisible(print(x)))
  expect_identical(ret$value, x)
  expect_false(ret$visible)
})

test_that("format.sessioncheck_sessionstate() defaults packages to the curated column subset", {
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "package", fixed = TRUE)
  expect_match(txt, "attached", fixed = TRUE)
  expect_match(txt, "loaded_version", fixed = TRUE)
  expect_match(txt, "source", fixed = TRUE)
  expect_no_match(txt, "ondisk_version", fixed = TRUE)
  expect_no_match(txt, "ondisk_path", fixed = TRUE)
  expect_no_match(txt, "loaded_path", fixed = TRUE)
  expect_no_match(txt, "version_mismatch", fixed = TRUE)
  expect_no_match(txt, "path_mismatch", fixed = TRUE)
  expect_no_match(txt, "removed_from_disk", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() defaults platform/machine/timing to showing every field", {
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "Matrix products:", fixed = TRUE)
  expect_match(txt, "hostname", fixed = TRUE)
  expect_match(txt, "captured at", fixed = TRUE)
  expect_match(txt, "working directory   ", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts machine fields to exclude cwd when requested", {
  x <- sessionstate()
  txt <- format(x, machine = "nodename")
  expect_no_match(txt, "working directory", fixed = TRUE)
})

test_that(".run_git_command() returns NA when git errors or exits non-zero", {
  local_mocked_bindings(system2 = function(...) stop("git not found"), .package = "base")
  expect_identical(.run_git_command(c("rev-parse", "HEAD")), NA_character_)

  local_mocked_bindings(
    system2 = function(...) structure(character(0), status = 128L),
    .package = "base"
  )
  expect_identical(.run_git_command(c("rev-parse", "HEAD")), NA_character_)
})

test_that(".run_git_command() returns the joined output on success", {
  local_mocked_bindings(system2 = function(...) c("line1", "line2"), .package = "base")
  expect_identical(.run_git_command("status"), "line1\nline2")
})

test_that(".run_git_command() returns an empty string for empty output", {
  local_mocked_bindings(system2 = function(...) character(0), .package = "base")
  expect_identical(.run_git_command("status"), "")
})

test_that(".get_git_info() reports NA sha/dirty when not in a git repository", {
  local_mocked_bindings(.run_git_command = function(args) NA_character_)
  expect_identical(.get_git_info(), list(sha = NA_character_, dirty = NA))
})

test_that(".get_git_info() reports sha and dirty when in a git repository", {
  local_mocked_bindings(.run_git_command = function(args) {
    if (identical(args, c("rev-parse", "HEAD"))) "abc123" else ""
  })
  expect_identical(.get_git_info(), list(sha = "abc123", dirty = FALSE))

  local_mocked_bindings(.run_git_command = function(args) {
    if (identical(args, c("rev-parse", "HEAD"))) "abc123" else " M file.R"
  })
  expect_identical(.get_git_info(), list(sha = "abc123", dirty = TRUE))
})

test_that("format.sessioncheck_sessionstate() defaults git to showing every field", {
  local_mocked_bindings(.get_git_info = function() list(sha = "abc123", dirty = TRUE))
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "Git:", fixed = TRUE)
  expect_match(txt, "commit sha      abc123", fixed = TRUE)
  expect_match(txt, "dirty           TRUE", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts git fields when requested", {
  local_mocked_bindings(.get_git_info = function() list(sha = "abc123", dirty = TRUE))
  x <- sessionstate()
  txt <- format(x, git = "sha")
  expect_match(txt, "commit sha      abc123", fixed = TRUE)
  expect_no_match(txt, "dirty", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() honors sessionstate_git set via options(sessioncheck = ...)", {
  local_mocked_bindings(.get_git_info = function() list(sha = "abc123", dirty = TRUE))
  old <- options(sessioncheck = list(sessionstate_git = "sha"))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x)
  expect_no_match(txt, "dirty", fixed = TRUE)
})

test_that("an explicit git argument overrides options(sessioncheck = ...)", {
  local_mocked_bindings(.get_git_info = function() list(sha = "abc123", dirty = TRUE))
  old <- options(sessioncheck = list(sessionstate_git = "sha"))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x, git = c("sha", "dirty"))
  expect_match(txt, "dirty", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() reports placeholders when git info is NA", {
  local_mocked_bindings(.get_git_info = function() list(sha = NA_character_, dirty = NA))
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "commit sha      \\(not a git repository\\)", fixed = FALSE)
  expect_match(txt, "dirty           \\(unknown\\)", fixed = FALSE)
})

test_that("format.sessioncheck_sessionstate() errors informatively on an unknown git field", {
  x <- sessionstate()
  expect_error(format(x, git = "bogus"), "Unknown git field")
})

test_that("format.sessioncheck_sessionstate() defaults rng to showing every field", {
  set.seed(2024)
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "RNG state:", fixed = TRUE)
  expect_match(txt, "kind            Mersenne-Twister", fixed = TRUE)
  expect_match(txt, "normal kind     Inversion", fixed = TRUE)
  expect_match(txt, "sample kind     Rejection", fixed = TRUE)
  expect_match(txt, "seed hash       ", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts rng fields when requested", {
  set.seed(2024)
  x <- sessionstate()
  txt <- format(x, rng = "kind")
  expect_match(txt, "kind            Mersenne-Twister", fixed = TRUE)
  expect_no_match(txt, "seed hash", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() honors sessionstate_rng set via options(sessioncheck = ...)", {
  set.seed(2024)
  old <- options(sessioncheck = list(sessionstate_rng = "kind"))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x)
  expect_no_match(txt, "seed hash", fixed = TRUE)
})

test_that("an explicit rng argument overrides options(sessioncheck = ...)", {
  set.seed(2024)
  old <- options(sessioncheck = list(sessionstate_rng = "kind"))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x, rng = c("kind", "seed_hash"))
  expect_match(txt, "seed hash", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() reports '(not set)' when seed_hash is NA", {
  local_mocked_bindings(.get_rng_info = function() {
    list(kind = "Mersenne-Twister", normal_kind = "Inversion", sample_kind = "Rejection", seed_hash = NA_character_)
  })
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "seed hash       \\(not set\\)", fixed = FALSE)
})

test_that("format.sessioncheck_sessionstate() errors informatively on an unknown rng field", {
  x <- sessionstate()
  expect_error(format(x, rng = "bogus"), "Unknown rng field")
})

test_that(".run_version_command() returns NA when the path is empty or missing", {
  expect_identical(.run_version_command("", "--version"), NA_character_)
  expect_identical(.run_version_command("/no/such/binary", "--version"), NA_character_)
})

test_that(".run_version_command() strips a leading word from pandoc-style output", {
  local_mocked_bindings(file.exists = function(...) TRUE, .package = "base")
  local_mocked_bindings(
    system2 = function(...) c("pandoc 3.10", "Features: +server"),
    .package = "base"
  )
  expect_identical(.run_version_command(tempfile(), "--version"), "3.10")
})

test_that(".run_version_command() leaves bare version-number output unchanged", {
  local_mocked_bindings(file.exists = function(...) TRUE, .package = "base")
  local_mocked_bindings(system2 = function(...) "1.5.55", .package = "base")
  expect_identical(.run_version_command(tempfile(), "--version"), "1.5.55")
})

test_that(".run_version_command() returns NA when the command errors or warns", {
  local_mocked_bindings(file.exists = function(...) TRUE, .package = "base")
  local_mocked_bindings(system2 = function(...) stop("nope"), .package = "base")
  expect_identical(.run_version_command(tempfile(), "--version"), NA_character_)
  local_mocked_bindings(system2 = function(...) { warning("nope"); "" }, .package = "base")
  expect_identical(.run_version_command(tempfile(), "--version"), NA_character_)
})

test_that(".get_pandoc_version() prefers RSTUDIO_PANDOC over PATH", {
  old <- Sys.getenv("RSTUDIO_PANDOC", unset = NA)
  Sys.setenv(RSTUDIO_PANDOC = tempdir())
  on.exit(
    if (is.na(old)) Sys.unsetenv("RSTUDIO_PANDOC") else Sys.setenv(RSTUDIO_PANDOC = old),
    add = TRUE
  )
  local_mocked_bindings(.run_version_command = function(path, ...) path)
  expected <- file.path(
    tempdir(), if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  )
  expect_identical(.get_pandoc_version(), expected)
})

test_that(".get_pandoc_version() falls back to PATH when RSTUDIO_PANDOC is unset", {
  old <- Sys.getenv("RSTUDIO_PANDOC", unset = NA)
  Sys.setenv(RSTUDIO_PANDOC = "")
  on.exit(
    if (is.na(old)) Sys.unsetenv("RSTUDIO_PANDOC") else Sys.setenv(RSTUDIO_PANDOC = old),
    add = TRUE
  )
  local_mocked_bindings(Sys.which = function(x) c(pandoc = "/usr/bin/pandoc"), .package = "base")
  local_mocked_bindings(.run_version_command = function(path, ...) path)
  expect_identical(.get_pandoc_version(), "/usr/bin/pandoc")
})

test_that(".get_quarto_version() prefers QUARTO_PATH over PATH", {
  old <- Sys.getenv("QUARTO_PATH", unset = NA)
  Sys.setenv(QUARTO_PATH = "/some/quarto")
  on.exit(
    if (is.na(old)) Sys.unsetenv("QUARTO_PATH") else Sys.setenv(QUARTO_PATH = old),
    add = TRUE
  )
  local_mocked_bindings(.run_version_command = function(path, ...) path)
  expect_identical(.get_quarto_version(), "/some/quarto")
})

test_that(".get_quarto_version() falls back to PATH when QUARTO_PATH is unset", {
  old <- Sys.getenv("QUARTO_PATH", unset = NA)
  Sys.setenv(QUARTO_PATH = "")
  on.exit(
    if (is.na(old)) Sys.unsetenv("QUARTO_PATH") else Sys.setenv(QUARTO_PATH = old),
    add = TRUE
  )
  local_mocked_bindings(Sys.which = function(x) c(quarto = "/usr/bin/quarto"), .package = "base")
  local_mocked_bindings(.run_version_command = function(path, ...) path)
  expect_identical(.get_quarto_version(), "/usr/bin/quarto")
})

test_that(".get_document_info() includes pandoc and quarto fields", {
  info <- .get_document_info()
  expect_true(all(c("pandoc", "quarto") %in% names(info)))
})

test_that("format.sessioncheck_sessionstate() restricts document fields when requested", {
  x <- sessionstate()
  txt <- format(x, document = "pandoc")
  expect_match(txt, "pandoc", fixed = TRUE)
  expect_no_match(txt, "quarto", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() reports '(not found)' when pandoc/quarto are unavailable", {
  local_mocked_bindings(.get_pandoc_version = function() NA_character_)
  local_mocked_bindings(.get_quarto_version = function() NA_character_)
  x <- sessionstate()
  txt <- format(x, document = c("pandoc", "quarto"))
  expect_match(txt, "pandoc.*\\(not found\\)", fixed = FALSE)
  expect_match(txt, "quarto.*\\(not found\\)", fixed = FALSE)
})

test_that("format.sessioncheck_sessionstate() defaults globalenv to every column but only the 10 largest rows", {
  for (i in 1:15) assign(paste0("sc_test_genv_", i), i, envir = .GlobalEnv)
  on.exit(rm(list = paste0("sc_test_genv_", 1:15), envir = .GlobalEnv), add = TRUE)

  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "Global environment \\[n = ", fixed = FALSE)
  lines <- strsplit(txt, "\n")[[1]]
  header_line <- lines[grep("^\\s*name\\s+class\\s+size\\s*$", lines)]
  expect_length(header_line, 1L)
  expect_match(txt, "... and", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() shows every globalenv row when there are 10 or fewer", {
  local_mocked_bindings(.get_globalenv_info = function() {
    data.frame(name = c("a", "b"), class = c("numeric", "numeric"), size = c(56, 48), stringsAsFactors = FALSE)
  })
  x <- sessionstate()
  txt <- format(x)
  expect_no_match(txt, "... and", fixed = TRUE)
  expect_match(txt, "Global environment \\[n = 2\\]", fixed = FALSE)
})

test_that("format.sessioncheck_sessionstate() orders globalenv rows by size regardless of displayed columns", {
  local_mocked_bindings(.get_globalenv_info = function() {
    data.frame(
      name = c("small", "big", "medium"),
      class = "numeric",
      size = c(10, 1000, 100),
      stringsAsFactors = FALSE
    )
  })
  x <- sessionstate()
  txt <- format(x, globalenv = "name")
  lines <- strsplit(txt, "\n")[[1]]
  genv_start <- grep("^Global environment", lines)
  genv_lines <- trimws(lines[(genv_start + 2L):(genv_start + 4L)])
  expect_identical(genv_lines, c("big", "medium", "small"))
})

test_that("format.sessioncheck_sessionstate() honors sessionstate_globalenv and sessionstate_globalenv_n options", {
  local_mocked_bindings(.get_globalenv_info = function() {
    data.frame(
      name = c("a", "b", "c"),
      class = "numeric",
      size = c(30, 20, 10),
      stringsAsFactors = FALSE
    )
  })
  old <- options(sessioncheck = list(sessionstate_globalenv = "name", sessionstate_globalenv_n = 1))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x)
  expect_no_match(txt, "class", fixed = TRUE)
  expect_match(txt, "... and 2 more", fixed = TRUE)
})

test_that("explicit globalenv/globalenv_n arguments override options(sessioncheck = ...)", {
  local_mocked_bindings(.get_globalenv_info = function() {
    data.frame(
      name = c("a", "b", "c"),
      class = "numeric",
      size = c(30, 20, 10),
      stringsAsFactors = FALSE
    )
  })
  old <- options(sessioncheck = list(sessionstate_globalenv_n = 1))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x, globalenv_n = 3)
  expect_no_match(txt, "... and", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() errors informatively on invalid globalenv_n", {
  x <- sessionstate()
  expect_error(format(x, globalenv_n = "a"), "must be a single number")
  expect_error(format(x, globalenv_n = c(1, 2)), "must be a single number")
})

test_that("format.sessioncheck_sessionstate() defaults attachments to every column and every row", {
  x <- sessionstate()
  txt <- format(x)
  expect_match(txt, "Attached environments \\[n = ", fixed = FALSE)
  lines <- strsplit(txt, "\n")[[1]]
  att_start <- grep("^Attached environments", lines)
  header_line <- lines[att_start + 1L]
  expect_match(header_line, "name", fixed = TRUE)
  expect_match(header_line, "type", fixed = TRUE)
  expect_match(txt, "\\.GlobalEnv", fixed = FALSE)
})

test_that("format.sessioncheck_sessionstate() restricts attachments columns when requested", {
  x <- sessionstate()
  txt <- format(x, attachments = "name")
  lines <- strsplit(txt, "\n")[[1]]
  att_start <- grep("^Attached environments", lines)
  header_line <- lines[att_start + 1L]
  expect_no_match(header_line, "type", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() honors sessionstate_attachments set via options(sessioncheck = ...)", {
  old <- options(sessioncheck = list(sessionstate_attachments = "name"))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x)
  lines <- strsplit(txt, "\n")[[1]]
  att_start <- grep("^Attached environments", lines)
  header_line <- lines[att_start + 1L]
  expect_no_match(header_line, "type", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() errors informatively on an unknown globalenv/attachments field", {
  x <- sessionstate()
  expect_error(format(x, globalenv = "bogus"), "Unknown globalenv field")
  expect_error(format(x, attachments = "bogus"), "Unknown attachments field")
})

test_that("selecting globalenv/attachments display fields never changes the underlying object", {
  x <- sessionstate()
  full_genv <- x$globalenv
  full_att <- x$attachments
  format(x, globalenv = "name", globalenv_n = 1, attachments = "name")
  expect_identical(x$globalenv, full_genv)
  expect_identical(x$attachments, full_att)
})

test_that("format.sessioncheck_sessionstate() honors sessionstate_packages set via options(sessioncheck = ...)", {
  old <- options(sessioncheck = list(sessionstate_packages = c("package", "source")))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x)
  # the "attached + loaded via namespace" sentence in the section heading
  # always contains the word "attached", so restrict the check to the
  # table itself, below the heading line
  lines <- strsplit(txt, "\n")[[1]]
  table_txt <- paste(lines[-seq_len(grep("^Packages", lines))], collapse = "\n")
  expect_no_match(table_txt, "attached", fixed = TRUE)
  expect_no_match(table_txt, "loaded_version", fixed = TRUE)
})

test_that("an explicit packages argument overrides options(sessioncheck = ...)", {
  old <- options(sessioncheck = list(sessionstate_packages = c("package", "source")))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x, packages = c("package", "attached"))
  expect_match(txt, "attached", fixed = TRUE)
  expect_no_match(txt, "source", fixed = TRUE)
})

test_that("options(sessioncheck = ...) can also set defaults for platform/machine/timing", {
  old <- options(sessioncheck = list(sessionstate_platform = "version", sessionstate_machine = "user"))
  on.exit(options(old), add = TRUE)
  x <- sessionstate()
  txt <- format(x)
  expect_no_match(txt, "ui ", fixed = TRUE)
  expect_no_match(txt, "hostname", fixed = TRUE)
  # timing has no option set, so it should still fall back to "show everything"
  expect_match(txt, "captured at", fixed = TRUE)
})

test_that(".resolve_field_selection() prefers the explicit argument", {
  old <- options(sessioncheck = list(some_option = "from_option"))
  on.exit(options(old), add = TRUE)
  expect_identical(.resolve_field_selection("from_arg", "some_option", "from_default"), "from_arg")
})

test_that(".resolve_field_selection() falls back to options(sessioncheck = ...) when no explicit argument is given", {
  old <- options(sessioncheck = list(some_option = "from_option"))
  on.exit(options(old), add = TRUE)
  expect_identical(.resolve_field_selection(NULL, "some_option", "from_default"), "from_option")
})

test_that(".resolve_field_selection() falls back to the hard-coded default when neither is set", {
  old <- options(sessioncheck = NULL)
  on.exit(options(old), add = TRUE)
  expect_identical(.resolve_field_selection(NULL, "some_option", "from_default"), "from_default")
})

test_that(".resolve_field_selection() falls back to the hard-coded default when getOption('sessioncheck') isn't a list", {
  old <- options(sessioncheck = "not_a_list")
  on.exit(options(old), add = TRUE)
  expect_identical(.resolve_field_selection(NULL, "some_option", "from_default"), "from_default")
})

test_that("format.sessioncheck_sessionstate() restricts platform fields when requested", {
  x <- sessionstate()
  txt <- format(x, platform = c("version", "os"))
  expect_match(txt, "version", fixed = TRUE)
  expect_match(txt, "os", fixed = TRUE)
  expect_no_match(txt, "ui ", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts locale fields when requested", {
  x <- sessionstate()
  txt <- format(x, locale = "collate")
  expect_match(txt, "collate", fixed = TRUE)
  expect_no_match(txt, "ctype", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts matrix fields when requested", {
  x <- sessionstate()
  txt <- format(x, matrix = "blas")
  expect_match(txt, "BLAS", fixed = TRUE)
  expect_no_match(txt, "LAPACK", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts machine and timing fields when requested", {
  x <- sessionstate()
  txt <- format(x, machine = "user", timing = "elapsed_sec")
  expect_no_match(txt, "hostname", fixed = TRUE)
  expect_no_match(txt, "captured at", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts package columns when requested", {
  x <- sessionstate()
  txt <- format(x, packages = c("package", "source"))
  expect_no_match(txt, "ondisk_version", fixed = TRUE)
  expect_no_match(txt, "loaded_path", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() errors informatively on an unknown field", {
  x <- sessionstate()
  expect_error(format(x, platform = "bogus"), "Unknown platform field")
  expect_error(format(x, locale = "bogus"), "Unknown locale field")
  expect_error(format(x, matrix = "bogus"), "Unknown matrix field")
  expect_error(format(x, document = "bogus"), "Unknown document field")
  expect_error(format(x, machine = "bogus"), "Unknown machine field")
  expect_error(format(x, git = "bogus"), "Unknown git field")
  expect_error(format(x, timing = "bogus"), "Unknown timing field")
  expect_error(format(x, rng = "bogus"), "Unknown rng field")
  expect_error(format(x, packages = "bogus"), "Unknown packages field")
})

test_that("format.sessioncheck_sessionstate() defaults to showing every field when NULL", {
  x <- sessionstate()
  expect_identical(
    format(x),
    format(
      x, platform = NULL, locale = NULL, matrix = NULL, document = NULL, machine = NULL, git = NULL,
      timing = NULL, rng = NULL, packages = NULL, globalenv = NULL, globalenv_n = NULL,
      attachments = NULL
    )
  )
})

test_that("print.sessioncheck_sessionstate() forwards field-selection arguments to format()", {
  x <- sessionstate()
  out <- capture.output(
    print(
      x, platform = "version", locale = "collate", matrix = "blas", document = "pandoc",
      machine = "user", git = "sha", timing = "elapsed_sec", rng = "kind", packages = "package"
    )
  )
  expect_equal(
    trimws(paste(out, collapse = "\n")),
    trimws(format(
      x, platform = "version", locale = "collate", matrix = "blas", document = "pandoc",
      machine = "user", git = "sha", timing = "elapsed_sec", rng = "kind", packages = "package"
    ))
  )
})

test_that("print.sessioncheck_sessionstate() forwards globalenv/globalenv_n/attachments arguments to format()", {
  x <- sessionstate()
  out <- capture.output(
    print(x, globalenv = "name", globalenv_n = 2, attachments = "name")
  )
  expect_equal(
    trimws(paste(out, collapse = "\n")),
    trimws(format(x, globalenv = "name", globalenv_n = 2, attachments = "name"))
  )
})

test_that(".select_fields() preserves canonical order regardless of requested order", {
  expect_identical(.select_fields(c("a", "b", "c"), c("c", "a"), "test"), c("a", "c"))
})

test_that(".select_fields() returns all names unchanged when requested is NULL", {
  expect_identical(.select_fields(c("a", "b"), NULL, "test"), c("a", "b"))
})

test_that(".select_fields() errors on non-character input", {
  expect_error(.select_fields(c("a", "b"), 1, "test"), "must be a character vector")
})

test_that(".select_fields() errors informatively on unknown fields", {
  expect_error(.select_fields(c("a", "b"), "z", "test"), "Unknown test field.*z.*Valid fields are: a, b")
})

test_that(".get_ui() reports 'non-interactive' regardless of .Platform$GUI when not interactive", {
  local_mocked_bindings(.is_interactive = function() FALSE)
  local_mocked_bindings(.get_platform_gui = function() "Positron")
  expect_identical(.get_ui(), "non-interactive")
})

test_that(".get_ui() reports .Platform$GUI when interactive", {
  local_mocked_bindings(.is_interactive = function() TRUE)
  local_mocked_bindings(.get_platform_gui = function() "Positron")
  expect_identical(.get_ui(), "Positron")

  local_mocked_bindings(.get_platform_gui = function() "RStudio")
  expect_identical(.get_ui(), "RStudio")
})

test_that(".get_ui() falls back to 'unknown' when .Platform$GUI is empty", {
  local_mocked_bindings(.is_interactive = function() TRUE)
  local_mocked_bindings(.get_platform_gui = function() "")
  expect_identical(.get_ui(), "unknown")
})

test_that(".get_loaded_version() returns NA for a namespace that isn't loaded", {
  local_mocked_bindings(isNamespaceLoaded = function(pkg) FALSE, .package = "base")
  expect_identical(.get_loaded_version("somepkg"), NA_character_)
})

test_that(".get_loaded_version() returns the loaded namespace version", {
  local_mocked_bindings(isNamespaceLoaded = function(pkg) TRUE, .package = "base")
  local_mocked_bindings(
    getNamespaceVersion = function(pkg) {
      structure("1.2.3", names = pkg)
    },
    .package = "base"
  )
  expect_identical(.get_loaded_version("somepkg"), "1.2.3")
})

test_that(".get_package_inventory() flags a version_mismatch when on-disk and loaded versions differ", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "2.0.0"),
    .package = "utils"
  )
  local_mocked_bindings(.get_loaded_version = function(pkg) "1.0.0")
  local_mocked_bindings(.get_package_source = function(pkg) "local")

  df <- .get_package_inventory()
  expect_true(all(df$ondisk_version == "2.0.0"))
  expect_true(all(df$loaded_version == "1.0.0"))
  expect_true(all(df$version_mismatch))
})

test_that(".get_package_inventory() does not flag a version_mismatch when versions agree", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "1.0.0"),
    .package = "utils"
  )
  local_mocked_bindings(.get_loaded_version = function(pkg) "1.0.0")
  local_mocked_bindings(.get_package_source = function(pkg) "local")

  df <- .get_package_inventory()
  expect_false(any(df$version_mismatch))
})

test_that(".get_loaded_path() special-cases 'base'", {
  local_mocked_bindings(getNamespaceInfo = function(pkg, which) stop("should not be called"), .package = "base")
  expect_identical(.get_loaded_path("base"), system.file())
})

test_that(".get_loaded_path() returns NA for a namespace that isn't loaded", {
  local_mocked_bindings(isNamespaceLoaded = function(pkg) FALSE, .package = "base")
  expect_identical(.get_loaded_path("somepkg"), NA_character_)
})

test_that(".get_loaded_path() returns the loaded namespace path", {
  local_mocked_bindings(isNamespaceLoaded = function(pkg) TRUE, .package = "base")
  local_mocked_bindings(
    getNamespaceInfo = function(pkg, which) "/some/lib/somepkg",
    .package = "base"
  )
  expect_identical(.get_loaded_path("somepkg"), "/some/lib/somepkg")
})

test_that(".get_ondisk_path() returns NA when the package isn't found on disk", {
  local_mocked_bindings(system.file = function(...) "", .package = "base")
  expect_identical(.get_ondisk_path("somepkg"), NA_character_)
})

test_that(".get_ondisk_path() prefers a loaded library that isn't on .libPaths()", {
  # mirrors library(pkg, lib.loc = <private lib>), which is how R CMD
  # check loads the package under test: the private library is never
  # added to .libPaths(), so without this fallback system.file() would
  # either miss the package entirely or resolve to an unrelated, stale
  # copy elsewhere on .libPaths()
  local_mocked_bindings(.get_loaded_path = function(pkg) "/private/lib/somepkg")
  local_mocked_bindings(
    system.file = function(package, lib.loc, ...) {
      if (identical(lib.loc[[1L]], "/private/lib")) "/private/lib/somepkg" else ""
    },
    .package = "base"
  )
  expect_identical(.get_ondisk_path("somepkg"), "/private/lib/somepkg")
})

test_that(".get_ondisk_path() leaves search order unchanged when the loaded library is already on .libPaths()", {
  local_mocked_bindings(.get_loaded_path = function(pkg) file.path(.libPaths()[[1L]], pkg))
  local_mocked_bindings(
    system.file = function(package, lib.loc, ...) {
      expect_identical(lib.loc, .libPaths())
      ""
    },
    .package = "base"
  )
  expect_identical(.get_ondisk_path("somepkg"), NA_character_)
})

test_that(".get_package_inventory() flags a path_mismatch when on-disk and loaded paths differ", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "1.0.0"),
    .package = "utils"
  )
  local_mocked_bindings(.get_loaded_version = function(pkg) "1.0.0")
  local_mocked_bindings(.get_package_source = function(pkg) "local")
  local_mocked_bindings(.get_ondisk_path = function(pkg) "/new/lib/path")
  local_mocked_bindings(.get_loaded_path = function(pkg) "/old/lib/path")
  # otherwise sessioncheck itself (loaded via load_all() during testing)
  # would be correctly excluded from the flag, breaking all()
  local_mocked_bindings(.is_load_all_package = function(pkg) FALSE)

  df <- .get_package_inventory()
  expect_true(all(df$path_mismatch))
  expect_false(any(df$removed_from_disk))
})

test_that(".get_package_inventory() does not flag load_all() packages as path_mismatch", {
  # under devtools::load_all(), system.file() resolves to inst/ while the
  # loaded namespace path is the source root; this is expected and not
  # genuine path drift (reproduces the false positive found when this was
  # first implemented, since sessioncheck itself is loaded via load_all()
  # during testing)
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "1.0.0"),
    .package = "utils"
  )
  local_mocked_bindings(.get_loaded_version = function(pkg) "1.0.0")
  local_mocked_bindings(.get_package_source = function(pkg) "load_all()")
  local_mocked_bindings(.get_ondisk_path = function(pkg) "/pkg/inst")
  local_mocked_bindings(.get_loaded_path = function(pkg) "/pkg")
  local_mocked_bindings(.is_load_all_package = function(pkg) TRUE)

  df <- .get_package_inventory()
  expect_false(any(df$path_mismatch))
})

test_that(".get_package_inventory() flags removed_from_disk when the namespace is loaded but not found on disk", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "1.0.0"),
    .package = "utils"
  )
  local_mocked_bindings(.get_loaded_version = function(pkg) "1.0.0")
  local_mocked_bindings(.get_package_source = function(pkg) "local")
  local_mocked_bindings(.get_ondisk_path = function(pkg) NA_character_)
  local_mocked_bindings(.get_loaded_path = function(pkg) "/old/lib/path")

  df <- .get_package_inventory()
  expect_true(all(df$removed_from_disk))
  expect_false(any(df$path_mismatch))
})

test_that(".get_package_source() classifies base packages", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Priority = "base"),
    .package = "utils"
  )
  expect_identical(.get_package_source("base"), "base")
})

test_that(".get_package_source() classifies CRAN packages", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(Repository = "CRAN", Built = "R 4.6.0; x86_64-pc-linux-gnu; unix")
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "CRAN (R 4.6.0)")
})

test_that(".get_package_source() classifies GitHub remotes", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "github",
        RemoteUsername = "someuser",
        RemoteRepo = "somerepo",
        RemoteSha = "abcdef1234567890"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "Github (someuser/somerepo@abcdef1)")
})

test_that(".get_package_source() classifies packages with no remote or repository metadata as local", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "0.0.1"),
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "local")
})

test_that(".get_package_source() treats RemoteType 'standard' like an ordinary install", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(RemoteType = "standard", Repository = "RSPM", Built = "R 4.6.0; x86_64; unix")
    },
    .package = "utils"
  )
  # RSPM mirrors CRAN but is not literally "CRAN": report the repository
  # name actually recorded rather than mislabeling it
  expect_identical(.get_package_source("somepkg"), "RSPM (R 4.6.0)")
})

test_that(".get_package_source() classifies renv-restored CRAN packages", {
  # renv::install()/renv::restore() also mark ordinary installs with
  # RemoteType = "standard", but (unlike pak) set RemoteSha to the package
  # *version* rather than a git SHA. That field is simply ignored once
  # RemoteType is treated as absent, so this should behave the same as any
  # other "standard" install.
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        Repository = "RSPM",
        RemoteType = "standard",
        RemoteRef = "brio",
        RemoteSha = "1.1.5",
        RemotePkgRef = "brio",
        Built = "R 4.6.0; x86_64-pc-linux-gnu; unix"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("brio"), "RSPM (R 4.6.0)")
})

test_that(".get_package_source() classifies renv-restored GitHub packages", {
  # renv::install("user/repo") records the same Remote* fields as
  # remotes/pak for GitHub installs.
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "github",
        RemoteHost = "api.github.com",
        RemoteRepo = "etal",
        RemoteUsername = "djnavarro",
        RemoteRef = "main",
        RemoteSha = "e8fafefd5927138efda95939ed7b25f36103f131",
        Built = "R 4.6.1; ; unix"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("etal"), "Github (djnavarro/etal@e8fafef)")
})

test_that(".get_package_source() classifies r-universe packages", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "standard",
        Repository = "https://someuser.r-universe.dev",
        Built = "R 4.6.1; x86_64; unix"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "r-universe (R 4.6.1)")
})

test_that(".get_package_source() classifies Bioconductor packages via biocViews", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        biocViews = "Software, GeneExpression",
        Built = "R 4.6.0; x86_64; unix"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "Bioconductor (R 4.6.0)")
})

test_that(".get_package_source() classifies remotes::install_bioc() git2r remotes", {
  # remote_metadata.bioc_git2r_remote() in {remotes} sets RemoteRepo and
  # RemoteMirror, but never RemoteUsername or RemoteUrl
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "bioc_git2r",
        RemoteMirror = "https://git.bioconductor.org/packages",
        RemoteRepo = "Biobase",
        RemoteRelease = "release",
        RemoteBranch = "RELEASE_3_23",
        RemoteSha = "65ae7a98395e50568bfb7a6b6367dcd967d89e1a",
        biocViews = "Infrastructure"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("Biobase"), "Bioconductor (Biobase@65ae7a9)")
})

test_that(".get_package_source() classifies remotes::install_bioc() xgit remotes", {
  # verified against a real remotes::install_bioc("Biobase") install (falls
  # back to plain git when git2r is unavailable); fields are the same shape
  # as bioc_git2r, with RemoteType = "bioc_xgit"
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "bioc_xgit",
        RemoteMirror = "https://git.bioconductor.org/packages",
        RemoteRepo = "Biobase",
        RemoteRelease = "release",
        RemoteBranch = "RELEASE_3_23",
        RemoteSha = "65ae7a98395e50568bfb7a6b6367dcd967d89e1a",
        biocViews = "Infrastructure"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("Biobase"), "Bioconductor (Biobase@65ae7a9)")
})

test_that(".get_package_source() classifies GitLab remotes", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "gitlab",
        RemoteUsername = "someuser",
        RemoteRepo = "somerepo",
        RemoteSha = "0123456789abcdef"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "GitLab (someuser/somerepo@0123456)")
})

test_that(".get_package_source() classifies Bitbucket remotes", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "bitbucket",
        RemoteUsername = "someuser",
        RemoteRepo = "somerepo",
        RemoteSha = "abcdef0123456789"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "Bitbucket (someuser/somerepo@abcdef0)")
})

test_that(".get_package_source() classifies generic git remotes (e.g. Codeberg) by URL", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "git",
        RemoteUrl = "https://codeberg.org/someuser/somerepo",
        RemoteSha = "fedcba9876543210"
      )
    },
    .package = "utils"
  )
  expect_identical(
    .get_package_source("somepkg"),
    "Git (https://codeberg.org/someuser/somerepo@fedcba9)"
  )
})

test_that(".get_package_source() classifies pak local installs via RemotePkgRef", {
  # pak::local_install() / pak::pkg_install("local::<path>") record the
  # install path only in RemotePkgRef (with a "local::" prefix); unlike
  # remotes::install_local(), no RemoteUrl field is set at all.
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        RemoteType = "local",
        RemotePkgRef = "local::/tmp/pak_local_test/mylocalpkg",
        Built = "R 4.6.1; ; unix"
      )
    },
    .package = "utils"
  )
  expect_identical(
    .get_package_source("mylocalpkg"),
    "local (/tmp/pak_local_test/mylocalpkg)"
  )
})

test_that(".get_package_source() classifies legacy devtools::install_github() installs", {
  # pre-RemoteType devtools versions recorded Github* fields directly
  # instead of RemoteType = "github" + Remote* fields
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(
        GithubUsername = "someuser",
        GithubRepo = "somerepo",
        GithubSHA1 = "abcdef1234567890"
      )
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "Github (someuser/somerepo@abcdef1)")
})

test_that(".get_package_source() classifies devtools::load_all() packages", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) list(Version = "0.0.1"),
    .package = "utils"
  )
  local_mocked_bindings(.is_load_all_package = function(pkg) TRUE)
  expect_identical(.get_package_source("somepkg"), "load_all()")
})

test_that(".get_package_source() falls back to the raw RemoteType label when unrecognized", {
  local_mocked_bindings(
    packageDescription = function(pkg, ...) {
      list(RemoteType = "some_future_type", RemoteSha = "1112223334445556")
    },
    .package = "utils"
  )
  expect_identical(.get_package_source("somepkg"), "some_future_type (1112223)")
})
