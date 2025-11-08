
test_that("session checkers call the validators", {
  checkers <- list(
    check_globalenv, 
    check_attachments, 
    check_packages,
    check_namespaces
  )
  for (chk in checkers) {
    expect_error(chk(action = "none", allow = 1L))
    expect_error(chk(action = "asdf", allow = NULL))
  }
  expect_error(check_sessiontime(action = "asdf", tol = NULL))
  expect_error(check_sessiontime(action = "none", tol = "asdf"))
})

test_that("session checkers match the correct internal function", {

  expect_equal(check_attachments("none"), .get_attachment_status(NULL))
  expect_equal(check_globalenv("none"), .get_globalenv_status(NULL))
  expect_equal(check_namespaces("none"), .get_namespace_status(NULL))
  expect_equal(check_packages("none"), .get_package_status(NULL))
  expect_equal( # names won't be the same
    unname(check_sessiontime("none")$status), 
    unname(.get_sessiontime_status(NULL)$status)
  )
})

test_that("sessioncheck() returns list of status vectors", {

  ss <- sessioncheck(
    action = "none", 
    checks = c("globalenv", "packages", "namespaces", "attachments"),
    settings = NULL
  )
  ii <- list(
    globalenv = check_globalenv(action = "none", allow = NULL),
    packages = check_packages(action = "none", allow = NULL),
    namespaces = check_namespaces(action = "none", allow = NULL),
    attachments = check_attachments(action = "none", allow = NULL)
  )
  class(ii) <- "sessioncheck_sessioncheck"

  expect_equal(ss, ii)
})