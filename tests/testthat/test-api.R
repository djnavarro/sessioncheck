
test_that("session checkers call the correct internal function", {

  expect_equal(check_attached_environments("none"), .get_attachment_status(NULL))
  expect_equal(check_globalenv_objects("none"), .get_globalenv_status(NULL))
  expect_equal(check_loaded_namespaces("none"), .get_namespace_status(NULL))
  expect_equal(check_attached_packages("none"), .get_package_status(NULL))
  expect_equal( # names won't be the same
    unname(check_sessiontime("none")$status), 
    unname(.get_sessiontime_status(NULL)$status)
  )
  expect_equal(check_required_options("none"), .get_options_status(NULL))
  expect_equal(check_required_sysenv("none"), .get_sysenv_status(NULL))
  expect_equal(check_required_locale("none"), .get_locale_status(NULL))
})

test_that("sessioncheck() returns a list of status checks", {

  ss <- sessioncheck(
    action = "none", 
    checks = c("globalenv_objects", "attached_packages", "loaded_namespaces", "attached_environments")
  )
  ii <- list(
    globalenv = check_globalenv_objects(action = "none", allow_globalenv_objects = NULL),
    packages = check_attached_packages(action = "none", allow_attached_packages = NULL),
    namespaces = check_loaded_namespaces(action = "none", allow_loaded_namespaces = NULL),
    attachments = check_attached_environments(action = "none", allow_attached_environments = NULL)
  )
  class(ii) <- "sessioncheck_sessioncheck"

  expect_equal(ss, ii)
})

test_that("sessioncheck() respects user options", {
  opts <- options(sessioncheck = list(action = "none", checks = c("globalenv_objects", "loaded_namespaces")))
  ss <- sessioncheck()
  ii <- list(
    globalenv = check_globalenv_objects(action = "none", allow_globalenv_objects = NULL),
    namespaces = check_loaded_namespaces(action = "none", allow_loaded_namespaces = NULL)
  )
  class(ii) <- "sessioncheck_sessioncheck"

  expect_equal(ss, ii)
  options(opts)
})
