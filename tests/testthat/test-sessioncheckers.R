test_that("returned status is a sessoncheck status object", {
  expect_s3_class(.get_attachment_status(allow = NULL), "sessioncheck_status")
  expect_s3_class(.get_globalenv_status(allow = NULL), "sessioncheck_status")
  expect_s3_class(.get_package_status(allow = NULL), "sessioncheck_status")
  expect_s3_class(.get_namespace_status(allow = NULL), "sessioncheck_status")
  expect_s3_class(.get_sessiontime_status(tol = NULL), "sessioncheck_status")
  expect_s3_class(.get_options_status(required = NULL), "sessioncheck_status")
  expect_s3_class(.get_sysenv_status(required = NULL), "sessioncheck_status")
  expect_s3_class(.get_locale_status(required = NULL), "sessioncheck_status")
})

test_that("returned status is named correctly", {
  expect_named(
    object = .get_attachment_status(allow = NULL)$status,
    expected = search()
  )
  expect_named(
    object = .get_globalenv_status(allow = NULL)$status,
    expected = ls(envir = .GlobalEnv, all.names = TRUE)
  )
  expect_named(
    object = .get_package_status(allow = NULL)$status,
    expected = .packages()
  )
  expect_named(
    object = .get_namespace_status(allow = NULL)$status,
    expected = loadedNamespaces()
  )
})

# package and namespace checks ------

test_that("base-priority packages are always allowed", {
  pp <- .get_package_status(allow = NULL)$status
  nn <- .get_namespace_status(allow = NULL)$status
  aa <- .get_attachment_status(allow = NULL)$status
  expect_false(pp["base"])
  expect_false(nn["base"])
  expect_false(aa["package:base"])
  expect_false(pp["utils"])
  expect_false(nn["utils"])
  expect_false(aa["package:utils"])
  expect_false(pp["grDevices"])
  expect_false(nn["grDevices"])
  expect_false(aa["package:grDevices"])

  pp <- .get_package_status(allow = character(0L))$status
  nn <- .get_namespace_status(allow = character(0L))$status
  aa <- .get_attachment_status(allow = character(0L))$status
  expect_false(pp["base"])
  expect_false(nn["base"])
  expect_false(aa["package:base"])
  expect_false(pp["utils"])
  expect_false(nn["utils"])
  expect_false(aa["package:utils"])
  expect_false(pp["grDevices"])
  expect_false(nn["grDevices"])
  expect_false(aa["package:grDevices"])
})

test_that("sessioncheck is always an allowed namespace", {
  nn <- .get_namespace_status(allow = NULL)$status
  expect_false(nn["sessioncheck"])

  nn <- .get_namespace_status(allow = character(0L))$status
  expect_false(nn["sessioncheck"])
})

test_that("sessioncheck is flaggable as an attached package", {
  pp <- .get_package_status(allow = NULL)$status
  expect_true(pp["sessioncheck"])

  pp <- .get_package_status(allow = character(0L))$status
  expect_true(pp["sessioncheck"])
})

# non-package attachment checks ------

test_that("global environment is always an allowed attachment", {
  aa <- .get_attachment_status(allow = NULL)$status
  expect_false(aa[".GlobalEnv"])

  aa <- .get_attachment_status(allow = character(0L))$status
  expect_false(aa[".GlobalEnv"])
})

test_that("non-package environments are flaggable", {
  attach(iris)
  aa <- .get_attachment_status(allow = NULL)$status
  expect_true(aa["iris"])

  aa <- .get_attachment_status(allow = character(0L))$status
  expect_true(aa["iris"])

  aa <- .get_attachment_status(allow = "iris")$status
  expect_false(aa["iris"])
  detach(iris)
})

# global environment checks ------

test_that("dot-prefixed variables are always detected in the global environment", {
  assign(x = ".sessioncheck_test", value = NA, envir = .GlobalEnv)

  vv <- .get_globalenv_status(allow = NULL)$status
  expect_true(".sessioncheck_test" %in% names(vv))

  vv <- .get_globalenv_status(allow = character(0L))$status
  expect_true(".sessioncheck_test" %in% names(vv))

  rm(.sessioncheck_test, envir = .GlobalEnv)
})

test_that("dot-prefixed variables are flaggable but allowed by default in the global environment", {
  assign(x = ".sessioncheck_test", value = NA, envir = .GlobalEnv)

  vv <- .get_globalenv_status(allow = NULL)$status
  expect_false(vv[".sessioncheck_test"])

  vv <- .get_globalenv_status(allow = character(0L))$status
  expect_true(vv[".sessioncheck_test"])

  rm(.sessioncheck_test, envir = .GlobalEnv)
})

test_that(".onLoad creates snapshot in .sessioncheck_env", {
  ns <- asNamespace("sessioncheck")

  if (!exists(".sessioncheck_env", envir = ns, inherits = FALSE)) {
    env_ok <- tryCatch(
      {
        assign(".sessioncheck_env", new.env(parent = emptyenv()), envir = ns)
        TRUE
      },
      error = function(e) FALSE
    )

    skip_if_not(
      env_ok,
      ".sessioncheck_env cannot be created in package namespace"
    )
  }

  # cleanup envs
  on.exit(
    {
      sc_env <- tryCatch(
        get(".sessioncheck_env", envir = ns),
        error = function(e) NULL
      )

      if (!is.null(sc_env)) {
        tryCatch(rm("snapshot", envir = sc_env), error = function(e) NULL)
      }
    },
    add = TRUE
  )

  # grab the onload fn to call it
  onload_fn <- get(".onLoad", envir = ns, inherits = FALSE)
  onload_fn(NULL, "sessioncheck")

  sc_env <- get(".sessioncheck_env", envir = ns)
  expect_true(exists("snapshot", envir = sc_env, inherits = FALSE))

  snapshot <- get("snapshot", envir = sc_env)
  expect_type(snapshot, "list")
  expect_true(all(c("sys_time", "options", "packages") %in% names(snapshot)))
})

# session runtime checks ------

test_that("session time elapsed is flaggable", {
  Sys.sleep(.01)
  expect_true(.get_sessiontime_status(tol = 0.001)$status)
  expect_false(.get_sessiontime_status(tol = Inf)$status)
})

# value checks ------

test_that("options are flaggable", {
  opts <- options(scipen = 11L)
  expect_true(.get_options_status(required = list(scipen = 10L))$status)
  expect_false(.get_options_status(required = list(scipen = 11L))$status)
  expect_true(.get_options_status(required = list(asdfasdfasdf = 10))$status)
  options(opts)
})

test_that("system environment variables are flaggable", {
  Sys.setenv(R_TEST = "sessioncheck")
  expect_true(
    .get_sysenv_status(required = list(R_TEST = "wrong value"))$status
  )
  expect_false(
    .get_sysenv_status(required = list(R_TEST = "sessioncheck"))$status
  )
  Sys.unsetenv("R_TEST")
  expect_true(
    .get_sysenv_status(required = list(R_TEST = "sessioncheck"))$status
  )
})

test_that("locale settings are flaggable", {
  skip_on_os(os = c("mac", "solaris"))
  skip_on_cran()
  old <- Sys.getlocale(category = "LC_TIME")
  Sys.setlocale(category = "LC_TIME", locale = "C")
  expect_true(
    .get_locale_status(required = list(LC_TIME = "en_US.UTF-8"))$status
  )
  expect_false(.get_locale_status(required = list(LC_TIME = "C"))$status)
  Sys.setlocale(category = "LC_TIME", locale = old)
})
