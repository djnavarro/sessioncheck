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
})

test_that("invalid `ignore` arguments are detected", {
  expect_error(.validate_ignore(ignore = 1L))
  expect_error(.validate_ignore(ignore = TRUE))
  expect_error(.validate_ignore(ignore = list()))
})

test_that("valid `ignore` arguments are permitted", {
  expect_no_error(.validate_ignore(ignore = NULL))
  expect_no_error(.validate_ignore(ignore = ""))
  expect_no_error(.validate_ignore(ignore = "sessioncheck"))
})

test_that(".action() produces the requested action", {
  # action occurs if status is FALSE
  expect_error(.action(action = "error", status = FALSE))
  expect_warning(.action(action = "warn", status = FALSE))
  expect_message(.action(action = "message", status = FALSE))
  # no action occurs if status is TRUE
  expect_no_error(.action(action = "error", status = TRUE))
  expect_no_warning(.action(action = "warn", status = TRUE))
  expect_no_message(.action(action = "message", status = TRUE))
})