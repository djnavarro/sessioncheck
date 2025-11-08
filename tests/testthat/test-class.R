test_that("constructors work for valid input", {
  expect_no_error(new_status(status = c(x = TRUE), type = "globalenv"))
  expect_no_error(new_sessioncheck(new_status(status = c(x = TRUE), type = "globalenv")))
})

gg <- new_status(status = c(x = TRUE), type = "globalenv")  
ss <- new_sessioncheck(gg)

test_that("constructors return objects with expected structure", {
  expect_s3_class(gg, "sessioncheck_status")
  expect_s3_class(ss, "sessioncheck_sessioncheck")
  expect_named(gg, c("status", "type"))
})

test_that("print methods return formatted objects", {
  expect_equal(capture.output(print(gg)), format(gg))
})

test_that("print methods invisibly return original objects", {
  expect_equal(print(gg), gg)
  expect_equal(print(ss), ss)
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
