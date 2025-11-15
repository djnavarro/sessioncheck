
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
