
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

  mock_proc_time <- function() c(user = 0, system = 0, elapsed = 86753.09) #sessiontime
  local_mocked_bindings(proc.time = mock_proc_time, .package = "base") #sessiontime
  options(print.max = 9000L) #required_options
  mock_get_locale <- function() "LC_COLLATE=Spanish_United States.utf8;LC_CTYPE=Spanish_United States.utf8;LC_MONETARY=Spanish_United States.utf8;LC_NUMERIC=C;LC_TIME=Spanish_United States.utf8" #required_locale
  local_mocked_bindings(Sys.getlocale, .package = "base") #required_locale
  
  res <- sessioncheck(checks = checks_to_test)

  # TO DO: Add other checks and investigate locale setting console messaging
  expect_true(any(grepl("86753.09 sec elapsed", names(res$sessiontime$status))))


})
