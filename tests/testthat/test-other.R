
status_true  <- new_status(status = c(x = TRUE),  type = "globalenv")
status_false <- new_status(status = c(x = FALSE), type = "globalenv")
sessioncheck_true  <- new_sessioncheck(status_true)
sessioncheck_false <- new_sessioncheck(status_false)

test_that(".action() errors on unexpected status class", {
  bad_status <- structure(list(), class = "not_a_status")
  expect_error(.action("warn", bad_status), regexp = "unexpected status class")
})

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

test_that(".message_text() prefixes with a cross symbol when issues are found", {
  ss <- c(a = FALSE, b = TRUE, c = TRUE, d = TRUE)

  local_mocked_bindings(.unicode_enabled = function() FALSE, .ansi_enabled = function() FALSE)
  expect_equal(.message_text("hi", ss, 5L), "x hi b, c, d")
  expect_equal(.message_text("no", ss, 5L), "x no b, c, d")
  expect_equal(.message_text("hi", ss, 1L), "x hi b, and 2 more")

  local_mocked_bindings(.unicode_enabled = function() TRUE, .ansi_enabled = function() FALSE)
  expect_equal(.message_text("hi", ss, 5L), "\u2716 hi b, c, d")
})

test_that(".message_text() prefixes with a tick symbol when no issues are found", {
  ss <- c(a = FALSE, b = FALSE)

  local_mocked_bindings(.unicode_enabled = function() FALSE, .ansi_enabled = function() FALSE)
  expect_equal(.message_text("hi", ss), "v hi [no issues detected]")

  local_mocked_bindings(.unicode_enabled = function() TRUE, .ansi_enabled = function() FALSE)
  expect_equal(.message_text("hi", ss), "\u2714 hi [no issues detected]")
})

test_that(".message_text() colors the symbol when ansi is enabled", {
  ss_issue <- c(a = TRUE)
  ss_clean <- c(a = FALSE)

  local_mocked_bindings(.unicode_enabled = function() FALSE, .ansi_enabled = function() TRUE)
  expect_equal(.message_text("hi", ss_issue), "\033[31mx\033[0m hi a")
  expect_equal(.message_text("hi", ss_clean), "\033[32mv\033[0m hi [no issues detected]")
})

test_that(".symbol() falls back to ASCII when unicode is unavailable", {
  local_mocked_bindings(.unicode_enabled = function() FALSE)
  expect_equal(.symbol("tick"), "v")
  expect_equal(.symbol("cross"), "x")
})

test_that(".symbol() returns unicode glyphs when unicode is available", {
  local_mocked_bindings(.unicode_enabled = function() TRUE)
  expect_equal(.symbol("tick"), "\u2714")
  expect_equal(.symbol("cross"), "\u2716")
})

test_that(".ansi_enabled() honors options(cli.num_colors = )", {
  # cli.num_colors is checked before NO_COLOR/isatty, so it takes precedence
  # regardless of the environment this test happens to run in
  old <- options(cli.num_colors = 8L)
  on.exit(options(old), add = TRUE)
  expect_true(.ansi_enabled())

  options(cli.num_colors = 1L)
  expect_false(.ansi_enabled())
})

# the remaining .ansi_enabled() tests exercise checks that come after
# cli.num_colors/NO_COLOR, so these must be neutralized first (including the
# RStudio console signal, which would otherwise short-circuit the isatty
# fallback tests); returns a restore function so each test can register its
# own on.exit() cleanup, rather than depending on the ambient environment
.reset_ansi_precedence <- function() {
  old_opt <- options(cli.num_colors = NULL)
  env_vars <- c("NO_COLOR", "RSTUDIO", "RSTUDIO_CONSOLE_COLOR")
  old_env <- Sys.getenv(env_vars, unset = NA, names = TRUE)
  Sys.unsetenv(env_vars)
  function() {
    options(old_opt)
    to_restore <- !is.na(old_env)
    if (any(to_restore)) do.call(Sys.setenv, as.list(old_env[to_restore]))
    Sys.unsetenv(env_vars[!to_restore])
  }
}

test_that(".ansi_enabled() honors the NO_COLOR standard", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)
  Sys.setenv(NO_COLOR = "1")
  expect_false(.ansi_enabled())
})

test_that(".ansi_enabled() treats knitr rendering as non-interactive", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)
  old <- options(knitr.in.progress = TRUE)
  on.exit(options(old), add = TRUE)
  expect_false(.ansi_enabled())
})

test_that(".ansi_enabled() disables color when output is captured", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)
  local_mocked_bindings(sink.number = function() 1L, .package = "base")
  expect_false(.ansi_enabled())
})

test_that(".ansi_enabled() falls back to isatty(stdout()) otherwise", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)
  local_mocked_bindings(sink.number = function() 0L, isatty = function(con) TRUE, .package = "base")
  expect_true(.ansi_enabled())

  local_mocked_bindings(sink.number = function() 0L, isatty = function(con) FALSE, .package = "base")
  expect_false(.ansi_enabled())
})

test_that(".rstudio_console_with_color() requires both RSTUDIO and a numeric RSTUDIO_CONSOLE_COLOR", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)

  # neither set
  expect_false(.rstudio_console_with_color())

  # RSTUDIO alone (e.g. Terminal pane, Build pane, or an RStudio Job)
  Sys.setenv(RSTUDIO = "1")
  expect_false(.rstudio_console_with_color())

  # RSTUDIO_CONSOLE_COLOR alone should not occur in practice, but shouldn't count either
  Sys.unsetenv("RSTUDIO")
  Sys.setenv(RSTUDIO_CONSOLE_COLOR = "256")
  expect_false(.rstudio_console_with_color())

  # both set, as RStudio's Console pane does
  Sys.setenv(RSTUDIO = "1")
  expect_true(.rstudio_console_with_color())

  # a non-numeric RSTUDIO_CONSOLE_COLOR should not count
  Sys.setenv(RSTUDIO_CONSOLE_COLOR = "")
  expect_false(.rstudio_console_with_color())
})

test_that(".ansi_enabled() honors the RStudio console color signal even when isatty(stdout()) is FALSE", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)
  local_mocked_bindings(sink.number = function() 0L, isatty = function(con) FALSE, .package = "base")

  Sys.setenv(RSTUDIO = "1", RSTUDIO_CONSOLE_COLOR = "256")
  expect_true(.ansi_enabled())
})

test_that(".ansi_enabled() ignores RSTUDIO outside the Console pane", {
  restore <- .reset_ansi_precedence()
  on.exit(restore(), add = TRUE)
  local_mocked_bindings(sink.number = function() 0L, isatty = function(con) FALSE, .package = "base")

  Sys.setenv(RSTUDIO = "1")
  expect_false(.ansi_enabled())
})

test_that(".ansi_style() wraps text in the given SGR code only when ansi is enabled", {
  style <- .ansi_style("31")

  local_mocked_bindings(.ansi_enabled = function() TRUE)
  expect_equal(style("hi"), "\033[31mhi\033[0m")

  local_mocked_bindings(.ansi_enabled = function() FALSE)
  expect_equal(style("hi"), "hi")
})

test_that(".col_green() and .col_red() apply the expected SGR codes", {
  local_mocked_bindings(.ansi_enabled = function() TRUE)
  expect_equal(.col_green("hi"), "\033[32mhi\033[0m")
  expect_equal(.col_red("hi"), "\033[31mhi\033[0m")
})

test_that(".colored_symbol() colors tick green and cross red when ansi is enabled", {
  local_mocked_bindings(.ansi_enabled = function() TRUE, .unicode_enabled = function() TRUE)
  # unicode and octal escapes cannot be mixed within a single string literal
  expect_equal(.colored_symbol("tick"), paste0("\033[32m", "\u2714", "\033[0m"))
  expect_equal(.colored_symbol("cross"), paste0("\033[31m", "\u2716", "\033[0m"))
})

test_that(".colored_symbol() returns a plain symbol when ansi is disabled", {
  local_mocked_bindings(.ansi_enabled = function() FALSE, .unicode_enabled = function() FALSE)
  expect_equal(.colored_symbol("tick"), "v")
  expect_equal(.colored_symbol("cross"), "x")
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

