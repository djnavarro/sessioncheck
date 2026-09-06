# Reporting the session state

``` r

library(sessioncheck)
```

In addition to tools for checking the state of an R session,
**sessioncheck** also provides a
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
function that can be used to report on the overall state of an R
session. This function is similar in spirit to the
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html)
function available in base R, and also to the
[**sessioninfo**](https://sessioninfo.r-lib.org/) package that offers a
more detailed replacement,
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html).
This article explains what
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
does, and the ways in which it is similar to but also different from the
existing tools. In particular, it discusses what
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
adds over and above what the other two functions report, and – because
it does add quite a lot of new information – what you give up in return,
namely some privacy.

## Two different jobs

[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
and
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
are companions, but they solve different problems:

- [`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
  is typically called at the *start* of a script. It looks for signs
  that the session isn’t “clean” and, depending on `action`, warns or
  errors before the rest of the script runs.
- [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
  is typically called at the *end* of a script (or embedded in a
  rendered report). It doesn’t judge anything; it just records what the
  session actually looked like, so that if something goes wrong later,
  there’s a record to consult.

[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) and
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)
serve the same “record what happened” purpose as
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md).
All three are audit tools, not gatekeeping tools, and none of them will
stop a script from running.

## A side-by-side look

Here’s what each of the three produces in the same session:

``` r

utils::sessionInfo()
#> R version 4.6.1 (2026-06-24)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] sessioncheck_0.1.1.9000
#> 
#> loaded via a namespace (and not attached):
#>  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
#>  [5] xfun_0.60         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
#>  [9] rmarkdown_2.32    lifecycle_1.0.5   cli_3.6.6         sass_0.4.10      
#> [13] pkgdown_2.2.1     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
#> [17] compiler_4.6.1    tools_4.6.1       ragg_1.5.2        bslib_0.12.0     
#> [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
#> [25] rlang_1.3.0       fs_2.1.0
```

``` r

sessioninfo::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value
#>  version  R version 4.6.1 (2026-06-24)
#>  os       Ubuntu 24.04.4 LTS
#>  system   x86_64, linux-gnu
#>  ui       X11
#>  language en-US
#>  collate  C.UTF-8
#>  ctype    C.UTF-8
#>  tz       UTC
#>  date     2026-09-06
#>  pandoc   3.8.3 @ /opt/hostedtoolcache/pandoc/3.8.3/x64/ (via rmarkdown)
#>  quarto   NA
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package      * version    date (UTC) lib source
#>  bslib          0.12.0     2026-08-04 [1] RSPM
#>  cachem         1.1.0      2024-05-16 [1] RSPM
#>  cli            3.6.6      2026-04-09 [1] RSPM
#>  desc           1.4.3      2023-12-10 [1] RSPM
#>  digest         0.6.39     2025-11-19 [1] RSPM
#>  evaluate       1.0.5      2025-08-27 [1] RSPM
#>  fastmap        1.2.0      2024-05-15 [1] RSPM
#>  fs             2.1.0      2026-04-18 [1] RSPM
#>  htmltools      0.5.9      2025-12-04 [1] RSPM
#>  jquerylib      0.1.4      2021-04-26 [1] RSPM
#>  jsonlite       2.0.0      2025-03-27 [1] RSPM
#>  knitr          1.51       2025-12-20 [1] RSPM
#>  lifecycle      1.0.5      2026-01-08 [1] RSPM
#>  otel           0.2.0      2025-08-29 [1] RSPM
#>  pkgdown        2.2.1      2026-07-07 [1] any (@2.2.1)
#>  R6             2.6.1      2025-02-15 [1] RSPM
#>  ragg           1.5.2      2026-03-23 [1] RSPM
#>  rlang          1.3.0      2026-07-05 [1] RSPM
#>  rmarkdown      2.32       2026-09-01 [1] RSPM
#>  sass           0.4.10     2025-04-11 [1] RSPM
#>  sessioncheck * 0.1.1.9000 2026-09-06 [1] local
#>  sessioninfo    1.2.4      2026-06-04 [1] RSPM
#>  systemfonts    1.3.2      2026-03-05 [1] RSPM
#>  textshaping    1.0.5      2026-03-06 [1] RSPM
#>  xfun           0.60       2026-07-09 [1] RSPM
#>  yaml           2.3.12     2025-12-10 [1] RSPM
#> 
#>  [1] /home/runner/work/_temp/Library
#>  [2] /opt/R/4.6.1/lib/R/site-library
#>  [3] /opt/R/4.6.1/lib/R/library
#>  * ── Packages attached to the search path.
#> 
#> ──────────────────────────────────────────────────────────────────────────────
```

``` r

sessionstate()
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version             R version 4.6.1 (2026-06-24)
#> • os                  Ubuntu 24.04.4 LTS
#> • system              x86_64, linux-gnu
#> • ui                  non-interactive
#> • tz                  UTC
#> • date                2026-09-06
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
#> • hostname            runnervmejwal
#> • user                runner
#> • working directory   /home/runner/work/sessioncheck/sessioncheck/vignettes/articles
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha          7a5196dce247d262d9edec3bcfb5eab05a01d373
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-06 12:09:18 UTC
#> • session uptime      0.917 sec
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
#> ─ Packages [n = 35] (attached + loaded via namespace) ──────────────────────────
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
#>         knitr                    1.51 RSPM (R 4.6.0)
#>     lifecycle                   1.0.5 RSPM (R 4.6.0)
#>       methods        *          4.6.1           base
#>          otel                   0.2.0 RSPM (R 4.6.0)
#>       pkgdown                   2.2.1 RSPM (R 4.6.0)
#>            R6                   2.6.1 RSPM (R 4.6.0)
#>          ragg                   1.5.2 RSPM (R 4.6.0)
#>         rlang                   1.3.0 RSPM (R 4.6.0)
#>     rmarkdown                    2.32 RSPM (R 4.6.0)
#>          sass                  0.4.10 RSPM (R 4.6.0)
#>  sessioncheck        *     0.1.1.9000      local (.)
#>   sessioninfo                   1.2.4 RSPM (R 4.6.0)
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

The three outputs overlap heavily – R version, platform, locale,
BLAS/LAPACK, attached and loaded packages – but
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
goes noticeably further. It records:

- **git provenance** (`git`): the current commit SHA and whether the
  working tree is dirty, so a script’s output can later be tied to an
  exact version of the code.
- **RNG state** (`rng`): the kind of generator in use, plus an MD5
  fingerprint of `.Random.seed` so two runs can be compared for a change
  in random state without printing the seed itself.
- **timing** (`timing`): when the snapshot was captured and how much
  wall-clock time the session had been running.
- **document tooling versions** (`document`): the pandoc and quarto
  versions in use, since these affect how a rendered report looks even
  when the R-level session is identical.
- **package drift** (`packages`): beyond version numbers, whether a
  package’s on-disk and loaded versions or paths disagree
  (`version_mismatch`, `path_mismatch`), or whether a loaded namespace
  has since vanished from disk (`removed_from_disk`).
- **non-package attachments** (`attachments`): everything on the search
  path, including things like `tools:rstudio` or environments added with
  [`attach()`](https://rdrr.io/r/base/attach.html), that package-only
  listings omit.
- **global environment contents** (`globalenv`): the name, class, and
  size of every object currently in `.GlobalEnv` (values are never
  captured, only metadata about them).

None of
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) or
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)
capture any of the above.

## The cost: more identifying information

[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
gets this extra detail by looking at things the other two tools mostly
leave alone: the filesystem, the machine, and the objects sitting in
memory. That has a real privacy cost, and it’s worth being deliberate
about it before pasting
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
output into a GitHub issue, a CI log, or a shared report.

The table below summarizes what identifying information each tool can
expose:

| Information | [`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) | [`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html) | [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md) |
|----|----|----|----|
| Hostname | No | No | Yes (`machine$nodename`) |
| Local username | No | No | Yes (`machine$user`) |
| Working directory | No | No | Yes (`machine$cwd`) |
| Library paths (often embed a home directory) | No | Yes, in the `[1] /home/...` listing | Yes (`libpaths`, and `packages$ondisk_path`/`loaded_path`) |
| Object names from your script | No | No | Yes (`globalenv$name`) |

[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)
already leaks a little here – its library-path listing routinely
includes a personal library under a home directory, as it does in the
example above.
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
goes considerably further: `machine` directly records the hostname and
username reported by
[`Sys.info()`](https://rdrr.io/r/base/Sys.info.html), plus
[`getwd()`](https://rdrr.io/r/base/getwd.html) at capture time, and
`globalenv` lists the name of every object in `.GlobalEnv` (never its
value, but object names alone can be revealing – e.g. `patient_ids`,
`q3_salary_data`).

This isn’t accidental – these fields are exactly what makes
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
useful as a reproducibility audit trail. `machine$cwd` matters because
relative paths elsewhere in the script only resolve correctly relative
to it; `ondisk_path`/`loaded_path` matter because they show precisely
which library a package came from. But usefulness and shareability are
in tension here, and the output above makes the tradeoff concrete: it
exposes this machine’s real hostname, username, and directory structure,
simply by being rendered.

## Choosing between the three

None of these functions is a strictly better choice than the others;
they trade off detail against exposure:

- **[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html)**
  – no external dependency, no privacy exposure beyond package/platform
  names. Good default for a quick report or a bug filed by someone you
  don’t know well.
- **[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)**
  – much more readable package table (remotes, install source, mismatch
  flags), at the cost of a library-path listing that usually reveals a
  home directory.
- **[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)**
  – the most complete audit trail, including git/RNG/timing information
  the other two don’t capture at all, but with the most exposure:
  hostname, username, working directory, and global environment object
  names.

If you do want to share
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
output but need to redact some of it, the
[`print()`](https://rdrr.io/r/base/print.html)/[`format()`](https://rdrr.io/r/base/format.html)
methods accept field-selection arguments so you don’t have to hand-edit
the output. For example, this hides `machine` entirely and drops the
`name` column from `globalenv` (keeping only object classes, not the
names that might describe their contents):

``` r

print(sessionstate(), machine = character(0), globalenv = "class")
#> ─ Platform ─────────────────────────────────────────────────────────────────────
#> • version             R version 4.6.1 (2026-06-24)
#> • os                  Ubuntu 24.04.4 LTS
#> • system              x86_64, linux-gnu
#> • ui                  non-interactive
#> • tz                  UTC
#> • date                2026-09-06
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
#> • commit sha          7a5196dce247d262d9edec3bcfb5eab05a01d373
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-06 12:09:18 UTC
#> • session uptime      1.018 sec
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
#> ─ Packages [n = 35] (attached + loaded via namespace) ──────────────────────────
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
#>         knitr                    1.51 RSPM (R 4.6.0)
#>     lifecycle                   1.0.5 RSPM (R 4.6.0)
#>       methods        *          4.6.1           base
#>          otel                   0.2.0 RSPM (R 4.6.0)
#>       pkgdown                   2.2.1 RSPM (R 4.6.0)
#>            R6                   2.6.1 RSPM (R 4.6.0)
#>          ragg                   1.5.2 RSPM (R 4.6.0)
#>         rlang                   1.3.0 RSPM (R 4.6.0)
#>     rmarkdown                    2.32 RSPM (R 4.6.0)
#>          sass                  0.4.10 RSPM (R 4.6.0)
#>  sessioncheck        *     0.1.1.9000      local (.)
#>   sessioninfo                   1.2.4 RSPM (R 4.6.0)
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

Selecting fields this way only changes what’s displayed – it never
touches the underlying object, so `x$machine` and `x$globalenv` are
still captured in full for your own use. See
[`?display_methods`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
for the complete list of selectable fields, and the [customizing
sessioncheck](https://sessioncheck.djnavarro.net/articles/customizing-sessioncheck.md)
article for how these defaults can also be set globally via
`options(sessioncheck = list(...))`.

## Suggested next step

Because `machine`, `libpaths`, and `packages$ondisk_path`/`loaded_path`
are the fields most likely to carry personal information, it’s worth
deciding *before* you start using
[`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
in scripts or reports whether its output will ever leave your machine
(e.g. committed logs, shared reports, public CI artifacts) and, if so,
which fields you’re comfortable including.
