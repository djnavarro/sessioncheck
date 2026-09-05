
.sessioncheck_env <- new.env()

.onLoad <- function(libname, pkgname) {
  assign("snapshot", .session_snapshot(), .sessioncheck_env)
}

.session_snapshot <- function() {
  list(
    sys_time = Sys.time(),
    options = options(),
    packages = .packages(),
    namespaces = loadedNamespaces(),
    attached = search(),
    proc_time = proc.time(),
    globalenv =  ls(envir = .GlobalEnv, all.names = TRUE),
    locale = Sys.getlocale(),
    sys_env = Sys.getenv()
  )
}

# status code:
# FALSE = exists in both and matches
# TRUE  = mismatched value or not in y
# (not included) = does not exist in x 
.get_xiny_status <- function(x, y) (
  vapply(
    names(x),
    function(nn) {
      if (!(nn %in% names(y))) return(c(nn = TRUE))
      if (identical(x[[nn]], y[[nn]])) return(c(nn = FALSE))
      c(nn = TRUE)
    },
    logical(1L)
  )
)

.get_locale_list <- function() {
  lc_vec <- strsplit(Sys.getlocale(), ";")[[1]]
  lc_lst <- strsplit(lc_vec, "=", fixed = TRUE)
  lc_lbl <- vapply(lc_lst, function(x) x[1L], character(1L))
  lc_val <- vapply(lc_lst, function(x) x[2L], character(1L))
  lc <- as.list(lc_val)
  names(lc) <- lc_lbl
  lc
}

# sessionstate helpers ------

.get_platform_info <- function() {
  os <- tryCatch(utils::osVersion, error = function(e) NA_character_)
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
  list(
    language = Sys.getenv("LANGUAGE", unset = NA_character_),
    collate  = lc[["LC_COLLATE"]],
    ctype    = lc[["LC_CTYPE"]]
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
  df <- data.frame(name = objs, class = cls, size = size, stringsAsFactors = FALSE)
  df <- df[order(df$name), , drop = FALSE]
  rownames(df) <- NULL
  df
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
  rver <- if (!is.null(built)) sub("^R ([0-9.]+);.*$", "\\1", built) else NA_character_
  if (is.na(rver) || identical(rver, built)) rver <- paste(getRversion())
  rver
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

.get_remote_ref <- function(desc) {
  sha <- desc$RemoteSha
  if (!is.null(sha) && nzchar(sha)) return(substr(sha, 1L, 7L))
  ref <- desc$RemoteRef
  if (!is.null(ref) && nzchar(ref)) return(ref)
  "unknown"
}

.format_remote_source <- function(remote_type, desc) {
  label <- if (remote_type %in% names(.remote_type_labels)) {
    .remote_type_labels[[remote_type]]
  } else {
    remote_type
  }
  ref <- .get_remote_ref(desc)
  user <- desc$RemoteUsername
  repo <- desc$RemoteRepo
  # host-based remotes (Github, GitLab, Bitbucket, ...) report user/repo@ref
  if (!is.null(user) && nzchar(user) && !is.null(repo) && nzchar(repo)) {
    return(sprintf("%s (%s/%s@%s)", label, user, repo, ref))
  }
  # remotes::install_bioc()'s bioc_git2r/bioc_xgit remotes set RemoteRepo
  # (the package name) and RemoteMirror, but no RemoteUsername
  if (!is.null(repo) && nzchar(repo)) {
    return(sprintf("%s (%s@%s)", label, repo, ref))
  }
  # generic git/svn/url/local remotes (e.g. Codeberg, self-hosted Gitea,
  # remotes::install_git()/install_local() with an arbitrary URL or path)
  # report the URL/path instead, since there is no user/repo pair to show
  url <- desc$RemoteUrl
  if (!is.null(url) && nzchar(url)) {
    return(sprintf("%s (%s@%s)", label, url, ref))
  }
  # pak's local installs (e.g. pak::local_install(), pak::pkg_install()
  # with a "local::<path>" spec) do not set RemoteUrl at all; the path is
  # only recorded in RemotePkgRef, with a "local::" prefix to strip
  pkg_ref <- desc$RemotePkgRef
  if (!is.null(pkg_ref) && nzchar(pkg_ref)) {
    path <- sub("^local::", "", pkg_ref)
    return(sprintf("%s (%s)", label, path))
  }
  sprintf("%s (%s)", label, ref)
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
  # treat that the same as no RemoteType at all
  remote_type <- desc$RemoteType
  if (!is.null(remote_type) && identical(remote_type, "standard")) remote_type <- NULL
  if (!is.null(remote_type) && nzchar(remote_type)) {
    return(.format_remote_source(remote_type, desc))
  }

  # biocViews is a mandatory field in every Bioconductor package's
  # DESCRIPTION, so it is a more reliable signal than Repository, which
  # BiocManager-installed packages do not consistently set
  if (!is.null(desc$biocViews) && nzchar(desc$biocViews)) {
    return(sprintf("Bioconductor (R %s)", .get_built_rversion(desc)))
  }

  repo <- desc$Repository
  if (!is.null(repo) && nzchar(repo)) {
    if (identical(repo, "CRAN")) {
      return(sprintf("CRAN (R %s)", .get_built_rversion(desc)))
    }
    if (grepl("r-universe", repo, ignore.case = TRUE)) {
      return(sprintf("r-universe (R %s)", .get_built_rversion(desc)))
    }
    # any other named repository (e.g. an RSPM mirror, an internal package
    # manager repo, etc.) - report the repository name rather than
    # mislabeling it as "CRAN"
    return(sprintf("%s (R %s)", repo, .get_built_rversion(desc)))
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
  if (!is.na(loaded_path) && !(dirname(loaded_path) %in% lib_loc)) {
    lib_loc <- c(dirname(loaded_path), lib_loc)
  }
  p <- system.file(package = pkg, lib.loc = lib_loc)
  if (!nzchar(p)) NA_character_ else p
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
    # "moved": both paths exist but disagree (excluding load_all() packages;
    # see is_load_all above)
    path_mismatch   = !is_load_all & !is.na(ondisk_path) & !is.na(loaded_path) &
      ondisk_path != loaded_path,
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

.parse_args <- function(...) {
  args <- list(...)
  opts_args <- getOption("sessioncheck")
  if (is.list(opts_args)) {
    if (is.null(args$action)) args$action <- opts_args$action
    if (is.null(args$checks)) args$checks <- opts_args$checks
    if (is.null(args$allow_globalenv_objects)) args$allow_globalenv_objects <- opts_args$allow_globalenv_objects
    if (is.null(args$allow_attached_packages)) args$allow_attached_packages <- opts_args$allow_attached_packages
    if (is.null(args$allow_loaded_namespaces)) args$allow_loaded_namespaces <- opts_args$allow_loaded_namespaces
    if (is.null(args$allow_attached_environments)) args$allow_attached_environments <- opts_args$allow_attached_environments
    if (is.null(args$max_sessiontime)) args$max_sessiontime <- opts_args$max_sessiontime
    if (is.null(args$required_options)) args$required_options <- opts_args$required_options
    if (is.null(args$required_locale)) args$required_locale <- opts_args$required_locale
    if (is.null(args$required_sysenv)) args$required_sysenv <- opts_args$required_sysenv 
  }
  args
}
