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
  expect_identical(.get_package_source("somepkg"), "CRAN (R 4.6.0)")
})
