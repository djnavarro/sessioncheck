test_that("invalid `action` arguments are detected", {
  expect_error(.validate_action(action = NULL))
  expect_error(.validate_action(action = "dffgsdf"))
  expect_error(.validate_action(action = c("warn", "error")))
  expect_error(.validate_action(action = 1L))
})

test_that("valid `action` arguments are permitted", {
  expect_no_error(.validate_action(action = "warn"))
  expect_no_error(.validate_action(action = "error"))
  expect_no_error(.validate_action(action = "message"))
  expect_no_error(.validate_action(action = "none"))
})

test_that("invalid `allow` arguments are detected", {
  expect_error(.validate_allow(allow = 1L))
  expect_error(.validate_allow(allow = TRUE))
  expect_error(.validate_allow(allow = list()))
})

test_that("valid `allow` arguments are permitted", {
  expect_no_error(.validate_allow(allow = NULL))
  expect_no_error(.validate_allow(allow = ""))
  expect_no_error(.validate_allow(allow = "sessioncheck"))
})

test_that("invalid `tol` arguments are detected", {
  expect_error(.validate_tol(tol = "asdf"))
  expect_error(.validate_tol(tol = TRUE))
  expect_error(.validate_tol(tol = list()))
  expect_error(.validate_tol(tol = c(123, 456)))
})

test_that("valid `tol` arguments are permitted", {
  expect_no_error(.validate_tol(tol = NULL))
  expect_no_error(.validate_tol(tol = 123.45))
  expect_no_error(.validate_tol(tol = 123L))
  expect_no_error(.validate_tol(tol = Inf))
})

test_that("invalid `checks` arguments are detected", {
  expect_error(.validate_checks(checks = 1L))
  expect_error(.validate_checks(checks = "typo_check"))
  expect_error(.validate_checks(checks = c("globalenv_objects", "typo_check")))
})

test_that("valid `checks` arguments are permitted", {
  expect_no_error(.validate_checks(checks = NULL))
  expect_no_error(.validate_checks(checks = "globalenv_objects"))
  expect_no_error(.validate_checks(checks = c("globalenv_objects", "attached_packages")))
  expect_no_error(.validate_checks(checks = c(
    "globalenv_objects", "attached_packages", "loaded_namespaces",
    "attached_environments", "sessiontime", "required_options",
    "required_locale", "required_sysenv"
  )))
})

test_that("invalid `required` arguments are detected", {
  expect_error(.validate_required(required = "a"))         # not a list
  expect_error(.validate_required(required = 1L))          # not a list
  expect_error(.validate_required(required = list(1L)))    # unnamed
  expect_error(.validate_required(required = list("a")))   # unnamed
  expect_error(.validate_required(required = list(a = 1L, 2L)))  # partially unnamed (empty name)
})

test_that("valid `required` arguments are permitted", {
  expect_no_error(.validate_required(required = NULL))
  expect_no_error(.validate_required(required = list()))
  expect_no_error(.validate_required(required = list(a = 1L)))
  expect_no_error(.validate_required(required = list(a = 1L, b = "x")))
})