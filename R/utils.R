
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
#
# in addition to the status vector itself, this attaches "expected"/
# "actual"/"present" attributes recording, for each entry in `x`, the
# required value, the value actually found in `y` (if any), and whether it
# was found at all. This lets format.sessioncheck_status() tell a missing
# option/locale/sysenv value apart from one with the wrong value, rather
# than lumping both into the same "unexpected" label (see #5). The
# attributes are additive -- the status vector itself is unchanged from
# before, so any code that only looks at names/values of the vector
# continues to work as it did.
.get_xiny_status <- function(x, y) {
  nms <- names(x)
  present <- nms %in% names(y)
  names(present) <- nms
  status <- vapply(
    nms,
    function(nn) {
      if (!present[[nn]]) return(c(nn = TRUE))
      if (identical(x[[nn]], y[[nn]])) return(c(nn = FALSE))
      c(nn = TRUE)
    },
    logical(1L)
  )
  actual <- lapply(nms, function(nn) if (present[[nn]]) y[[nn]] else NULL)
  names(actual) <- nms
  attr(status, "expected") <- x
  attr(status, "actual") <- actual
  attr(status, "present") <- present
  status
}

.get_locale_list <- function() {
  lc_vec <- strsplit(Sys.getlocale(), ";")[[1]]
  lc_lst <- strsplit(lc_vec, "=", fixed = TRUE)
  lc_lbl <- vapply(lc_lst, function(x) x[1L], character(1L))
  lc_val <- vapply(lc_lst, function(x) x[2L], character(1L))
  lc <- as.list(lc_val)
  names(lc) <- lc_lbl
  lc
}
