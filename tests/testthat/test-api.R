
test_that("session checkers call the correct internal function", {

  expect_equal(check_attached_environments("none"), .get_attachment_status(NULL))
  expect_equal(check_globalenv_objects("none"), .get_globalenv_status(NULL))
  expect_equal(check_loaded_namespaces("none"), .get_namespace_status(NULL))
  expect_equal(check_attached_packages("none"), .get_package_status(NULL))
  expect_equal( # names/elapsed/threshold attributes differ between the two
    # independent .get_sessiontime_status() calls (real elapsed time
    # varies), so compare only the bare TRUE/FALSE value
    as.logical(check_sessiontime("none")$status),
    as.logical(.get_sessiontime_status(NULL)$status)
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

test_that("sessioncheck() validates options(sessioncheck = ...) before merging", {
  opts <- options(sessioncheck = "not a list")
  expect_error(sessioncheck())
  options(opts)
})

test_that("sessioncheck() tolerates options(sessioncheck = NULL)", {
  opts <- options(sessioncheck = NULL)
  expect_no_error(sessioncheck(action = "none"))
  options(opts)
})

test_that("check_*() functions default to action_on_pass = \"none\" (silent on a clean pass)", {
  expect_no_message(check_attached_packages(action = "none", allow_attached_packages = .packages()))
  expect_no_message(check_loaded_namespaces(action = "none", allow_loaded_namespaces = loadedNamespaces()))
  expect_no_message(check_globalenv_objects(
    action = "none",
    allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE)
  ))
  expect_no_message(check_attached_environments(action = "none", allow_attached_environments = search()))
  expect_no_message(check_sessiontime(action = "none", max_sessiontime = Inf))
  expect_no_message(check_required_options(
    action = "none",
    required_options = list(digits = getOption("digits"))
  ))
  expect_no_message(check_required_locale(
    action = "none",
    required_locale = list(LC_COLLATE = Sys.getlocale("LC_COLLATE"))
  ))
  expect_no_message(check_required_sysenv(
    action = "none",
    required_sysenv = list(R_HOME = Sys.getenv("R_HOME"))
  ))
})

test_that("check_*() functions confirm a clean pass when action_on_pass = \"message\"", {
  expect_message(check_attached_packages(
    action = "none", allow_attached_packages = .packages(), action_on_pass = "message"
  ))
  expect_message(check_loaded_namespaces(
    action = "none", allow_loaded_namespaces = loadedNamespaces(), action_on_pass = "message"
  ))
  expect_message(check_globalenv_objects(
    action = "none",
    allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
    action_on_pass = "message"
  ))
  expect_message(check_attached_environments(
    action = "none", allow_attached_environments = search(), action_on_pass = "message"
  ))
  expect_message(check_sessiontime(action = "none", max_sessiontime = Inf, action_on_pass = "message"))
  expect_message(check_required_options(
    action = "none",
    required_options = list(digits = getOption("digits")),
    action_on_pass = "message"
  ))
  expect_message(check_required_locale(
    action = "none",
    required_locale = list(LC_COLLATE = Sys.getlocale("LC_COLLATE")),
    action_on_pass = "message"
  ))
  expect_message(check_required_sysenv(
    action = "none",
    required_sysenv = list(R_HOME = Sys.getenv("R_HOME")),
    action_on_pass = "message"
  ))
})

test_that("check_*() functions do not confirm when the status is unclean, even with action_on_pass = \"message\"", {
  expect_no_message(suppressWarnings(check_attached_packages(
    action = "warn", allow_attached_packages = character(0L), action_on_pass = "message"
  )))
})

test_that("check_*() functions validate `action_on_pass`", {
  expect_error(check_attached_packages(action_on_pass = "warn"))
  expect_error(check_loaded_namespaces(action_on_pass = "warn"))
  expect_error(check_globalenv_objects(action_on_pass = "warn"))
  expect_error(check_attached_environments(action_on_pass = "warn"))
  expect_error(check_sessiontime(action_on_pass = "warn"))
  expect_error(check_required_options(action_on_pass = "warn"))
  expect_error(check_required_locale(action_on_pass = "warn"))
  expect_error(check_required_sysenv(action_on_pass = "warn"))
})

test_that("sessioncheck() defaults to action_on_pass = \"none\" (silent on a clean pass)", {
  expect_no_message(sessioncheck(
    action = "none",
    allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
    allow_attached_packages = .packages(),
    allow_attached_environments = search()
  ))
})

test_that("sessioncheck() confirms a clean pass when action_on_pass = \"message\"", {
  expect_message(sessioncheck(
    action = "none",
    allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
    allow_attached_packages = .packages(),
    allow_attached_environments = search(),
    action_on_pass = "message"
  ))
})

test_that("sessioncheck() respects action_on_pass set via options()", {
  opts <- options(sessioncheck = list(
    action = "none",
    action_on_pass = "message",
    allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
    allow_attached_packages = .packages(),
    allow_attached_environments = search()
  ))
  expect_message(sessioncheck())
  options(opts)
})

test_that("an explicit action_on_pass argument overrides options(sessioncheck = ...)", {
  opts <- options(sessioncheck = list(
    action = "none",
    action_on_pass = "message",
    allow_globalenv_objects = ls(envir = .GlobalEnv, all.names = TRUE),
    allow_attached_packages = .packages(),
    allow_attached_environments = search()
  ))
  expect_no_message(sessioncheck(action_on_pass = "none"))
  options(opts)
})

test_that("sessioncheck() validates `action_on_pass`", {
  expect_error(sessioncheck(action_on_pass = "warn"))
})

test_that("sessioncheck `checks` argument returns expected results", {
  checks_to_test <- c("sessiontime", "required_options", "required_locale", "required_sysenv")

  #sessiontime - Specified time expected
  mock_sessiontime_status <- list(status = c("Session runtime: 86753.09 sec elapsed" = TRUE), type = "sessiontime")
  class(mock_sessiontime_status) <- "sessioncheck_status"
  local_mocked_bindings(.get_sessiontime_status = function(max_sessiontime) mock_sessiontime_status)
  sessiontime_res <- c("Session runtime: 86753.09 sec elapsed" = TRUE)

  #requiredoptions - Issue expected
  options(print.max = 9000L)
  opts_check <- list(print.max = 500)
  opts_res <- c("print.max" = TRUE)

  #required_locale - Issue -not- expected
  mock_locale_status <- new_status(status = c(LC_TIME = FALSE), type = "locale")
  local_mocked_bindings(.get_locale_status = function(required_locale) mock_locale_status)
  locale_check <- list(LC_TIME = "Spanish_United States.utf8")

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

  # .get_options_status()/.get_sysenv_status() now attach expected/actual/
  # present detail attributes (see #5) that aren't relevant to this test
  options_status <- res$options$status
  attributes(options_status)[c("expected", "actual", "present")] <- NULL
  sysenv_status <- res$sysenv$status
  attributes(sysenv_status)[c("expected", "actual", "present")] <- NULL

  expect_equal(res$sessiontime$status, sessiontime_res)
  expect_equal(options_status, opts_res)
  expect_equal(res$locale, mock_locale_status)
  expect_equal(sysenv_status, sysenv_res)
}
)

