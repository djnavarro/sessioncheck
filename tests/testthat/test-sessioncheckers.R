test_that("returned status is logical", {
  expect_type(.get_attachment_status(allow = NULL), "logical")
  expect_type(.get_globalenv_status(allow = NULL), "logical")
  expect_type(.get_package_status(allow = NULL), "logical")
  expect_type(.get_namespace_status(allow = NULL), "logical")
})

test_that("returned status is named", {
  expect_named(
    object = .get_attachment_status(allow = NULL), 
    expected = search()
  )
  expect_named(
    object = .get_globalenv_status(allow = NULL), 
    expected = ls(envir = .GlobalEnv, all.names = TRUE)
  )
  expect_named( 
    object = .get_package_status(allow = NULL), 
    expected = .packages()
  )
  expect_named(
    object = .get_namespace_status(allow = NULL), 
    expected = loadedNamespaces()
  )
})

# package and namespace checks ------

test_that("base-priority packages are always allowed", {
  pp <- .get_package_status(allow = NULL)
  nn <- .get_namespace_status(allow = NULL)
  aa <- .get_attachment_status(allow = NULL)
  expect_true(pp["base"])
  expect_true(nn["base"])
  expect_true(aa["package:base"])
  expect_true(pp["utils"])
  expect_true(nn["utils"])
  expect_true(aa["package:utils"])
  expect_true(pp["grDevices"])
  expect_true(nn["grDevices"])
  expect_true(aa["package:grDevices"])

  pp <- .get_package_status(allow = character(0L))
  nn <- .get_namespace_status(allow = character(0L))
  aa <- .get_attachment_status(allow = character(0L))
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

test_that("sessioncheck is always an allowed namespace", {
  nn <- .get_namespace_status(allow = NULL)
  expect_true(nn["sessioncheck"])

  nn <- .get_namespace_status(allow = character(0L))
  expect_true(nn["sessioncheck"])
})

test_that("sessioncheck is flaggable as an attached package", {
  pp <- .get_package_status(allow = NULL)
  expect_false(pp["sessioncheck"])

  pp <- .get_package_status(allow = character(0L))
  expect_false(pp["sessioncheck"])
})

# non-package attachment checks ------

test_that("global environment is always an allowed attachment", {
  aa <- .get_attachment_status(allow = NULL)
  expect_true(aa[".GlobalEnv"])

  aa <- .get_attachment_status(allow = character(0L))
  expect_true(aa[".GlobalEnv"])
})

test_that("non-package environments are flaggable", {
  attach(iris)
  aa <- .get_attachment_status(allow = NULL)
  expect_false(aa["iris"])

  aa <- .get_attachment_status(allow = character(0L))
  expect_false(aa["iris"])

  aa <- .get_attachment_status(allow = "iris")
  expect_true(aa["iris"])
  detach(iris)
})

# global environment checks ------

test_that("dot-prefixed variables are always detected in the global environment", {
  assign(x = ".sessioncheck_test", value = NA, envir = .GlobalEnv)

  vv <- .get_globalenv_status(allow = NULL)
  expect_true(".sessioncheck_test" %in% names(vv))

  vv <- .get_globalenv_status(allow = character(0L))
  expect_true(".sessioncheck_test" %in% names(vv))
 
  rm(.sessioncheck_test, envir = .GlobalEnv)
})

test_that("dot-prefixed variables are flaggable but allowed by default in the global environment", {
  assign(x = ".sessioncheck_test", value = NA, envir = .GlobalEnv)

  vv <- .get_globalenv_status(allow = NULL)
  expect_true(vv[".sessioncheck_test"])

  vv <- .get_globalenv_status(allow = character(0L))
  expect_false(vv[".sessioncheck_test"])
 
  rm(.sessioncheck_test, envir = .GlobalEnv)  
})

