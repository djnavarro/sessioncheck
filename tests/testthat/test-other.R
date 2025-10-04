
test_that(".action() produces the requested action", {
  # action occurs if status is FALSE
  expect_error(.action(action = "error", status = FALSE))
  expect_warning(.action(action = "warn", status = FALSE))
  expect_message(.action(action = "message", status = FALSE))
  # no action occurs if status is TRUE
  expect_no_error(.action(action = "error", status = TRUE))
  expect_no_warning(.action(action = "warn", status = TRUE))
  expect_no_message(.action(action = "message", status = TRUE))
  # no action occurs if action is "none"
  expect_no_error(.action(action = "none", status = FALSE))
  expect_no_warning(.action(action = "none", status = FALSE))
  expect_no_message(.action(action = "none", status = FALSE))
})
