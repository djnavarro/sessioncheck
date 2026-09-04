
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
  lc <- .get_locale_list()
  os <- tryCatch(utils::osVersion, error = function(e) NA_character_)
  if (is.null(os) || is.na(os) || !nzchar(os)) {
    os <- paste(Sys.info()[["sysname"]], Sys.info()[["release"]])
  }
  ui <- .get_ui()
  blas <- unname(extSoftVersion()[["BLAS"]])
  lapack <- La_library()
  list(
    version  = R.version.string,
    os       = os,
    system   = paste(R.version$system),
    ui       = ui,
    language = Sys.getenv("LANGUAGE", unset = NA_character_),
    collate  = lc[["LC_COLLATE"]],
    ctype    = lc[["LC_CTYPE"]],
    tz       = Sys.timezone(),
    date     = as.character(Sys.Date()),
    blas     = blas,
    lapack   = lapack
  )
}

.get_ui <- function() {
  if (nzchar(Sys.getenv("POSITRON"))) return("Positron")
  if (nzchar(Sys.getenv("RSTUDIO"))) return("RStudio")
  if (!is.na(Sys.getenv("R_GUI_APP_VERSION", unset = NA_character_))) return("R.app")
  if (!interactive()) return("non-interactive")
  "unknown"
}

.get_machine_info <- function() {
  info <- Sys.info()
  list(
    nodename = unname(info[["nodename"]]),
    user     = unname(info[["user"]])
  )
}

.get_timing_info <- function() {
  pt <- proc.time()
  list(
    captured_at = Sys.time(),
    elapsed_sec = unname(pt[["elapsed"]])
  )
}

.get_package_source <- function(pkg) {
  desc <- tryCatch(utils::packageDescription(pkg), error = function(e) NA)
  if (identical(desc, NA) || !is.list(desc)) return("unknown")
  if (identical(desc$Priority, "base")) return("base")
  remote_type <- desc$RemoteType
  if (!is.null(remote_type) && identical(remote_type, "standard")) remote_type <- NULL
  if (!is.null(remote_type) && nzchar(remote_type)) {
    if (identical(remote_type, "github")) {
      sha <- desc$RemoteSha
      sha7 <- if (!is.null(sha) && nzchar(sha)) substr(sha, 1L, 7L) else "unknown"
      return(sprintf("Github (%s/%s@%s)", desc$RemoteUsername, desc$RemoteRepo, sha7))
    }
    ref <- desc$RemoteSha
    ref <- if (!is.null(ref) && nzchar(ref)) substr(ref, 1L, 7L) else desc$RemoteRef
    return(sprintf("%s (%s)", remote_type, if (is.null(ref)) "unknown" else ref))
  }
  if (!is.null(desc$Repository) && nzchar(desc$Repository)) {
    built <- desc$Built
    rver <- if (!is.null(built)) sub("^R ([0-9.]+);.*$", "\\1", built) else NA_character_
    if (is.na(rver) || identical(rver, built)) rver <- paste(getRversion())
    return(sprintf("CRAN (R %s)", rver))
  }
  "local"
}

.get_package_inventory <- function() {
  pkgs <- sort(union(.packages(), loadedNamespaces()))
  attached_set <- .packages()
  df <- data.frame(
    package  = pkgs,
    attached = pkgs %in% attached_set,
    version  = vapply(pkgs, function(p) {
      v <- utils::packageDescription(p)$Version
      if (is.null(v)) NA_character_ else v
    }, character(1L)),
    source   = vapply(pkgs, .get_package_source, character(1L)),
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
