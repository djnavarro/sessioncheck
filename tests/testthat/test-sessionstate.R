test_that("sessionstate() returns a well-formed sessioncheck_sessionstate object", {
  x <- sessionstate()
  expect_s3_class(x, "sessioncheck_sessionstate")
  expect_named(x, c("platform", "machine", "timing", "packages"))
  expect_true(is.list(x$platform))
  expect_true(is.list(x$machine))
  expect_true(is.list(x$timing))
  expect_s3_class(x$packages, "data.frame")
})

test_that("as.data.frame.sessioncheck_sessionstate() returns the package inventory", {
  x <- sessionstate()
  df <- as.data.frame(x)
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
  expect_match(txt, "matrix products", fixed = TRUE)
  expect_match(txt, "nodename", fixed = TRUE)
  expect_match(txt, "captured at", fixed = TRUE)
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
  expect_no_match(txt, "matrix products", fixed = TRUE)
  expect_no_match(txt, "nodename", fixed = TRUE)
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
  expect_no_match(txt, "matrix products", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() shows the matrix products heading only when blas/lapack are requested", {
  x <- sessionstate()
  txt_with <- format(x, platform = c("version", "blas"))
  txt_without <- format(x, platform = "version")
  expect_match(txt_with, "matrix products", fixed = TRUE)
  expect_no_match(txt_without, "matrix products", fixed = TRUE)
})

test_that("format.sessioncheck_sessionstate() restricts machine and timing fields when requested", {
  x <- sessionstate()
  txt <- format(x, machine = "user", timing = "elapsed_sec")
  expect_no_match(txt, "nodename", fixed = TRUE)
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
  expect_error(format(x, machine = "bogus"), "Unknown machine field")
  expect_error(format(x, timing = "bogus"), "Unknown timing field")
  expect_error(format(x, packages = "bogus"), "Unknown packages field")
})

test_that("format.sessioncheck_sessionstate() defaults to showing every field when NULL", {
  x <- sessionstate()
  expect_identical(format(x), format(x, platform = NULL, machine = NULL, timing = NULL, packages = NULL))
})

test_that("print.sessioncheck_sessionstate() forwards field-selection arguments to format()", {
  x <- sessionstate()
  out <- capture.output(print(x, platform = "version", machine = "user", timing = "elapsed_sec", packages = "package"))
  expect_equal(
    trimws(paste(out, collapse = "\n")),
    trimws(format(x, platform = "version", machine = "user", timing = "elapsed_sec", packages = "package"))
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
