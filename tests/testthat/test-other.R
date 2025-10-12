
test_that(".action() produces the requested action", {
  # action occurs if status is TRUE and action is requested
  expect_error(.action(action = "error", status = TRUE))
  expect_warning(.action(action = "warn", status = TRUE))
  expect_message(.action(action = "message", status = TRUE))
  # no action occurs if status is FALSE
  expect_no_error(.action(action = "error", status = FALSE))
  expect_no_warning(.action(action = "warn", status = FALSE))
  expect_no_message(.action(action = "message", status = FALSE))
  # no action occurs if action is "none" even if status is TRUE
  expect_no_error(.action(action = "none", status = TRUE))
  expect_no_warning(.action(action = "none", status = TRUE))
  expect_no_message(.action(action = "none", status = TRUE))
})


test_that(".message_text() produces the expected text", {
  ss <- c(a = FALSE, b = TRUE, c = TRUE, d = TRUE)  
  expect_equal(.message_text("hi", ss, 5L), "hi b, c, d")
  expect_equal(.message_text("no", ss, 5L), "no b, c, d")
  expect_equal(.message_text("hi", ss, 1L), "hi b, and 2 more")
})