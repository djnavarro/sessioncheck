
status_true  <- new_status(status = c(x = TRUE),  type = "globalenv")
status_false <- new_status(status = c(x = FALSE), type = "globalenv")
sessioncheck_true  <- new_sessioncheck(status_true)
sessioncheck_false <- new_sessioncheck(status_false)

test_that(".action() produces the requested action for status objects", {
  # action occurs if status is TRUE and action is requested
  expect_error(.action(action = "error", status = status_true))
  expect_warning(.action(action = "warn", status = status_true))
  expect_message(.action(action = "message", status = status_true))
  # no action occurs if status is FALSE
  expect_no_error(.action(action = "error", status = status_false))
  expect_no_warning(.action(action = "warn", status = status_false))
  expect_no_message(.action(action = "message", status = status_false))
  # no action occurs if action is "none" even if status is TRUE
  expect_no_error(.action(action = "none", status = status_true))
  expect_no_warning(.action(action = "none", status = status_true))
  expect_no_message(.action(action = "none", status = status_true))
})

test_that(".action() produces the requested action for sessioncheck objects", {
  # action occurs if status is TRUE and action is requested
  expect_error(.action(action = "error", status = sessioncheck_true))
  expect_warning(.action(action = "warn", status = sessioncheck_true))
  expect_message(.action(action = "message", status = sessioncheck_true))
  # no action occurs if status is FALSE
  expect_no_error(.action(action = "error", status = sessioncheck_false))
  expect_no_warning(.action(action = "warn", status = sessioncheck_false))
  expect_no_message(.action(action = "message", status = sessioncheck_false))
  # no action occurs if action is "none" even if status is TRUE
  expect_no_error(.action(action = "none", status = sessioncheck_true))
  expect_no_warning(.action(action = "none", status = sessioncheck_true))
  expect_no_message(.action(action = "none", status = sessioncheck_true))
})

test_that(".message_text() produces the expected text", {
  ss <- c(a = FALSE, b = TRUE, c = TRUE, d = TRUE)  
  expect_equal(.message_text("hi", ss, 5L), "hi b, c, d")
  expect_equal(.message_text("no", ss, 5L), "no b, c, d")
  expect_equal(.message_text("hi", ss, 1L), "hi b, and 2 more")
})

test_that(".get_xiny_status() returns expected integer status", {
  x <- list(a = 1L, b = 2L, c = 3L)
  y <- list(a = 1L, b = "", d = 3L)
  expect_equal(
    .get_xiny_status(x, y),
    c(a = FALSE, b = TRUE, c = TRUE)
  )
})

test_that(".session_snapshot works", {
  expect_no_error(.session_snapshot())
})

ss <- .session_snapshot()

test_that(".session_snapshot returns named list", {
  expect_true(is.list(ss))
  expect_named(ss, c(
    "sys_time",
    "options",
    "packages",
    "namespaces",
    "attached",
    "proc_time",
    "globalenv",
    "locale",
    "sys_env"
  ))
})

