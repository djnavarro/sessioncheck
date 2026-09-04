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
  expect_named(df, c("package", "attached", "version", "source"))
  expect_true("base" %in% df$package)
  expect_true("sessioncheck" %in% df$package)
  expect_true(is.logical(df$attached))
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

test_that(".get_ui() reports 'non-interactive' regardless of .Platform$GUI when not interactive", {
  local_mocked_bindings(interactive = function() FALSE, .package = "base")
  local_mocked_bindings(.get_platform_gui = function() "Positron")
  expect_identical(.get_ui(), "non-interactive")
})

test_that(".get_ui() reports .Platform$GUI when interactive", {
  local_mocked_bindings(interactive = function() TRUE, .package = "base")
  local_mocked_bindings(.get_platform_gui = function() "Positron")
  expect_identical(.get_ui(), "Positron")

  local_mocked_bindings(.get_platform_gui = function() "RStudio")
  expect_identical(.get_ui(), "RStudio")
})

test_that(".get_ui() falls back to 'unknown' when .Platform$GUI is empty", {
  local_mocked_bindings(interactive = function() TRUE, .package = "base")
  local_mocked_bindings(.get_platform_gui = function() "")
  expect_identical(.get_ui(), "unknown")
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
