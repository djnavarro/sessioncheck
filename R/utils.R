
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
