# Report the current state of the R session

`sessionstate()` captures a point-in-time, human-readable snapshot of
the R session: platform details, selected machine information, session
timing, an inventory of attached and loaded-namespace packages
(including remote source tracking for packages installed from GitHub),
the contents of the global environment, and the non-package entries on
the search path. It is intended as a companion to
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md):
where
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is typically called at the *start* of a script to check for a clean
session, `sessionstate()` is intended to be called at the *end* of a
script to produce an audit log of the environment the script actually
ran in.

## Usage

``` r
sessionstate()
```

## Value

An object of class `sessioncheck_sessionstate`, a list with elements
`platform`, `locale`, `matrix`, `document`, `machine`, `git`, `timing`,
`rng`, `libpaths`, `packages`, `globalenv`, and `attachments`.

## Details

The `machine` element includes the node name and user reported by
[`Sys.info()`](https://rdrr.io/r/base/Sys.info.html), along with the
working directory reported by
[`getwd()`](https://rdrr.io/r/base/getwd.html) at capture time (`cwd`) –
useful for a reproducibility audit since relative paths used elsewhere
in a script only resolve correctly relative to this directory. Because
this can reveal a hostname, local username, or directory structure, be
mindful about where `sessionstate()` output is stored or shared. The
same caution applies to the `ondisk_path`/ `loaded_path` columns of
`packages`, since library paths often embed a home directory.

The `git` element records `sha`, the current commit
(`git rev-parse HEAD`, run in the working directory captured as
`machine$cwd`), and `dirty`, whether the working tree has uncommitted
changes (`git status --porcelain` is non-empty). Both are `NA` if the
working directory isn't inside a git repository, or if `git` itself
isn't installed. This is arguably the single most useful field for
reproducing a script's output later: `sha` identifies exactly which
version of the code ran, and `dirty` flags whether that identification
is trustworthy (a `TRUE` means the code that ran may not match any
commit).

The `rng` element records
[`RNGkind()`](https://rdrr.io/r/base/Random.html) (as `kind`,
`normal_kind`, and `sample_kind`) together with `seed_hash`, an MD5
fingerprint of `.Random.seed` (via
[`tools::md5sum()`](https://rdrr.io/r/tools/md5sum.html), since base R
has no in-memory hashing function). `seed_hash` is `NA` if the RNG
hasn't been used yet this session (nothing has consumed a random draw,
so `.Random.seed` doesn't exist); `sessionstate()` never forces this
into existence, since doing so would itself consume a draw as a side
effect of an audit call. The hash exists to make RNG state comparable
across renders without printing the seed itself: for example, comparing
`seed_hash` between two rendered versions of the same Quarto/R Markdown
document shows whether an edit changed the RNG state anywhere upstream,
without having to inspect or store the (long, not directly meaningful)
seed value.

The `libpaths` element is the character vector returned by
[`.libPaths()`](https://rdrr.io/r/base/libPaths.html), i.e. the library
locations R searches, in search order. It complements `packages`: that
element records where each individual package resolved *to*
(`ondisk_path`), while `libpaths` records where R was looking in the
first place, which matters when, e.g., a project-local library shadows a
personal one. Unlike the other elements, there is no corresponding
display-filtering argument for `libpaths`, since it is already a flat
list of paths rather than a set of named fields or columns to choose
among; it is always shown in full.

The `packages` element covers every package that is either attached to
the search path or loaded via namespace (i.e.,
`union(.packages(), loadedNamespaces())`). It has columns `package`,
`attached`, `ondisk_version` (the version recorded in the installed
package's `DESCRIPTION` file), `loaded_version` (the version of the
namespace actually loaded into memory), `version_mismatch` (`TRUE` when
the two disagree, e.g. because the package was updated on disk after
this session loaded it), `ondisk_path` and `loaded_path` (the library
paths a package currently resolves to versus where its loaded namespace
actually came from), `path_mismatch` (`TRUE` when both exist but
disagree, e.g. after a
[`.libPaths()`](https://rdrr.io/r/base/libPaths.html) change
mid-session), `removed_from_disk` (`TRUE` when the namespace is loaded
but no longer found on disk at all), and `source`, which classifies each
package as `"base"`, `"CRAN (R x.y.z)"`, `"Github (user/repo@sha)"`,
another remote type, or `"local"` when no remote metadata is available.

The `globalenv` element is a data frame with one row per object in
`.GlobalEnv` (including dot-prefixed objects), with columns `name`,
`class`, and `size` (in bytes, as reported by
[`utils::object.size()`](https://rdrr.io/r/utils/object.size.html)).
Only object names, classes, and sizes are captured, never values.
Because a long-running script can accumulate many objects, the default
display shows only the largest few (see below); the captured object
itself always holds every object.

The `locale` element records `language`, `collate`, and `ctype`. These
are split out from `platform` because they describe how text and dates
are formatted for this session, rather than what/where/when the session
is running.

The `matrix` element records `blas` and `lapack`, the shared libraries
backing R's linear algebra routines (as reported by
[`extSoftVersion()`](https://rdrr.io/r/base/extSoftVersion.html) and
[`La_library()`](https://rdrr.io/r/base/La_library.html)). Like
`locale`, this is split out from `platform` – in this case mirroring how
base R's
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html)
treats "Matrix products" as its own block rather than nesting it under
platform info.

The `document` element's `pandoc` and `quarto` fields record the
versions of those two document-rendering tools, if found (`NA`
otherwise). Both checks prefer the IDE-provided location over whatever
happens to be on `PATH` (`RSTUDIO_PANDOC` for pandoc, `QUARTO_PATH` for
quarto), since RStudio/Positron bundle their own copies that may differ
from a separately installed one. Deliberately not tracked: other system
dependencies (e.g. LaTeX, Hugo, spatial libraries) are package-specific
rather than session-wide, and tracking them well would mean tracking
many of them; `pandoc`/`quarto` are included because they, like
BLAS/LAPACK, are already tracked by
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) or
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html).
`document` has no
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) precedent
(unlike `matrix`), but is grouped the same way for consistency.

The `attachments` element is a data frame with one row per entry on the
search path (as returned by
[`search()`](https://rdrr.io/r/base/search.html)), with columns `name`
and `type` (`"package"` or `"other"`). This surfaces non-package
attachments (e.g. `tools:rstudio`, or environments added via
[`attach()`](https://rdrr.io/r/base/attach.html)) that aren't reflected
in `packages`.

`sessionstate()` itself always captures every field in full (`globalenv`
is never truncated at capture time). To display only a subset when
printing, pass `platform`/`locale`/`matrix`/`document`/`machine`/`git`/
`timing`/`rng`/`packages`/`globalenv`/`attachments` arguments to
[`print()`](https://rdrr.io/r/base/print.html) or
[`format()`](https://rdrr.io/r/base/format.html) on the result, or set
defaults via `options(sessioncheck = list(sessionstate_packages = ...))`
(see
[display_methods](https://sessioncheck.djnavarro.net/reference/display_methods.md)
for the full precedence rules and option names). The `globalenv_n`
argument separately controls how many rows of `globalenv` are shown
(largest objects first), independent of which columns are selected. None
of this affects the underlying object, so `x$globalenv`/`x$attachments`
always return their full data frames. Separately,
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
one of the three tables captured by `sessionstate()` (`packages`,
`globalenv`, or `attachments`, selected via its `which` argument); see
[coercion_methods](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
for why this coercion, unlike the one for
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md),
cannot be lossless.

## See also

[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)

## Examples

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
#> • collate             C
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
#> • working directory   /home/runner/work/sessioncheck/sessioncheck/docs/reference
#> 
#> ─ Git ──────────────────────────────────────────────────────────────────────────
#> • commit sha          5d9dea2b08945691beeeef0728ce8fa494b6e1f4
#> • dirty               FALSE
#> 
#> ─ Timing ───────────────────────────────────────────────────────────────────────
#> • captured at         2026-09-06 10:55:19 UTC
#> • session uptime      8.475 sec
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
#> ─ Packages [n = 56] (attached + loaded via namespace) ──────────────────────────
#>         package attached loaded_version
#>              R6                   2.6.1
#>         askpass                   1.2.1
#>            base        *          4.6.1
#>            brio                   1.1.5
#>           bslib                  0.12.0
#>          cachem                   1.1.0
#>             cli                   3.6.6
#>        compiler                   4.6.1
#>            curl                   8.0.0
#>        datasets        *          4.6.1
#>            desc                   1.4.3
#>          digest                  0.6.39
#>         downlit                   0.4.5
#>        evaluate                   1.0.5
#>           fansi                   1.0.7
#>         fastmap                   1.2.0
#>     fontawesome                   0.5.3
#>              fs                   2.1.0
#>            glue                   1.8.1
#>       grDevices        *          4.6.1
#>        graphics        *          4.6.1
#>       htmltools                   0.5.9
#>           httr2                   1.3.0
#>       jquerylib                   0.1.4
#>        jsonlite                   2.0.0
#>           knitr                    1.51
#>       lifecycle                   1.0.5
#>        magrittr                   2.0.5
#>         memoise                   2.0.1
#>         methods        *          4.6.1
#>         openssl                   2.4.2
#>            otel                   0.2.0
#>             pak                  0.11.1
#>          pillar                  1.11.1
#>       pkgconfig                   2.0.3
#>         pkgdown                   2.2.1
#>           purrr                   1.2.2
#>            ragg                   1.5.2
#>           rlang                   1.3.0
#>       rmarkdown                    2.32
#>            sass                  0.4.10
#>    sessioncheck        *     0.1.1.9000
#>           stats        *          4.6.1
#>     systemfonts                   1.3.2
#>        testthat                   3.3.2
#>     textshaping                   1.0.5
#>          tibble                   3.3.1
#>           tools                   4.6.1
#>           utils        *          4.6.1
#>           vctrs                   0.7.3
#>  waeponwifestre              0.0.0.9000
#>         whisker                   0.4.1
#>           withr                   3.0.3
#>            xfun                    0.60
#>            xml2                   1.6.0
#>            yaml                  2.3.12
#>                                     source
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                       base
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                       base
#>                             RSPM (R 4.6.0)
#>                                       base
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                       base
#>                                       base
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                       base
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                      local
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                  local (.)
#>                                       base
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                                       base
#>                                       base
#>                             RSPM (R 4.6.0)
#>  Github (djnavarro/waeponwifestre@6265365)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#>                             RSPM (R 4.6.0)
#> 
#> ─ Global environment [n = 1] ───────────────────────────────────────────────────
#>          name   class   size
#>  .Random.seed integer 2.5 Kb
#> 
#> ─ Attached environments [n = 10] ───────────────────────────────────────────────
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
#>          package:base package 
```
