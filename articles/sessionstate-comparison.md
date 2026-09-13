# Comparing session states

``` r

library(sessioncheck)
```

The [session state
reporting](https://sessioncheck.djnavarro.net/articles/sessionstate-reporting.md)
article introduces
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md),
which takes a snapshot of the current R session – packages, global
environment contents, RNG state, and more. A single snapshot is useful
as a standalone record, but on its own it can’t answer a very natural
follow-up question: *what changed?*

## A concrete “what changed” question

Suppose you’re debugging a script that behaves inconsistently: some runs
produce the expected result, others don’t, and you suspect the script
itself is fine but something about the session it runs in differs from
one run to the next. Or perhaps you’re just cautious about a chunk of
code you’re about to run, and want to know afterwards exactly what it
did to the session – did it leave new objects behind? Change a package
version? Consume random numbers you didn’t expect it to?

Both questions have the same shape: take a snapshot before, take another
after, and compare the two.
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
does the comparing.

## A basic comparison

``` r

# wrapped in a function so `baseline`/`current` themselves never end up in
# .GlobalEnv -- otherwise each would show up as "added" in the diff below,
# simply for having been assigned in between the two snapshots
take_diff <- function() {
  baseline <- sessionstate()
  assign("some_result", 1:10, envir = .GlobalEnv)
  current <- sessionstate()
  compare_sessionstates(baseline, current)
}
diff <- take_diff()
diff
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
#> • captured at (old)     2026-09-13 02:44:40 UTC
#> • captured at (new)     2026-09-13 02:44:41 UTC
#> • wall clock elapsed    0.04 secs
#> • session uptime delta  0.04 secs
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
#>         name   class size
#>  some_result integer   96
#> 
#> ─ Attached environments ────────────────────────────────────────────────────────
#> • (no changes)
```

That comment is worth pausing on, because it’s a real gotcha rather than
defensive over-caution:
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
compares whatever is in `.GlobalEnv` at each snapshot, so any variable
you assign there between the two calls – including `baseline` itself, if
you didn’t wrap things in a function – will show up as “added”. Wrapping
the two snapshots in a function keeps `baseline` and `current` local to
that function, so the only real change visible in the diff is the one
this example is trying to demonstrate: `some_result` being created.

## Reading the output

Most sections above collapse to a single “(no changes)” line – that’s
[`print()`](https://rdrr.io/r/base/print.html)’s default behavior
(`changed_only = TRUE`), which hides any section where nothing differed
between the two snapshots. `globalenv` is the exception here because
`some_result` really was added; `timing` is always shown in full, since
`captured_at`/`elapsed_sec` necessarily differ between any two
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
calls, so there’s no “unchanged” case for a diff to collapse. To see
every field for the record-shaped sections (`platform`, `locale`,
`matrix`, `document`, `machine`, `git`, `rng`) regardless of whether it
changed, pass `changed_only = FALSE`.

## Digging into a specific section

Like
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)’s
tabular sections, `packages`/`globalenv`/`attachments` can be coerced
with [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) for
programmatic use. The shape is a little different from
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)’s
own tables, though: one row per key *and* tracked field, tagged
`"added"`, `"removed"`, or `"modified"`, rather than one row per key
overall.

``` r

as.data.frame(diff, which = "globalenv")
#>          name change field  old                              new verified
#> 1 some_result  added class <NA>                          integer       NA
#> 2 some_result  added  size <NA>                               96       NA
#> 3 some_result  added  hash <NA> 85ee0eceeffb89a47e4f4af1e6e38395       NA
```

## How much can you trust a “modified” value?

`globalenv`’s rows carry a `verified` column, and it’s worth knowing
what it does and doesn’t promise.
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
fingerprints each global environment object’s serialized value, so
[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
can usually detect that a value changed even when its class and size
stayed the same – for instance, an object mutated in place. When both
snapshots have a usable fingerprint for an object, a mismatch is
authoritative, and the row is marked `verified = TRUE`.

Some objects can’t be fingerprinted at all – one holding a live database
connection, for example. When that happens, the comparison falls back to
`class`/`size` only, and the row is marked `verified = FALSE`: if
neither of those changed either, a real value change could still have
happened without being detected. `verified = FALSE` is a signal to
double-check manually, not a sign that anything is broken.

The reverse gotcha also exists: for R6 objects, closures, and other
environment-backed values, `verified = TRUE` can still report a spurious
“modified” row, since fingerprinting is sensitive to binding order, not
just content – see
[`?compare_sessionstates`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
for the specifics of both failure modes.

## One thing worth watching for

[`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
warns if `new` looks like it was captured *before* `old`, since that
usually means the two snapshots were passed in the wrong order:

``` r

show_backwards_order <- function() {
  early <- sessionstate()
  Sys.sleep(0.05)
  late <- sessionstate()
  invisible(compare_sessionstates(late, early))
}
show_backwards_order()
#> Warning: `new` was captured before `old`; check whether the arguments are in
#> the intended order
```

The comparison is still computed either way – this is a nudge to
double-check your arguments, not an error. See
[`?compare_sessionstates`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md)
for the complete per-section diff semantics, including how each of
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)’s
twelve elements is compared.
