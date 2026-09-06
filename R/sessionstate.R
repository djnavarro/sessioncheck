
#' @title Report the current state of the R session
#'
#' @description
#' `sessionstate()` captures a point-in-time, human-readable snapshot of the R
#' session: platform details, selected machine information, session timing,
#' an inventory of attached and loaded-namespace packages (including remote
#' source tracking for packages installed from GitHub), the contents of the
#' global environment, and the non-package entries on the search path. It is
#' intended as a companion to [sessioncheck()]: where `sessioncheck()` is
#' typically called at the *start* of a script to check for a clean session,
#' `sessionstate()` is intended to be called at the *end* of a script to
#' produce an audit log of the environment the script actually ran in.
#'
#' @returns An object of class `sessioncheck_sessionstate`, a list with
#' elements `platform`, `locale`, `matrix`, `document`, `machine`, `git`,
#' `timing`, `rng`, `libpaths`, `packages`, `globalenv`, and `attachments`.
#'
#' @section Platform:
#' The `platform` element records `version` (the running R version, via
#' `R.version.string`), `os` (the operating system, preferring
#' [utils::osVersion()] when available and falling back to [Sys.info()]),
#' `system` (the R build's `R.version$system`), `ui` (the interface running
#' the session -- `"non-interactive"` when [interactive()] is `FALSE`,
#' otherwise the frontend reported by `.Platform$GUI`, e.g. `"RStudio"` or
#' `"Positron"`), `tz` (the session timezone via [Sys.timezone()]), and
#' `date` (the capture date).
#'
#' @section Locale:
#' The `locale` element records `language`, `collate`, and `ctype`. These
#' are split out from `platform` because they describe how text and dates
#' are formatted for this session, rather than what/where/when the session
#' is running.
#'
#' @section Matrix:
#' The `matrix` element records `blas` and `lapack`, the shared libraries
#' backing R's linear algebra routines (as reported by
#' [extSoftVersion()] and [La_library()]). Like `locale`, this is split out
#' from `platform` -- in this case mirroring how base R's
#' [utils::sessionInfo()] treats "Matrix products" as its own block rather
#' than nesting it under platform info.
#'
#' @section Document:
#' The `document` element's `pandoc` and `quarto` fields record the versions
#' of those two document-rendering tools, if found (`NA` otherwise). Both
#' checks prefer the IDE-provided location over whatever happens to be on
#' `PATH` (`RSTUDIO_PANDOC` for pandoc, `QUARTO_PATH` for quarto), since
#' RStudio/Positron bundle their own copies that may differ from a
#' separately installed one. Deliberately not tracked: other system
#' dependencies (e.g. LaTeX, Hugo, spatial libraries) are package-specific
#' rather than session-wide, and tracking them well would mean tracking
#' many of them; `pandoc`/`quarto` are included because they, like
#' BLAS/LAPACK, are already tracked by [utils::sessionInfo()] or
#' [sessioninfo::session_info()]. `document` has no `sessionInfo()`
#' precedent (unlike `matrix`), but is grouped the same way for
#' consistency.
#'
#' @section Machine:
#' The `machine` element includes the node name and user reported by
#' [Sys.info()], along with the working directory reported by [getwd()] at
#' capture time (`cwd`) -- useful for a reproducibility audit since relative
#' paths used elsewhere in a script only resolve correctly relative to this
#' directory. Because this can reveal a hostname, local username, or
#' directory structure, be mindful about where `sessionstate()` output is
#' stored or shared. The same caution applies to the `ondisk_path`/
#' `loaded_path` columns of `packages`, since library paths often embed a
#' home directory.
#'
#' @section Git:
#' The `git` element records `sha`, the current commit
#' (`git rev-parse HEAD`, run in the working directory captured as
#' `machine$cwd`), and `dirty`, whether the working tree has uncommitted
#' changes (`git status --porcelain` is non-empty). Both are `NA` if the
#' working directory isn't inside a git repository, or if `git` itself
#' isn't installed. This is arguably the single most useful field for
#' reproducing a script's output later: `sha` identifies exactly which
#' version of the code ran, and `dirty` flags whether that identification is
#' trustworthy (a `TRUE` means the code that ran may not match any commit).
#'
#' @section Timing:
#' The `timing` element records `captured_at`, the capture time reported by
#' [Sys.time()], and `elapsed_sec`, the session's elapsed run time in
#' seconds (the `"elapsed"` component of `proc.time()`). Together they let
#' an audit log show both when a snapshot was taken and how long the
#' session had already been running at that point.
#'
#' @section RNG:
#' The `rng` element records [RNGkind()] (as `kind`, `normal_kind`, and
#' `sample_kind`) together with `seed_hash`, an MD5 fingerprint of
#' `.Random.seed` (via [tools::md5sum()], since base R has no in-memory
#' hashing function). `seed_hash` is `NA` if the RNG hasn't been used yet
#' this session (nothing has consumed a random draw, so `.Random.seed`
#' doesn't exist); `sessionstate()` never forces this into existence, since
#' doing so would itself consume a draw as a side effect of an audit call.
#' The hash exists to make RNG state comparable across renders without
#' printing the seed itself: for example, comparing `seed_hash` between two
#' rendered versions of the same Quarto/R Markdown document shows whether
#' an edit changed the RNG state anywhere upstream, without having to
#' inspect or store the (long, not directly meaningful) seed value.
#'
#' @section Library paths:
#' The `libpaths` element is the character vector returned by [.libPaths()],
#' i.e. the library locations R searches, in search order. It complements
#' `packages`: that element records where each individual package resolved
#' *to* (`ondisk_path`), while `libpaths` records where R was looking in the
#' first place, which matters when, e.g., a project-local library shadows a
#' personal one. Unlike the other elements, there is no corresponding
#' display-filtering argument for `libpaths`, since it is already a flat
#' list of paths rather than a set of named fields or columns to choose
#' among; it is always shown in full.
#'
#' @section Packages:
#' The `packages` element covers every package that is either attached to
#' the search path or loaded via namespace (i.e., `union(.packages(),
#' loadedNamespaces())`). It has columns `package`, `attached`,
#' `ondisk_version` (the version recorded in the installed package's
#' `DESCRIPTION` file), `loaded_version` (the version of the namespace
#' actually loaded into memory), `version_mismatch` (`TRUE` when the two
#' disagree, e.g. because the package was updated on disk after this
#' session loaded it), `ondisk_path` and `loaded_path` (the library paths a
#' package currently resolves to versus where its loaded namespace actually
#' came from), `path_mismatch` (`TRUE` when both exist but disagree, e.g.
#' after a `.libPaths()` change mid-session), `removed_from_disk` (`TRUE`
#' when the namespace is loaded but no longer found on disk at all), and
#' `source`, which classifies each package as `"base"`, `"CRAN (R x.y.z)"`,
#' `"Github (user/repo@sha)"`, another remote type, or `"local"` when no
#' remote metadata is available.
#'
#' @section Global environment:
#' The `globalenv` element is a data frame with one row per object in
#' `.GlobalEnv` (including dot-prefixed objects), with columns `name`,
#' `class`, `size` (in bytes, as reported by [utils::object.size()]), and
#' `hash` (an MD5 fingerprint of the object's serialized value, in the same
#' spirit as `rng$seed_hash`: [serialize()] the object, then run
#' [tools::md5sum()] on the result). `hash` is `NA` when an object cannot be
#' serialized at all, which is rare in practice -- objects backed by an
#' external pointer (e.g. a database connection) typically still serialize
#' to a placeholder rather than erroring. This is reported rather than
#' silently treated as "unchanged" by anything comparing two snapshots. Only
#' object names, classes, sizes, and value fingerprints are captured, never
#' values themselves. Because a long-running script can accumulate many objects,
#' the default display shows only the largest few, and omits `hash` (see
#' "Selecting which elements are displayed" below); the captured object
#' itself always holds every object and every column.
#'
#' @section Attachments:
#' The `attachments` element is a data frame with one row per entry on the
#' search path (as returned by [search()]), with columns `name` and `type`
#' (`"package"` or `"other"`). This surfaces non-package attachments (e.g.
#' `tools:rstudio`, or environments added via [attach()]) that aren't
#' reflected in `packages`.
#'
#' @section Selecting which elements are displayed:
#' `sessionstate()` itself always captures every field in full (`globalenv`
#' is never truncated at capture time). To display only a subset when
#' printing, pass `platform`/`locale`/`matrix`/`document`/`machine`/`git`/
#' `timing`/`rng`/`packages`/`globalenv`/`attachments` arguments to
#' `print()` or `format()` on the result, or set
#' defaults via `options(sessioncheck = list(sessionstate_packages = ...))`
#' (see [display_methods] for the full precedence rules and option names).
#' The `globalenv_n` argument separately controls how many rows of
#' `globalenv` are shown (largest objects first), independent of which
#' columns are selected. None of this affects the underlying object, so
#' `x$globalenv`/`x$attachments` always return their full data frames.
#' Separately, `as.data.frame()` returns one of the three tables captured by
#' `sessionstate()` (`packages`, `globalenv`, or `attachments`, selected via
#' its `which` argument); see [coercion_methods] for why this coercion,
#' unlike the one for [sessioncheck()], cannot be lossless.
#'
#' @examples
#' sessionstate()
#'
#' @seealso [sessioncheck()]
#'
#' @export
sessionstate <- function() {
  new_sessionstate(
    platform    = .get_platform_info(),
    locale      = .get_locale_info(),
    matrix      = .get_matrix_info(),
    document    = .get_document_info(),
    machine     = .get_machine_info(),
    git         = .get_git_info(),
    timing      = .get_timing_info(),
    rng         = .get_rng_info(),
    libpaths    = .get_libpaths_info(),
    packages    = .get_package_inventory(),
    globalenv   = .get_globalenv_info(),
    attachments = .get_search_path_info()
  )
}

# sessionstate helpers ------

# thin wrapper around utils::osVersion for the same reason as
# .get_platform_gui() and .is_interactive() below: keeps a base R value
# that isn't always present (older R versions lack osVersion entirely)
# mockable in tests without needing to fake the OS itself
.get_os_version <- function() tryCatch(utils::osVersion, error = function(e) NA_character_)

.get_platform_info <- function() {
  os <- .get_os_version()
  if (is.null(os) || is.na(os) || !nzchar(os)) {
    os <- paste(Sys.info()[["sysname"]], Sys.info()[["release"]])
  }
  list(
    version = R.version.string,
    os      = os,
    system  = paste(R.version$system),
    ui      = .get_ui(),
    tz      = Sys.timezone(),
    date    = as.character(Sys.Date())
  )
}

# split out from .get_platform_info(): language/collate/ctype describe how
# text and dates are formatted for this session, a different dimension
# from the "what/where/when is this session running" facts platform covers
.get_locale_info <- function() {
  lc <- .get_locale_list()
  # Sys.getlocale() doesn't always report LC_COLLATE/LC_CTYPE as "NAME=value"
  # pairs (e.g. observed on macOS CI runners returning a bare locale string);
  # fall back to NA rather than silently dropping the field
  list(
    language = Sys.getenv("LANGUAGE", unset = NA_character_),
    collate  = if (is.null(lc[["LC_COLLATE"]])) NA_character_ else lc[["LC_COLLATE"]],
    ctype    = if (is.null(lc[["LC_CTYPE"]])) NA_character_ else lc[["LC_CTYPE"]]
  )
}

# split out from .get_platform_info(), mirroring how base R's sessionInfo()
# treats "Matrix products" as its own block rather than nesting it under
# platform info
.get_matrix_info <- function() {
  list(
    blas   = unname(extSoftVersion()[["BLAS"]]),
    lapack = La_library()
  )
}

# split out from .get_platform_info() for the same reason as
# .get_matrix_info(): a novel addition (no sessionInfo() precedent), but
# grouped the same way for consistency
.get_document_info <- function() {
  list(
    pandoc = .get_pandoc_version(),
    quarto = .get_quarto_version()
  )
}

# resolves the pandoc binary the way rmarkdown does: RStudio/Positron bundle
# their own pandoc and expose its directory via RSTUDIO_PANDOC, which takes
# priority over whatever "pandoc" happens to be on PATH (which may be a
# different, unrelated install, as observed while developing this)
.get_pandoc_version <- function() {
  dir <- Sys.getenv("RSTUDIO_PANDOC", unset = "")
  exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  path <- if (nzchar(dir)) file.path(dir, exe) else unname(Sys.which("pandoc"))
  .run_version_command(path, "--version")
}

# mirrors quarto::quarto_path(): QUARTO_PATH, if set, takes priority over
# PATH (kept dependency-free by not importing the quarto package)
.get_quarto_version <- function() {
  path <- Sys.getenv("QUARTO_PATH", unset = "")
  if (!nzchar(path)) path <- unname(Sys.which("quarto"))
  .run_version_command(path, "--version")
}

.run_version_command <- function(path, ...) {
  if (!nzchar(path) || !file.exists(path)) return(NA_character_)
  out <- tryCatch(
    system2(path, ..., stdout = TRUE, stderr = FALSE),
    error = function(e) character(0),
    warning = function(w) character(0)
  )
  if (length(out) == 0L || !nzchar(out[[1L]])) return(NA_character_)
  # pandoc's first line is "pandoc 3.10 ..."; quarto's is just "1.5.55" --
  # stripping a single leading word (if any) handles both
  ver <- trimws(sub("^\\S+\\s+(?=[0-9])", "", out[[1L]], perl = TRUE))
  if (!nzchar(ver)) NA_character_ else ver
}

.get_ui <- function() {
  # interactive() distinguishes an actual console session from batch/render
  # execution (e.g. Quarto/R Markdown rendering, Rscript); .Platform$GUI
  # cannot make that distinction, since it reflects the compiled/configured
  # frontend regardless of how the current call was invoked
  if (!.is_interactive()) return("non-interactive")
  # .Platform$GUI is a base R signal that already reports "Positron" and
  # "RStudio" in those IDEs (verified for Positron; documented for RStudio),
  # plus other frontends (e.g. "AQUA" for R.app, "Rgui" on Windows) that a
  # hand-rolled list of env var checks would otherwise have to track
  # one-by-one
  gui <- .get_platform_gui()
  if (!is.null(gui) && nzchar(gui)) return(gui)
  "unknown"
}

# interactive() is a primitive; mocking it directly via
# local_mocked_bindings(.package = "base") works under devtools::test() but
# not against a byte-compiled installed package (as built during R CMD
# check). Wrapping it in an ordinary closure in our own namespace, like
# .get_platform_gui() and .is_load_all_package() below, keeps it reliably
# mockable in both contexts.
.is_interactive <- function() interactive()

.get_platform_gui <- function() .Platform$GUI

.get_machine_info <- function() {
  info <- Sys.info()
  list(
    nodename = unname(info[["nodename"]]),
    user     = unname(info[["user"]]),
    cwd      = getwd()
  )
}

.get_timing_info <- function() {
  pt <- proc.time()
  list(
    captured_at = Sys.time(),
    elapsed_sec = unname(pt[["elapsed"]])
  )
}

.get_libpaths_info <- function() .libPaths()

.get_git_info <- function() {
  sha <- .run_git_command(c("rev-parse", "HEAD"))
  if (is.na(sha)) return(list(sha = NA_character_, dirty = NA))
  status <- .run_git_command(c("status", "--porcelain"))
  list(sha = sha, dirty = if (is.na(status)) NA else nzchar(status))
}

# runs a git subcommand against the current working directory (i.e. getwd(),
# matching the machine$cwd captured elsewhere), returning NA_character_ when
# git isn't installed, or the current directory isn't inside a git
# repository, rather than erroring -- most sessions won't be in a git repo,
# and that's an ordinary, non-exceptional outcome for an audit function
.run_git_command <- function(args) {
  out <- tryCatch(
    suppressWarnings(system2("git", args, stdout = TRUE, stderr = FALSE)),
    error = function(e) NULL
  )
  if (is.null(out)) return(NA_character_)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) return(NA_character_)
  if (length(out) == 0L) return("")
  paste(out, collapse = "\n")
}

.get_rng_info <- function() {
  kind <- RNGkind()
  list(
    kind        = kind[[1L]],
    normal_kind = kind[[2L]],
    sample_kind = kind[[3L]],
    seed_hash   = .hash_random_seed()
  )
}

# fingerprints .Random.seed so two renders of a document (e.g. before/after
# a small edit) can be compared for whether the edit perturbed the RNG
# state, without printing the seed itself (which is long and not
# meaningful to read directly). Returns NA if the RNG hasn't been
# initialized yet this session (i.e. nothing has consumed a random number,
# so .Random.seed doesn't exist) -- deliberately not forced into existence,
# since doing so would consume a draw as a side effect of an audit call
.hash_random_seed <- function() {
  if (!exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) return(NA_character_)
  seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  tmp <- tempfile()
  on.exit(unlink(tmp))
  # tools::md5sum() only operates on files; there is no base R function for
  # hashing an in-memory object directly, and adding a dependency (e.g.
  # digest) purely for this would violate the zero-dependency design. tools
  # is a base-priority package, so this stays dependency-free
  writeBin(as.integer(seed), tmp)
  unname(tools::md5sum(tmp))
}

.get_globalenv_info <- function() {
  objs <- ls(envir = .GlobalEnv, all.names = TRUE)
  cls <- vapply(
    objs,
    function(nm) paste(class(get(nm, envir = .GlobalEnv)), collapse = "/"),
    character(1L)
  )
  # bytes as a plain numeric so the captured object stays portable (e.g.
  # survives saveRDS()/as.data.frame() round-trips); display formatting into
  # human-readable units happens at print time via .format_object_size()
  size <- vapply(
    objs,
    function(nm) as.numeric(utils::object.size(get(nm, envir = .GlobalEnv))),
    numeric(1L)
  )
  hash <- vapply(
    objs,
    function(nm) .hash_object(get(nm, envir = .GlobalEnv)),
    character(1L)
  )
  df <- data.frame(name = objs, class = cls, size = size, hash = hash, stringsAsFactors = FALSE)
  df <- df[order(df$name), , drop = FALSE]
  rownames(df) <- NULL
  df
}

# fingerprints an arbitrary object's value via serialization, the same
# technique .hash_random_seed() uses for .Random.seed. This lets a
# comparison between two sessionstate() snapshots (see
# compare_sessionstates()) detect that a global environment object's value
# changed even when its class and size did not (e.g. a numeric vector whose
# elements were modified in place). Returns NA when the object cannot be
# serialized at all; rather than letting that abort the whole snapshot,
# the failure is recorded as "not verifiable" and left for the caller to
# decide how to treat it. Only `error` is caught, not `warning`: as of
# current R (>= 3.5.0), plain serialize(obj, connection = NULL) does not
# error on external pointers, weak references, or non-.GlobalEnv
# environments either -- with no refhook supplied, ?serialize documents
# that these reference-type objects fall back to a placeholder rather
# than erroring. Deliberate probing across a range of such objects (open
# connections, xptr slots, weak refs, R5/S4 instances, active bindings,
# locked/self-referential environments) found no case that errors, let
# alone warns, so the asymmetric error-only handling here is believed
# safe; revisit if a concrete warning-raising case turns up
.hash_object <- function(obj) {
  tmp <- tempfile()
  on.exit(unlink(tmp))
  ok <- tryCatch(
    {
      writeBin(serialize(obj, connection = NULL), tmp)
      TRUE
    },
    error = function(e) FALSE
  )
  if (!ok) return(NA_character_)
  unname(tools::md5sum(tmp))
}

.get_search_path_info <- function() {
  entries <- search()
  # mirrors the package/non-package classification used by
  # .get_attachment_status(): every entry with a "path" attribute is a
  # package, and the last entry (the base package) always is one even
  # though it carries no "path" attribute
  is_pkg <- vapply(
    seq_along(entries),
    function(ind) !is.null(attr(as.environment(ind), "path")) | ind == length(entries),
    logical(1L)
  )
  df <- data.frame(
    name = entries,
    type = ifelse(is_pkg, "package", "other"),
    stringsAsFactors = FALSE
  )
  rownames(df) <- NULL
  df
}

.get_built_rversion <- function(desc) {
  built <- desc$Built
  if (is.null(built)) return(NA_character_)
  rver <- sub("^R ([0-9.]+);.*$", "\\1", built)
  if (identical(rver, built)) NA_character_ else rver
}

# formats a package-source label together with its recorded on-disk build
# R version, e.g. "CRAN (R 4.6.0)". Falls back to the bare label (no
# parenthetical) when Built is missing or unparseable, rather than
# fabricating a build-time R version that was never recorded -- the
# current session's R version is already captured separately, in
# sessionstate()$platform$version
.format_with_built_rversion <- function(label, desc) {
  rver <- .get_built_rversion(desc)
  if (is.na(rver)) label else sprintf("%s (R %s)", label, rver)
}

# labels for known remotes::install_*() RemoteType values; anything else
# falls back to using the RemoteType string itself as the label
.remote_type_labels <- c(
  github     = "Github",
  gitlab     = "GitLab",
  bitbucket  = "Bitbucket",
  git        = "Git",
  svn        = "SVN",
  url        = "URL",
  local      = "local",
  # remotes::install_bioc() uses git2r when available, and falls back to a
  # plain git executable ("xgit") otherwise; both report RemoteRepo (the
  # package name) and RemoteMirror, but no RemoteUsername
  bioc_git2r = "Bioconductor",
  bioc_xgit  = "Bioconductor"
)

# returns NULL (rather than a fabricated placeholder) when neither field is
# set, so .format_remote_source() can omit the "@ref" suffix entirely
# instead of inventing one -- matching how sessioninfo handles remotes with
# no recorded sha/ref (e.g. a RemoteType with RemoteRepo but no RemoteSha).
# The full RemoteSha is kept as-is (not truncated) so the captured `source`
# value stays useful programmatically, e.g. for looking up the exact commit
# later; display-time abbreviation to a short, human-readable form happens
# separately in .abbrev_long_sha(), used only when printing/formatting
.get_remote_ref <- function(desc) {
  sha <- desc$RemoteSha
  if (!is.null(sha) && nzchar(sha)) return(sha)
  ref <- desc$RemoteRef
  if (!is.null(ref) && nzchar(ref)) return(ref)
  NULL
}

.format_remote_source <- function(remote_type, desc) {
  label <- if (remote_type %in% names(.remote_type_labels)) {
    .remote_type_labels[[remote_type]]
  } else {
    remote_type
  }
  ref <- .get_remote_ref(desc)
  ref_suffix <- if (!is.null(ref)) paste0("@", ref) else ""
  user <- desc$RemoteUsername
  repo <- desc$RemoteRepo
  # host-based remotes (Github, GitLab, Bitbucket, ...) report user/repo@ref,
  # or bare user/repo when no sha/ref was recorded at all
  if (!is.null(user) && nzchar(user) && !is.null(repo) && nzchar(repo)) {
    return(sprintf("%s (%s/%s%s)", label, user, repo, ref_suffix))
  }
  # remotes::install_bioc()'s bioc_git2r/bioc_xgit remotes set RemoteRepo
  # (the package name) and RemoteMirror, but no RemoteUsername
  if (!is.null(repo) && nzchar(repo)) {
    return(sprintf("%s (%s%s)", label, repo, ref_suffix))
  }
  # generic git/svn/url/local remotes (e.g. Codeberg, self-hosted Gitea,
  # remotes::install_git()/install_local() with an arbitrary URL or path)
  # report the URL/path instead, since there is no user/repo pair to show
  url <- desc$RemoteUrl
  if (!is.null(url) && nzchar(url)) {
    return(sprintf("%s (%s%s)", label, url, ref_suffix))
  }
  # pak's local installs (e.g. pak::local_install(), pak::pkg_install()
  # with a "local::<path>" spec) do not set RemoteUrl at all; the path is
  # only recorded in RemotePkgRef, with a "local::" prefix to strip
  pkg_ref <- desc$RemotePkgRef
  if (!is.null(pkg_ref) && nzchar(pkg_ref)) {
    path <- sub("^local::", "", pkg_ref)
    return(sprintf("%s (%s)", label, path))
  }
  # no user/repo, repo, url, or pkg_ref to report at all: show a
  # parenthesised ref if one exists, otherwise the bare label rather than
  # fabricating a placeholder like "(unknown)"
  if (!is.null(ref)) return(sprintf("%s (%s)", label, ref))
  label
}

.get_package_source <- function(pkg) {
  desc <- tryCatch(utils::packageDescription(pkg), error = function(e) NA)
  if (identical(desc, NA) || !is.list(desc)) return("unknown")
  if (identical(desc$Priority, "base")) return("base")

  # very old devtools::install_github() installs predate the RemoteType
  # convention entirely and instead record the ref directly in Github*
  # fields; reuse the same github formatting/truncation logic by mapping
  # them onto the modern Remote* field names
  if (!is.null(desc$GithubSHA1) && nzchar(desc$GithubSHA1)) {
    legacy_desc <- list(
      RemoteUsername = desc$GithubUsername,
      RemoteRepo = desc$GithubRepo,
      RemoteSha = desc$GithubSHA1
    )
    return(.format_remote_source("github", legacy_desc))
  }

  # pak/renv mark ordinary (non-remote) installs with RemoteType = "standard";
  # pak's other explicit package-source prefixes for CRAN-like/Bioconductor
  # repositories -- any::pkg (e.g. the "extra-packages: any::pkgdown" idiom
  # used by r-lib/actions/setup-r-dependencies, including this package's own
  # pkgdown deploy workflow), cran::pkg, and bioc::pkg -- record RemoteType
  # as "any"/"cran"/"bioc" respectively for what is still an ordinary
  # repository install, confirmed by installing via each prefix and
  # inspecting the resulting DESCRIPTION: RemoteSha is just the plain
  # package version, not a git commit, and RemotePkgRef/RemoteRef retain the
  # "<prefix>::pkg" spec rather than identifying a real remote host. All
  # four sentinels are therefore treated the same as no RemoteType at all,
  # so classification instead falls through to the Repository/biocViews
  # checks below
  remote_type <- desc$RemoteType
  if (!is.null(remote_type) && remote_type %in% c("standard", "any", "cran", "bioc")) {
    remote_type <- NULL
  }
  if (!is.null(remote_type) && nzchar(remote_type)) {
    return(.format_remote_source(remote_type, desc))
  }

  repo <- desc$Repository

  # Repository = "CRAN" is authoritative and takes priority over biocViews:
  # a package can legitimately carry a non-empty biocViews field (CRAN
  # ignores it) while still being an ordinary CRAN install, and Repository
  # being explicitly "CRAN" is a stronger signal than the biocViews
  # heuristic below, which exists to catch packages that *don't* set
  # Repository at all
  if (!is.null(repo) && identical(repo, "CRAN")) {
    return(.format_with_built_rversion("CRAN", desc))
  }

  # biocViews is a mandatory field in every Bioconductor package's
  # DESCRIPTION, so it is a more reliable signal than Repository, which
  # BiocManager-installed packages do not consistently set
  if (!is.null(desc$biocViews) && nzchar(desc$biocViews)) {
    return(.format_with_built_rversion("Bioconductor", desc))
  }

  if (!is.null(repo) && nzchar(repo)) {
    if (grepl("r-universe", repo, ignore.case = TRUE)) {
      return(.format_with_built_rversion("r-universe", desc))
    }
    # any other named repository (e.g. an RSPM mirror, an internal package
    # manager repo, etc.) - report the repository name rather than
    # mislabeling it as "CRAN"
    return(.format_with_built_rversion(repo, desc))
  }

  # a package with no remote/repository/biocViews metadata at all is either
  # a genuine local install, or the current in-development package loaded
  # via devtools::load_all() (which stubs in a namespace without going
  # through the normal install machinery)
  if (.is_load_all_package(pkg)) return("load_all()")

  "local"
}

.is_load_all_package <- function(pkg) {
  isNamespaceLoaded(pkg) && !is.null(asNamespace(pkg)$.__DEVTOOLS__)
}

# the version of the namespace actually loaded into memory, which can
# differ from the on-disk DESCRIPTION version if the package was updated
# on disk after this session loaded it
.get_loaded_version <- function(pkg) {
  if (!isNamespaceLoaded(pkg)) return(NA_character_)
  v <- tryCatch(getNamespaceVersion(pkg), error = function(e) NA_character_)
  if (is.null(v) || is.na(v)) NA_character_ else unname(v)
}

# the library path a package currently resolves to on disk, via the normal
# search mechanism used to load packages. When the loaded namespace's
# library was never part of .libPaths() at all (e.g. library(pkg,
# lib.loc = <private lib>), as R CMD check does for the package under
# test), that library is searched first: otherwise this would report
# drift against .libPaths() that never really happened -- the package was
# just loaded through an out-of-band mechanism, not moved. When the
# loaded library *is* part of .libPaths() (the ordinary case), search
# order is left untouched, so a genuine mid-session .libPaths() change
# that shadows the loaded copy with a different one is still detected
.get_ondisk_path <- function(pkg) {
  lib_loc <- .libPaths()
  loaded_path <- .get_loaded_path(pkg)
  if (!is.na(loaded_path) && !(.normalize_path(dirname(loaded_path)) %in% .normalize_path(lib_loc))) {
    lib_loc <- c(dirname(loaded_path), lib_loc)
  }
  p <- system.file(package = pkg, lib.loc = lib_loc)
  if (!nzchar(p)) NA_character_ else p
}

# resolves symlinks so that two spellings of the same real directory
# (e.g. macOS's /var -> /private/var, or a package cache that symlinks
# rather than copies) aren't treated as different locations; NA-safe
# and a no-op for paths that don't exist, since callers may pass NA or
# an already-nonexistent path
.normalize_path <- function(p) {
  ok <- !is.na(p) & nzchar(p)
  p[ok] <- normalizePath(p[ok], winslash = "/", mustWork = FALSE)
  p
}

# the library path the currently loaded namespace was actually loaded from;
# getNamespaceInfo() errors on "base" ("operation not allowed on base
# namespace"), so it needs the same system.file()-with-no-package special
# case sessioninfo uses
.get_loaded_path <- function(pkg) {
  if (identical(pkg, "base")) return(system.file())
  if (!isNamespaceLoaded(pkg)) return(NA_character_)
  p <- tryCatch(getNamespaceInfo(pkg, "path"), error = function(e) NA_character_)
  if (is.null(p) || is.na(p) || !nzchar(p)) NA_character_ else p
}

.get_package_inventory <- function() {
  pkgs <- sort(union(.packages(), loadedNamespaces()))
  attached_set <- .packages()
  ondisk_version <- vapply(pkgs, function(p) {
    v <- utils::packageDescription(p)$Version
    if (is.null(v)) NA_character_ else v
  }, character(1L))
  loaded_version <- vapply(pkgs, .get_loaded_version, character(1L))
  ondisk_path <- vapply(pkgs, .get_ondisk_path, character(1L))
  loaded_path <- vapply(pkgs, .get_loaded_path, character(1L))
  # under devtools::load_all(), system.file() resolves to inst/ while the
  # loaded namespace path is the source root: a real, structural difference
  # that isn't path drift, so load_all() packages are excluded from the
  # path_mismatch flag (matching how they're already excluded from the
  # ordinary "local" source classification)
  is_load_all <- vapply(pkgs, .is_load_all_package, logical(1L))
  df <- data.frame(
    package         = pkgs,
    attached        = pkgs %in% attached_set,
    ondisk_version  = ondisk_version,
    loaded_version  = loaded_version,
    # every package here is attached or loaded by construction, so
    # loaded_version should essentially never be NA; if it is, that's a
    # signal worth surfacing rather than masking with a FALSE mismatch
    version_mismatch = !is.na(ondisk_version) & !is.na(loaded_version) &
      ondisk_version != loaded_version,
    ondisk_path     = ondisk_path,
    loaded_path     = loaded_path,
    # "moved": both paths exist but disagree once symlinks are resolved
    # (excluding load_all() packages; see is_load_all above). Comparing
    # normalized forms avoids false positives from cosmetic path
    # differences such as macOS's /var -> /private/var alias
    path_mismatch   = !is_load_all & !is.na(ondisk_path) & !is.na(loaded_path) &
      .normalize_path(ondisk_path) != .normalize_path(loaded_path),
    # "deleted": the namespace is loaded, but it's no longer found on disk;
    # kept distinct from path_mismatch since these are different failure
    # modes worth telling apart
    removed_from_disk = is.na(ondisk_path) & !is.na(loaded_path),
    source          = vapply(pkgs, .get_package_source, character(1L)),
    stringsAsFactors = FALSE
  )
  rownames(df) <- NULL
  df
}
