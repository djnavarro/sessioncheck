test_that("returned status is logical", {
  expect_type(.get_attachment_status(ignore = NULL), "logical")
  expect_type(.get_globalenv_status(ignore = NULL), "logical")
  expect_type(.get_package_status(ignore = NULL), "logical")
  expect_type(.get_namespace_status(ignore = NULL), "logical")
})

test_that("returned status is named", {
  expect_named(
    object = .get_attachment_status(ignore = NULL), 
    expected = search()
  )
  expect_named(
    object = .get_globalenv_status(ignore = NULL), 
    expected = ls(envir = .GlobalEnv, all.names = TRUE)
  )
  expect_named( 
    object = .get_package_status(ignore = NULL), 
    expected = .packages()
  )
  expect_named(
    object = .get_namespace_status(ignore = NULL), 
    expected = loadedNamespaces()
  )
})

# package and namespace checks ------

test_that("base-priority packages are always ignored", {
  pp <- .get_package_status(ignore = NULL)
  nn <- .get_namespace_status(ignore = NULL)
  aa <- .get_attachment_status(ignore = NULL)
  expect_true(pp["base"])
  expect_true(nn["base"])
  expect_true(aa["package:base"])
  expect_true(pp["utils"])
  expect_true(nn["utils"])
  expect_true(aa["package:utils"])
  expect_true(pp["grDevices"])
  expect_true(nn["grDevices"])
  expect_true(aa["package:grDevices"])

  pp <- .get_package_status(ignore = character(0L))
  nn <- .get_namespace_status(ignore = character(0L))
  aa <- .get_attachment_status(ignore = character(0L))
  expect_true(pp["base"])
  expect_true(nn["base"])
  expect_true(aa["package:base"])
  expect_true(pp["utils"])
  expect_true(nn["utils"])
  expect_true(aa["package:utils"])
  expect_true(pp["grDevices"])
  expect_true(nn["grDevices"])
  expect_true(aa["package:grDevices"])
})

test_that("sessioncheck is always an ignored namespace", {
  nn <- .get_namespace_status(ignore = NULL)
  expect_true(nn["sessioncheck"])

  nn <- .get_namespace_status(ignore = character(0L))
  expect_true(nn["sessioncheck"])
})

test_that("sessioncheck is flaggable as an attached package", {
  pp <- .get_package_status(ignore = NULL)
  expect_false(pp["sessioncheck"])

  pp <- .get_package_status(ignore = character(0L))
  expect_false(pp["sessioncheck"])
})

# non-package attachment checks ------

test_that("global environment is always an ignored attachment", {
  aa <- .get_attachment_status(ignore = NULL)
  expect_true(aa[".GlobalEnv"])

  aa <- .get_attachment_status(ignore = character(0L))
  expect_true(aa[".GlobalEnv"])
})

test_that("non-package environments are flaggable", {
  attach(iris)
  aa <- .get_attachment_status(ignore = NULL)
  expect_false(aa["iris"])

  aa <- .get_attachment_status(ignore = character(0L))
  expect_false(aa["iris"])

  aa <- .get_attachment_status(ignore = "iris")
  expect_true(aa["iris"])
  detach(iris)
})

# global environment checks ------

test_that("dot-prefixed variables are always detected in the global environment", {
  assign(x = ".sessioncheck_test", value = NA, envir = .GlobalEnv)

  vv <- .get_globalenv_status(ignore = NULL)
  expect_true(".sessioncheck_test" %in% names(vv))

  vv <- .get_globalenv_status(ignore = character(0L))
  expect_true(".sessioncheck_test" %in% names(vv))
 
  rm(.sessioncheck_test, envir = .GlobalEnv)
})

test_that("dot-prefixed variables are flaggable but ignored by default in the global environment", {
  assign(x = ".sessioncheck_test", value = NA, envir = .GlobalEnv)

  vv <- .get_globalenv_status(ignore = NULL)
  expect_true(vv[".sessioncheck_test"])

  vv <- .get_globalenv_status(ignore = character(0L))
  expect_false(vv[".sessioncheck_test"])
 
  rm(.sessioncheck_test, envir = .GlobalEnv)  
})

# omnibus session check ------

test_that("check_session() returns list of status vectors", {

  ss <- check_session(
    action = "none", 
    checks = c("globalenv", "packages", "namespaces", "attachments"),
    settings = NULL
  )
  ii <- list(
    globalenv = check_globalenv(action = "none", ignore = NULL),
    packages = check_packages(action = "none", ignore = NULL),
    namespaces = check_namespaces(action = "none", ignore = NULL),
    attachments = check_attachments(action = "none", ignore = NULL)
  )

  expect_equal(ss, ii)
})