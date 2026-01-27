
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

test_that("sessioncheck() returns a warning if args$action is NULL (the default)", {
  expect_warning(sessioncheck())
})

test_that("sessioncheck `checks` argument returns expected results", {
  checks_to_test <- c("sessiontime", "required_options", "required_locale", "required_sysenv")

  #sessiontime - Specified time expected
  mock_sessiontime_status <- list(status = c("Session runtime: 86753.09 sec elapsed" = TRUE), type = "sessiontime")
  class(mock_sessiontime_status) <- "sessioncheck_status"
  local_mocked_bindings(.get_sessiontime_status = function(max_sessiontime) mock_sessiontime_status)

  #requiredoptions - Issue expected
  options(print.max = 9000L)
  opts_check <- list(print.max = 500)
  opts_res <- c("print.max" = TRUE)

  #required_locale - Issue -not- expected
  # Pick up here -> debug to track locale movement thru fx
  mock_get_locale <- "LC_TIME=Spanish_United States.utf8"
  local_mocked_bindings(.get_locale_status = function(required_locale) "LC_TIME=Spanish_United States.utf8")
  locale_check <- list(LC_TIME = "Spanish_United States.utf8")
  locale_res <- c("LC_TIME" = FALSE)

  #required_sysenv - Issue expected
  mandatory_object <- "I should be here"
  sysenv_check <- list(mandatory_object = "I should also be here")
  sysenv_res <- c("mandatory_object" = TRUE)

  res <- sessioncheck(
    action = "none",
    checks = checks_to_test,
    required_options = opts_check,
    required_locale = locale_check,
    required_sysenv = sysenv_check 
  )

  expect_equal(names(res$sessiontime$status), "Session runtime: 86753.09 sec elapsed")
  expect_equal(res$options$status, opts_res)
  expect_equal(res$locale$status, locale_res)
  expect_equal(res$sysenv$status, sysenv_res)
}
)

