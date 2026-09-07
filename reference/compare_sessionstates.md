# Compare two session state snapshots

`compare_sessionstates()` reports how two
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
snapshots differ. This is the comparison counterpart to
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)'s
point-in-time capture: take a snapshot with
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md),
do some work, take a second snapshot, and pass both to
`compare_sessionstates()` to see what changed.

## Usage

``` r
compare_sessionstates(old, new)
```

## Arguments

- old:

  A `sessioncheck_sessionstate` object (from
  [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)),
  treated as the baseline.

- new:

  A `sessioncheck_sessionstate` object (from
  [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)),
  treated as the later snapshot.

## Value

An object of class `sessioncheck_sessionstatediff`, a list with the same
12 elements as
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
(`platform`, `locale`, `matrix`, `document`, `machine`, `git`, `timing`,
`rng`, `libpaths`, `packages`, `globalenv`, `attachments`), each holding
a diff rather than a raw snapshot. See Details for the shape of each
element.

## Details

[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)'s
12 elements fall into four shapes, and each is diffed differently:

- **Record** elements (`platform`, `locale`, `matrix`, `document`,
  `machine`, `git`, `rng`) are named lists of scalar fields. Each is
  diffed field-by-field via
  [`identical()`](https://rdrr.io/r/base/identical.html), producing a
  data frame with columns `field`, `old`, `new`, and `changed`.

- **`timing`** is a record element, but `captured_at`/`elapsed_sec`
  necessarily differ between any two calls to
  [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md),
  so flagging them as "changed" the way other fields are would be noise
  every time. Instead `timing` reports `captured_at_old`,
  `captured_at_new`, `wall_elapsed` (the difference between the two
  capture times, in seconds), and `uptime_elapsed` (the difference
  between the two `elapsed_sec` values). The two are usually equal; a
  mismatch (e.g. the machine slept between snapshots) is itself worth
  noticing.

- **`libpaths`** is a plain character vector, diffed via
  [`setdiff()`](https://rdrr.io/r/base/sets.html) in both directions:
  `list(added = ..., removed = ...)`. Paths present in both snapshots
  but reordered are not reported as a change.

- **Keyed table** elements (`packages`, `globalenv`, `attachments`) are
  data frames. Each is diffed into
  `list(added = <data frame>, removed = <data frame>, modified = <data frame>)`
  (`attachments` has no `modified` table – a `type` change for the same
  search-path entry isn't a realistic scenario). `added`/`removed` are
  rows present in only one snapshot (keyed by `package`/`name`/`name`
  respectively); `modified` covers rows present in both where a tracked
  column differs, in a long format with one row per changed field
  (`package`/`name`, `field`, `old`, `new` for `packages`; see below for
  `globalenv`'s slightly different `modified` columns).

Keyed-table diffing assumes each key (`package` for `packages`; `name`
for `globalenv`/`attachments`) appears at most once per snapshot – true
for anything
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
itself produces. `old`/`new` are checked for this on every keyed-table
section, and `compare_sessionstates()` errors with an informative
message identifying the offending snapshot, section, and duplicated
value(s) if it doesn't hold (e.g. for a hand-constructed or corrupted
`sessioncheck_sessionstate` object).

Keyed-table diffing is purely key-based: it has no way to detect a
rename. A package or global environment object that is renamed but
otherwise unchanged between `old` and `new` (e.g. `pkgA` reinstalled
under a new name, or `x` renamed to `y` via
[`assign()`](https://rdrr.io/r/base/assign.html)) is reported as one
`removed` row (the old key) plus one `added` row (the new key), never as
a single "renamed" entry – there is no general way to tell a rename
apart from an unrelated removal-plus-addition that happens to involve
similar values. This is inherent to any key-based diff, not a bug to be
fixed.

`globalenv`'s `modified` table relies on the `hash` column
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
records for each object (an MD5 fingerprint of the object's serialized
value). When both snapshots have a non-`NA` hash for an object, a hash
mismatch is what marks it modified (`verified = TRUE`); when either
side's hash is `NA` (the object couldn't be serialized – see
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)'s
Global environment section), the comparison falls back to `class`/`size`
only, and the row is marked `verified = FALSE` to be explicit that a
value change could have gone undetected. If an object's hash goes from
`NA` to non-`NA` or vice versa between snapshots – e.g. it shrank below
`sessionstate_hash_max_size`, or started/stopped failing to serialize –
that is reported as its own `"hash"` row (with `verified = FALSE`), even
when `class`/`size` are unchanged, since the object's verifiability
itself changed.

`verified = TRUE` means the hash comparison itself is trustworthy as far
as R's serialization can see – it does not mean every possible kind of
change is detectable. For an object that is a thin wrapper around state
living outside R's memory (e.g. a database connection, an Arrow
`Table`/`RecordBatchReader`, a magick image; see
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)'s
Global environment section), `hash` fingerprints the R-level wrapper,
typically a fixed placeholder for the underlying pointer, not the
external data. A `verified = TRUE`, unchanged-hash result for such an
object means "unchanged as far as R can observe", not "definitely
unchanged" – the external state could have changed without the R-level
object being reassigned. This is inherent to hashing via R-level
serialization, not a defect in the comparison logic.

A related, opposite-direction limitation:
[`serialize()`](https://rdrr.io/r/base/serialize.html)'s traversal of an
environment's bindings is order-dependent, not purely content-dependent
(see
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)'s
Global environment section). For an object that is, or contains, an
environment – an R6 object, a closure, a reference class instance – this
can produce a hash mismatch, and so a false `modified` row here, even
when the object's actual contents are unchanged. `verified = TRUE` does
not rule this out.

A warning is issued if `new$timing$captured_at` is earlier than
`old$timing$captured_at`, since that usually means the two arguments
were passed in the wrong order; the comparison is still computed either
way.

## See also

[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)

## Examples

``` r
baseline <- sessionstate()
# assign() into .GlobalEnv explicitly (rather than `x <- 1:10`) so this
# example is correct wherever it's evaluated: sessionstate() specifically
# inspects .GlobalEnv, but some example/doc runners (e.g. pkgdown) do not
# evaluate example code there
assign("sessioncheck_example_obj", 1:10, envir = .GlobalEnv)
current <- sessionstate()
compare_sessionstates(baseline, current)
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Locale ───────────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Matrix products ──────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Document products ────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Machine ──────────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at (old)     2026-09-07 01:03:28 UTC
#> • captured at (new)     2026-09-07 01:03:28 UTC
#> • wall clock elapsed    0.07 secs
#> • session uptime delta  0.07 secs
#> 
#> ─ RNG state ────────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Library paths ────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Packages ─────────────────────────────────────────────────────────────────────
#> • (no changes)
#> 
#> ─ Global environment ───────────────────────────────────────────────────────────
#> Added [n = 1]
#>                      name   class size
#>  sessioncheck_example_obj integer   96
#> 
#> ─ Attached environments ────────────────────────────────────────────────────────
#> • (no changes) 
rm(sessioncheck_example_obj, envir = .GlobalEnv)
```
