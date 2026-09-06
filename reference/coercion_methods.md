# Coerce session check object to a data frame

S3 [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
methods for the three classes this package defines, letting each be
dropped into ordinary data frame workflows (filtering, joining, export)
instead of only being inspected via
[`print()`](https://rdrr.io/r/base/print.html)/[`format()`](https://rdrr.io/r/base/format.html).

## Usage

``` r
# S3 method for class 'sessioncheck_status'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'sessioncheck_sessioncheck'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'sessioncheck_sessionstate'
as.data.frame(x, row.names = NULL, optional = FALSE, which = "packages", ...)

# S3 method for class 'sessioncheck_sessionstatediff'
as.data.frame(x, row.names = NULL, optional = FALSE, which = "packages", ...)
```

## Arguments

- x:

  An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
  `sessioncheck_sessionstate`, or `sessioncheck_sessionstatediff`

- row.names:

  Ignored

- optional:

  Ignored

- ...:

  Ignored

- which:

  For `sessioncheck_sessionstate` objects, which tabular component to
  return: one of `"packages"` (the default), `"globalenv"`, or
  `"attachments"`. For `sessioncheck_sessionstatediff` objects, the same
  three section names instead select a long-format diff table (see
  Details); the default is likewise `"packages"`. Ignored for other
  classes.

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

`sessioncheck_sessionstatediff` objects (from
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md))
coerce differently again: each `which` selects a single long-format
table with one row per key (`package`/`name`/`name`, for
`"packages"`/`"globalenv"`/`"attachments"` respectively) and tracked
field, with columns `<key>`, `change` (`"added"`, `"removed"`, or
`"modified"`), `field`, `old`, and `new`. A key present in only one
snapshot contributes one row per tracked field, all with the same
`change`, and `old`/`new` `NA` on whichever side it didn't exist; a key
present in both snapshots contributes a row only for fields that
actually changed. The tracked fields are
`attached`/`ondisk_version`/`loaded_version`/`source` for `"packages"`,
`class`/`size`/`hash` for `"globalenv"`, and `type` for `"attachments"`
– the same fields
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
tracks for its own `modified` tables. `"globalenv"` additionally has a
`verified` column (`NA` for `"added"`/`"removed"` rows, since there is
nothing to verify when a key only exists in one snapshot; `TRUE`/`FALSE`
for `"modified"` rows – see
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
for what `verified` means). `"attachments"` never has `"modified"` rows,
since a `type` change for an existing search-path entry isn't a
realistic scenario.
