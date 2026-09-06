# Format and print sessioncheck objects

S3
[`format()`](https://rdrr.io/r/base/format.html)/[`print()`](https://rdrr.io/r/base/print.html)
methods for the three classes this package defines.
`sessioncheck_status`/`sessioncheck_sessioncheck` objects render as a
one-line-per-check status summary; `sessioncheck_sessionstate` objects
render as a multi-section report, and the arguments below let that
report be filtered down to specific fields or columns per section.

## Usage

``` r
# S3 method for class 'sessioncheck_status'
format(x, ...)

# S3 method for class 'sessioncheck_sessioncheck'
format(x, ...)

# S3 method for class 'sessioncheck_status'
print(x, ...)

# S3 method for class 'sessioncheck_sessioncheck'
print(x, ...)

# S3 method for class 'sessioncheck_sessionstate'
format(
  x,
  platform = NULL,
  locale = NULL,
  matrix = NULL,
  document = NULL,
  machine = NULL,
  git = NULL,
  timing = NULL,
  rng = NULL,
  packages = NULL,
  globalenv = NULL,
  globalenv_n = NULL,
  attachments = NULL,
  ...
)

# S3 method for class 'sessioncheck_sessionstate'
print(
  x,
  platform = NULL,
  locale = NULL,
  matrix = NULL,
  document = NULL,
  machine = NULL,
  git = NULL,
  timing = NULL,
  rng = NULL,
  packages = NULL,
  globalenv = NULL,
  globalenv_n = NULL,
  attachments = NULL,
  ...
)

# S3 method for class 'sessioncheck_sessionstatediff'
format(x, changed_only = TRUE, ...)

# S3 method for class 'sessioncheck_sessionstatediff'
print(x, changed_only = TRUE, ...)
```

## Arguments

- x:

  An object of class `sessioncheck_status`, `sessioncheck_sessioncheck`,
  `sessioncheck_sessionstate`, or `sessioncheck_sessionstatediff`

- ...:

  Ignored

- platform:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which platform fields to display (from `"version"`, `"os"`,
  `"system"`, `"ui"`, `"tz"`, `"date"`). Defaults to showing all fields.
  Ignored for other classes. See Details for how the default is
  resolved.

- locale:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which locale fields to display (from `"language"`,
  `"collate"`, `"ctype"`). Defaults to showing all fields. Ignored for
  other classes. See Details for how the default is resolved.

- matrix:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which matrix-products fields to display (from `"blas"`,
  `"lapack"`). Defaults to showing all fields. Ignored for other
  classes. See Details for how the default is resolved.

- document:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which document-products fields to display (from `"pandoc"`,
  `"quarto"`). Defaults to showing all fields. Ignored for other
  classes. See Details for how the default is resolved.

- machine:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which machine fields to display (from `"nodename"`,
  `"user"`, `"cwd"`). Defaults to showing all fields. Ignored for other
  classes. See Details for how the default is resolved.

- git:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which git fields to display (from `"sha"`, `"dirty"`).
  Defaults to showing all fields. Ignored for other classes. See Details
  for how the default is resolved.

- timing:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which timing fields to display (from `"captured_at"`,
  `"elapsed_sec"`). Defaults to showing all fields. Ignored for other
  classes. See Details for how the default is resolved.

- rng:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which RNG fields to display (from `"kind"`, `"normal_kind"`,
  `"sample_kind"`, `"seed_hash"`). Defaults to showing all fields.
  Ignored for other classes. See Details for how the default is
  resolved.

- packages:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which package inventory columns to display (see
  [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
  for the full list of columns). Defaults to
  `c("package", "attached", "loaded_version", "source")`. Ignored for
  other classes. See Details for how the default is resolved.

- globalenv:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which global environment columns to display (from `"name"`,
  `"class"`, `"size"`, `"hash"`). Defaults to
  `c("name", "class", "size")` (omitting `"hash"`, a long fingerprint
  mainly useful programmatically – see
  [`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)).
  Ignored for other classes. See Details for how the default is
  resolved, and for how `globalenv_n` separately controls the number of
  rows shown.

- globalenv_n:

  For `sessioncheck_sessionstate` objects, an optional single number
  giving the maximum number of `globalenv` rows to display, largest
  objects first. Defaults to `10`. Ignored for other classes. See
  Details for how the default is resolved.

- attachments:

  For `sessioncheck_sessionstate` objects, an optional character vector
  selecting which attached-environment columns to display (from
  `"name"`, `"type"`). Defaults to showing all columns. Ignored for
  other classes. See Details for how the default is resolved.

- changed_only:

  For `sessioncheck_sessionstatediff` objects, whether to collapse
  sections/fields with no detected change down to a single "(no
  changes)" line (`TRUE`, the default) or always show every field.
  Ignored for other classes.

## Value

Character vector

## Details

For `sessioncheck_sessionstate` objects, the
`platform`/`locale`/`matrix`/
`document`/`machine`/`git`/`timing`/`rng`/`packages`/`globalenv`/
`globalenv_n`/`attachments` arguments are resolved through the same
precedence used elsewhere in the package: an explicit argument always
wins; otherwise, `getOption("sessioncheck")` is checked for a
`sessionstate_platform`, `sessionstate_locale`, `sessionstate_matrix`,
`sessionstate_document`, `sessionstate_machine`, `sessionstate_git`,
`sessionstate_timing`, `sessionstate_rng`, `sessionstate_packages`,
`sessionstate_globalenv`, `sessionstate_globalenv_n`, or
`sessionstate_attachments` field (respectively); if neither is set, a
built-in default is used (showing every field/column, except for
`packages`, which defaults to
`c("package", "attached", "loaded_version", "source")`, `globalenv`,
which defaults to `c("name", "class", "size")`, and `globalenv_n`, which
defaults to `10`). This selection only affects what is displayed; it
never changes the underlying object, so
[`as.data.frame()`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
always returns the full package inventory, and
`x$globalenv`/`x$attachments` always return their full data frames,
regardless of any selection in effect.
