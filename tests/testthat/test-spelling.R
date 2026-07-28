test_that("spelling", {
  skip_on_cran()
  skip_if_not_installed("spelling")
  expect_no_error(spelling::spell_check_package(pkg = find.package("sessioncheck")))
})
