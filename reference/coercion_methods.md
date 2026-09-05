# Coerce session check object to a data frame

Coerce session check object to a data frame

## Usage

``` r
# S3 method for class 'sessioncheck_status'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'sessioncheck_sessioncheck'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'sessioncheck_sessionstate'
as.data.frame(x, row.names = NULL, optional = FALSE, which = "packages", ...)
```

## Arguments

- x:

  An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
  or `sessioncheck_sessionstate`

- row.names:

  Ignored

- optional:

  Ignored

- ...:

  Ignored

- which:

  For `sessioncheck_sessionstate` objects, which tabular component to
  return: one of `"packages"` (the default), `"globalenv"`, or
  `"attachments"`. Ignored for other classes.

## Value

A data frame

## Details

For `sessioncheck_status` and `sessioncheck_sessioncheck` objects, this
coercion is lossless: every entity and status recorded in `x` appears as
a row in the result. That guarantee does not extend to
`sessioncheck_sessionstate` objects:
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
captures more than any single rectangular table can hold, mixing scalar
fields (`platform`, `locale`, `matrix`, `document`, `machine`, `git`,
`timing`, `rng`), a bare character vector (`libpaths`), and three
differently-shaped tables (`packages`, `globalenv`, `attachments`).
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
whichever one of those three tables `which` selects; none of the scalar
fields or `libpaths` are represented in the result. Use `x$platform`,
`x$machine`, `x$git`, `x$libpaths`, etc. (or `unclass(x)` for everything
at once) to access those directly.
