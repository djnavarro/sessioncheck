# Reporting the session state

Suppose you run an analysis script today and it produces a number you
trust. Three months from now, you (or a colleague) run the same script
again and get a slightly different number. Nothing about the code has
changed, that much you know for sure. But, what *did* change? That’s a
little harder to answer. Maybe a package was updated in the meantime.
Maybe the script relies on randomness and the seed wasn’t what you
thought it was. Maybe there was already something sitting in the R
session, left over from earlier work, that quietly affected the result.

Questions like these are hard to answer if you don’t have an audit
trail, because by the time you notice a discrepancy, the session that
produced the original number is long gone. The fix is to capture a
record of that session *while it still exists*, ideally as part of the
script itself, so this audit is preserved alongside the output. That’s
the job of
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md).

``` r

library(sessioncheck)
```

## Introducing `sessionstate()`

The role of
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
is to take a snapshot of the current R session: what R version and
packages are in use, what’s in the global environment, what random
events have occurred, and more. Where
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is called at the *start* of a script to check that the session is clean,
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
is meant to be called at the *end* – or embedded in a rendered report –
purely to record what actually happened, without judging it. Here’s what
it produces:

``` r

sessionstate()
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version             R version 4.6.1 (2026-06-24)
#> • os                  Ubuntu 24.04.5 LTS
#> • system              x86_64, linux-gnu
#> • ui                  non-interactive
#> • tz                  UTC
#> • date                2026-09-13
#> 
#> ─ Locale ───────────────────────────────────────────────────────────────────────
#> • language            en-US
#> • collate             C.UTF-8
#> • ctype               C.UTF-8
#> 
#> ─ Matrix products ──────────────────────────────────────────────────────────────
#> • BLAS                /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
#> • LAPACK              /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so
#> 
#> ─ Document products ────────────────────────────────────────────────────────────
#> • pandoc              3.8.3
#> • quarto              (not found)
#> 
#> ─ Machine ──────────────────────────────────────────────────────────────────────
#> • hostname            runnervmlun5p
#> • user                runner
#> • working directory   /home/runner/work/sessioncheck/sessioncheck/vignettes/articles
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha          47716e14104ad4180aa8a486e842d5d1aff0dc24
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-13 10:18:44 UTC
#> • session uptime      0.795 sec
#> 
#> ─ RNG state ────────────────────────────────────────────────────────────────────
#> • kind                Mersenne-Twister
#> • normal kind         Inversion
#> • sample kind         Rejection
#> • seed hash           b71d56b44eb5ee9ceb53ef4cf66a2ed4
#> 
#> ─ Library paths [n = 3] ────────────────────────────────────────────────────────
#> • /home/runner/work/_temp/Library
#> • /opt/R/4.6.1/lib/R/site-library
#> • /opt/R/4.6.1/lib/R/library
#> 
#> ─ Packages [n = 34] (attached + loaded via namespace) ──────────────────────────
#>       package attached loaded_version         source
#>          base        *          4.6.1           base
#>         bslib                  0.12.0 RSPM (R 4.6.0)
#>        cachem                   1.1.0 RSPM (R 4.6.0)
#>           cli                   3.6.6 RSPM (R 4.6.0)
#>      compiler                   4.6.1           base
#>      datasets        *          4.6.1           base
#>          desc                   1.4.3 RSPM (R 4.6.0)
#>        digest                  0.6.39 RSPM (R 4.6.0)
#>      evaluate                   1.0.5 RSPM (R 4.6.0)
#>       fastmap                   1.2.0 RSPM (R 4.6.0)
#>            fs                   2.1.0 RSPM (R 4.6.0)
#>      graphics        *          4.6.1           base
#>     grDevices        *          4.6.1           base
#>     htmltools                   0.5.9 RSPM (R 4.6.0)
#>     jquerylib                   0.1.4 RSPM (R 4.6.0)
#>      jsonlite                   2.0.0 RSPM (R 4.6.0)
#>         knitr                    1.52 RSPM (R 4.6.0)
#>     lifecycle                   1.0.5 RSPM (R 4.6.0)
#>       methods        *          4.6.1           base
#>          otel                   0.2.0 RSPM (R 4.6.0)
#>       pkgdown                   2.2.1 RSPM (R 4.6.0)
#>            R6                   2.6.1 RSPM (R 4.6.0)
#>          ragg                   1.5.2 RSPM (R 4.6.0)
#>         rlang                   1.3.0 RSPM (R 4.6.0)
#>     rmarkdown                    2.32 RSPM (R 4.6.0)
#>          sass                  0.4.10 RSPM (R 4.6.0)
#>  sessioncheck        *          0.2.0      local (.)
#>         stats        *          4.6.1           base
#>   systemfonts                   1.3.2 RSPM (R 4.6.0)
#>   textshaping                   1.0.5 RSPM (R 4.6.0)
#>         tools                   4.6.1           base
#>         utils        *          4.6.1           base
#>          xfun                    0.60 RSPM (R 4.6.0)
#>          yaml                  2.3.12 RSPM (R 4.6.0)
#> 
#> ─ Global environment [n = 1] ───────────────────────────────────────────────────
#>          name   class   size
#>  .Random.seed integer 2.5 Kb
#> 
#> ─ Attached environments [n = 11] ───────────────────────────────────────────────
#>                  name    type
#>            .GlobalEnv   other
#>  package:sessioncheck package
#>         package:stats package
#>      package:graphics package
#>     package:grDevices package
#>         package:utils package
#>      package:datasets package
#>       package:methods package
#>             Autoloads   other
#>           tools:callr   other
#>          package:base package
```

If parts of this look familiar, that’s intentional:
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
is similar in spirit to
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) and
to the [**sessioninfo**](https://sessioninfo.r-lib.org/) package’s
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)
function. All three report the R version, platform, locale, and
attached/loaded packages. The difference lies in the details:
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
goes a little further than either of the other two functions, and
captures information that is not captured by the others. In the sections
below we’ll walk through these additional details, showing you both what
you *gain* by using the more detailed audit, but also highlighting some
of the *costs* of doing so.

## The gain: extra information captured by `sessionstate()`

As mentioned above,
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
captures the same information that other session information functions
do, but it also records a few extra things:

- **Which version of the code actually ran.** The `Git` section records
  the current commit SHA and whether the working tree was dirty
  (uncommitted changes) at capture time. If the script lives in a git
  repository, this is the most direct way to tie a result back to an
  exact version of the code – far more reliable than trusting that
  nobody edited anything since.

- **Whether a package changed underneath you.** The `Packages` section
  lists every attached or loaded package, alongside its installed
  (on-disk) and loaded version. When you set out to reproduce a result,
  this is usually the first thing worth checking;
  [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
  also flags subtler drift that a plain version listing would miss – a
  package whose on-disk and loaded versions or paths disagree
  (`version_mismatch`, `path_mismatch`), or a loaded namespace that has
  since been removed from disk entirely (`removed_from_disk`).

- **Whether randomness was involved.** The `RNG state` section records
  the kind of random number generator in use, plus an MD5 fingerprint of
  `.Random.seed` (`seed_hash`). Comparing that fingerprint across two
  runs tells you whether the random state differed, without needing to
  store or inspect the (long, unreadable) seed itself.

- **What was already there before the script ran.** The
  `Global environment` section lists every object in `.GlobalEnv` –
  name, class, size, and a value fingerprint – and
  `Attached environments` lists everything on the search path, including
  things a package listing alone would miss, like `tools:rstudio` or an
  environment added with
  [`attach()`](https://rdrr.io/r/base/attach.html). If a stray object
  from an earlier interactive session quietly fed into a calculation,
  this is where you’d spot it.

- **When it happened, and with what tools.** `Timing` records the
  capture time and how long the session had already been running;
  `Document products` records the pandoc and quarto versions in use,
  since these can affect how a rendered report looks even when the
  R-level session is otherwise identical.

None of this is captured by
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) or
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)
– which is exactly why, for the “what changed?” question above, a plain
session summary can sometimes fail to provide you the answers you need.

## The cost: more identifying information

This extra detail comes from looking at things the other two tools
mostly leave alone: the filesystem, the machine, and the objects sitting
in memory. That has a real privacy cost, and you should think about
these costs *before* you decide to allow
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
output to appear in a document that will be shared with other people.

| Information | [`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) | [`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html) | [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md) |
|----|----|----|----|
| Hostname | No | No | Yes (`machine$nodename`) |
| Local username | No | No | Yes (`machine$user`) |
| Working directory | No | No | Yes (`machine$cwd`) |
| Library paths (often embed a home directory) | No | Yes, in the `[1] /home/...` listing | Yes (`libpaths`, and `packages$ondisk_path`/`loaded_path`) |
| Object names from your script | No | No | Yes (`globalenv$name`) |

You can see this in the example above: `machine` records the hostname
and username reported by
[`Sys.info()`](https://rdrr.io/r/base/Sys.info.html), plus the working
directory at capture time, and `globalenv` lists the name of every
object in `.GlobalEnv` (never its value – but a name like `patient_ids`
or `q3_salary_data` can be revealing on its own).

This isn’t an oversight; it’s the same information that makes
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
useful as a reproducibility record in the first place. `machine$cwd`
matters because relative paths elsewhere in the script only resolve
correctly relative to it; `ondisk_path`/`loaded_path` matter because
they show precisely which library a package came from. Usefulness and
shareability are simply in tension here, so it’s worth deciding up front
how much of that tradeoff you’re comfortable with.

## Redacting fields when sharing

Although there are real advantages to tracking the additional
information recorded by
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md),
the privacy costs should not be disregarded. Sometimes those costs will
be too high, and you would be better advised to use a different
reporting tool. At other times, though, you may decide that the better
approach is to use
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
but redact a few pieces of information from the output. You can do this
via the [`print()`](https://rdrr.io/r/base/print.html) method for
session state objects, which accepts arguments that allow you to choose
what information gets printed and what information does not. For
example, the code below hides `machine` entirely and keeps only the
`class` column of `globalenv` (dropping the `name` column, which might
describe the contents of your script):

``` r

print(sessionstate(), machine = character(0), globalenv = "class")
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version             R version 4.6.1 (2026-06-24)
#> • os                  Ubuntu 24.04.5 LTS
#> • system              x86_64, linux-gnu
#> • ui                  non-interactive
#> • tz                  UTC
#> • date                2026-09-13
#> 
#> ─ Locale ───────────────────────────────────────────────────────────────────────
#> • language            en-US
#> • collate             C.UTF-8
#> • ctype               C.UTF-8
#> 
#> ─ Matrix products ──────────────────────────────────────────────────────────────
#> • BLAS                /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
#> • LAPACK              /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so
#> 
#> ─ Document products ────────────────────────────────────────────────────────────
#> • pandoc              3.8.3
#> • quarto              (not found)
#> 
#> ─ Machine ──────────────────────────────────────────────────────────────────────
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha          47716e14104ad4180aa8a486e842d5d1aff0dc24
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-13 10:18:44 UTC
#> • session uptime      0.916 sec
#> 
#> ─ RNG state ────────────────────────────────────────────────────────────────────
#> • kind                Mersenne-Twister
#> • normal kind         Inversion
#> • sample kind         Rejection
#> • seed hash           b71d56b44eb5ee9ceb53ef4cf66a2ed4
#> 
#> ─ Library paths [n = 3] ────────────────────────────────────────────────────────
#> • /home/runner/work/_temp/Library
#> • /opt/R/4.6.1/lib/R/site-library
#> • /opt/R/4.6.1/lib/R/library
#> 
#> ─ Packages [n = 34] (attached + loaded via namespace) ──────────────────────────
#>       package attached loaded_version         source
#>          base        *          4.6.1           base
#>         bslib                  0.12.0 RSPM (R 4.6.0)
#>        cachem                   1.1.0 RSPM (R 4.6.0)
#>           cli                   3.6.6 RSPM (R 4.6.0)
#>      compiler                   4.6.1           base
#>      datasets        *          4.6.1           base
#>          desc                   1.4.3 RSPM (R 4.6.0)
#>        digest                  0.6.39 RSPM (R 4.6.0)
#>      evaluate                   1.0.5 RSPM (R 4.6.0)
#>       fastmap                   1.2.0 RSPM (R 4.6.0)
#>            fs                   2.1.0 RSPM (R 4.6.0)
#>      graphics        *          4.6.1           base
#>     grDevices        *          4.6.1           base
#>     htmltools                   0.5.9 RSPM (R 4.6.0)
#>     jquerylib                   0.1.4 RSPM (R 4.6.0)
#>      jsonlite                   2.0.0 RSPM (R 4.6.0)
#>         knitr                    1.52 RSPM (R 4.6.0)
#>     lifecycle                   1.0.5 RSPM (R 4.6.0)
#>       methods        *          4.6.1           base
#>          otel                   0.2.0 RSPM (R 4.6.0)
#>       pkgdown                   2.2.1 RSPM (R 4.6.0)
#>            R6                   2.6.1 RSPM (R 4.6.0)
#>          ragg                   1.5.2 RSPM (R 4.6.0)
#>         rlang                   1.3.0 RSPM (R 4.6.0)
#>     rmarkdown                    2.32 RSPM (R 4.6.0)
#>          sass                  0.4.10 RSPM (R 4.6.0)
#>  sessioncheck        *          0.2.0      local (.)
#>         stats        *          4.6.1           base
#>   systemfonts                   1.3.2 RSPM (R 4.6.0)
#>   textshaping                   1.0.5 RSPM (R 4.6.0)
#>         tools                   4.6.1           base
#>         utils        *          4.6.1           base
#>          xfun                    0.60 RSPM (R 4.6.0)
#>          yaml                  2.3.12 RSPM (R 4.6.0)
#> 
#> ─ Global environment [n = 1] ───────────────────────────────────────────────────
#>    class
#>  integer
#> 
#> ─ Attached environments [n = 11] ───────────────────────────────────────────────
#>                  name    type
#>            .GlobalEnv   other
#>  package:sessioncheck package
#>         package:stats package
#>      package:graphics package
#>     package:grDevices package
#>         package:utils package
#>      package:datasets package
#>       package:methods package
#>             Autoloads   other
#>           tools:callr   other
#>          package:base package
```

It’s important to remember that this only changes what information is
displayed: the underlying object is untouched. See
[`?display_methods`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
for the full list of selectable fields, and the [customizing
sessionstate()
output](https://sessioncheck.djnavarro.net/articles/sessionstate-display.md)
article for a more detailed discussion of this topic.

## Choosing between the three

None of
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html),
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html),
and
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
is a strictly better choice – they trade detail against exposure:

- **[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html)**
  – no dependency, minimal exposure. A good default for a quick report
  or a bug filed by someone you don’t know well.
- **[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)**
  – a more readable package table (remotes, install source, mismatch
  flags), at the cost of a library-path listing that usually reveals a
  home directory.
- **[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)**
  – the most complete record, including git/RNG/timing information the
  other two don’t capture at all, but with the most exposure: hostname,
  username, working directory, and global environment object names.

If you decide
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)’s
extra detail is worth it, it’s worth deciding *before* you start using
it in scripts or reports whether its output will ever leave your machine
(committed logs, shared reports, public CI artifacts) – and if so,
redacting the fields you’re not comfortable including.

## Further reading

- The [session state
  comparisons](https://sessioncheck.djnavarro.net/articles/sessionstate-comparison.md)
  article covers
  [`compare_sessionstates()`](https://sessioncheck.djnavarro.net/reference/compare_sessionstates.md),
  which takes two snapshots and reports exactly how they differ.
- The [session state
  display](https://sessioncheck.djnavarro.net/articles/sessionstate-display.md)
  article provides a more detailed discussion of how you can customize
  the information that gets displayed when a session state is printed.
