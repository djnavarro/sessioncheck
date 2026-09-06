test_that("constructors work for valid input", {
  expect_no_error(new_status(status = c(x = TRUE), type = "globalenv"))
  expect_no_error(new_sessioncheck(new_status(status = c(x = TRUE), type = "globalenv")))
})

gg <- new_status(status = c(x = TRUE), type = "globalenv")  
nm <- new_status(status = c(x = TRUE), type = "namespace") 
pac <- new_status(status = c(x = TRUE), type = "package")
att <- new_status(status = c(x = TRUE), type = "attachment")
st <- new_status(status = c(x = TRUE), type = "sessiontime")
opt <- new_status(status = c(x = TRUE), type = "options")
syse <- new_status(status = c(x = TRUE), type = "sysenv")
loc <- new_status(status = c(x = TRUE), type = "locale")
ss <- new_sessioncheck(gg, nm, pac, att, st, opt, syse, loc)

test_that("constructors return objects with expected structure", {
  expect_s3_class(gg, "sessioncheck_status")
  expect_s3_class(ss, "sessioncheck_sessioncheck")
  expect_named(gg, c("status", "type"))
})

test_that("print methods return formatted objects", {
  expect_equal(capture.output(print(gg)), format(gg))
  expect_equal(capture.output(print(nm)), format(nm))
  expect_equal(capture.output(print(pac)), format(pac))
  expect_equal(capture.output(print(att)), format(att))
  expect_equal(capture.output(print(st)), format(st))
  expect_equal(capture.output(print(opt)), format(opt))
  expect_equal(capture.output(print(syse)), format(syse))
  expect_equal(capture.output(print(loc)), format(loc))
})

test_that("print methods invisibly return original objects", {
  expect_equal(print(gg), gg)
  expect_equal(print(ss), ss)
})

test_that("format.sessioncheck_status() uses missing/expected/got detail for options/locale/sysenv when available (#5)", {
  opt_detail <- new_status(status = .get_xiny_status(list(scipen = 5L, OutDec = "."), list(scipen = 0L)), type = "options")
  loc_detail <- new_status(status = .get_xiny_status(list(LC_TIME = "en_US.UTF-8"), list()), type = "locale")
  sysenv_detail <- new_status(status = .get_xiny_status(list(R_TEST = "x"), list(R_TEST = "y")), type = "sysenv")

  expect_match(format(opt_detail), "scipen: expected 5, got 0", fixed = TRUE)
  expect_match(format(opt_detail), "OutDec: missing (expected .)", fixed = TRUE)
  expect_match(format(loc_detail), "LC_TIME: missing (expected en_US.UTF-8)", fixed = TRUE)
  expect_match(format(sysenv_detail), "R_TEST: expected x, got y", fixed = TRUE)
})

test_that("format.sessioncheck_status() falls back to the plain name list for hand-built options/locale/sysenv statuses", {
  # opt/syse/loc (defined above) lack the expected/actual/present attributes
  # that .get_options_status()/.get_locale_status()/.get_sysenv_status()
  # attach, so formatting degrades to the same plain list used for other
  # check types rather than erroring
  local_mocked_bindings(.unicode_enabled = function() FALSE, .ansi_enabled = function() FALSE)
  expect_equal(format(opt), "x Unexpected options: x")
  expect_equal(format(syse), "x Unexpected system environment variables: x")
  expect_equal(format(loc), "x Unexpected locale settings: x")
})

test_that("format.sessioncheck_status() uses a consistent 'Unexpected <thing>:' failure prefix for every check type", {
  local_mocked_bindings(.unicode_enabled = function() FALSE, .ansi_enabled = function() FALSE)
  expect_equal(format(gg),  "x Unexpected objects in global environment: x")
  expect_equal(format(nm),  "x Unexpected namespaces: x")
  expect_equal(format(pac), "x Unexpected packages: x")
  expect_equal(format(att), "x Unexpected environments attached: x")
  expect_equal(format(st),  "x Session runtime exceeded: x")
})

test_that("format.sessioncheck_status() uses a checker-specific pass message instead of the generic '[no issues detected]'", {
  local_mocked_bindings(.unicode_enabled = function() FALSE, .ansi_enabled = function() FALSE)
  clean <- function(type) new_status(status = c(x = FALSE), type = type)

  expect_equal(format(clean("globalenv")),   "v No unexpected objects in global environment")
  expect_equal(format(clean("namespace")),   "v No unexpected namespaces loaded")
  expect_equal(format(clean("package")),     "v No unexpected packages attached")
  expect_equal(format(clean("attachment")),  "v No unexpected environments attached")
  expect_equal(format(clean("sessiontime")), "v Session runtime within limits")
  expect_equal(format(clean("options")),     "v No unexpected options detected")
  expect_equal(format(clean("sysenv")),      "v No unexpected system environment variables detected")
  expect_equal(format(clean("locale")),      "v No unexpected locale settings detected")
})

test_that("as.data.frame methods return data frames", {
  d1 <- as.data.frame(gg)
  d2 <- as.data.frame(ss)
  expect_s3_class(d1, "data.frame")
  expect_s3_class(d2, "data.frame")
  expect_named(d1, c("type", "entity", "status"))
  expect_named(d2, c("type", "entity", "status"))
  expect_equal(nrow(d1), length(gg$status))
})
