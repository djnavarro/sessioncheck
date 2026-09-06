
# display helpers ------

# unicode symbols used to prefix formatted status output, with an ASCII
# fallback for locales/terminals that cannot render UTF-8
.symbols_unicode <- c(
  tick   = "\u2714",
  cross  = "\u2716",
  bullet = "\u2022",
  line   = "\u2500"
)

.symbols_ascii <- c(
  tick   = "v",
  cross  = "x",
  bullet = "*",
  line   = "-"
)

# mirrors base R's own UTF-8 capability check (see l10n_info()) rather than
# hard-coding platform assumptions
.unicode_enabled <- function() {
  isTRUE(l10n_info()[["UTF-8"]])
}

.symbol <- function(name) {
  set <- if (.unicode_enabled()) .symbols_unicode else .symbols_ascii
  unname(set[[name]])
}

# ansi color support ------

# detects RStudio's Console pane specifically. RStudio (>= 1.3) sets
# RSTUDIO_CONSOLE_COLOR only in the Console pane, not in the Terminal pane,
# Build pane, or RStudio Jobs, so this is a safe, console-scoped signal --
# unlike a bare RSTUDIO == "1" check, which is set in all of those contexts.
# Mirrors the approach used by crayon/cli's rstudio_with_ansi_support().
.rstudio_console_with_color <- function() {
  if (!identical(Sys.getenv("RSTUDIO", ""), "1")) return(FALSE)
  cols <- Sys.getenv("RSTUDIO_CONSOLE_COLOR", "")
  !is.na(suppressWarnings(as.numeric(cols)))
}

# detects Positron's console. ark (Positron's R kernel) sets
# options(cli.default_num_colors = <n>) directly at session startup to tell
# `cli` that its console can render ANSI color, bypassing isatty()/RSTUDIO
# style detection entirely -- Positron's console is not a real tty, and it
# does not set RSTUDIO = "1". Scoped to Sys.getenv("POSITRON") == "1" so
# this doesn't trust `cli.default_num_colors` if something else set it
# outside of a Positron session.
.positron_console_with_color <- function() {
  if (!identical(Sys.getenv("POSITRON", ""), "1")) return(FALSE)
  n <- getOption("cli.default_num_colors", NULL)
  is.numeric(n) && n > 1
}

# detects whether ANSI escape codes are safe to emit. `cli.num_colors` is
# checked first so that this defers to detection already performed by other
# packages (e.g. cli) when present. After that, front end signals are
# checked in order: Positron's console, then RStudio's console, falling
# back to isatty(stdout()) for plain terminals.
.ansi_enabled <- function() {
  opt <- getOption("cli.num_colors", NULL)
  if (!is.null(opt)) return(opt > 1)

  # https://no-color.org
  if (nzchar(Sys.getenv("NO_COLOR", ""))) return(FALSE)

  # knitr/Quarto capture output to a string buffer, not a real terminal
  if (isTRUE(getOption("knitr.in.progress"))) return(FALSE)

  # output has been redirected/captured (e.g. capture.output(), testthat)
  if (sink.number() > 0) return(FALSE)

  if (.positron_console_with_color()) return(TRUE)
  if (.rstudio_console_with_color()) return(TRUE)

  isatty(stdout())
}

.ansi_style <- function(code) {
  force(code)
  function(text) {
    if (!.ansi_enabled()) return(text)
    paste0("\033[", code, "m", text, "\033[0m")
  }
}

.col_green <- .ansi_style("32")
.col_red   <- .ansi_style("31")
.col_blue  <- .ansi_style("34")
.style_dim <- .ansi_style("2")

# combines a symbol with the color conventionally associated with it: green
# for "ok", red for "problem", blue for a neutral/informational bullet with
# no pass/fail meaning; falls back to a plain symbol when .ansi_enabled()
# is FALSE
.colored_symbol <- function(name) {
  col <- switch(name, tick = .col_green, cross = .col_red, bullet = .col_blue, identity)
  col(.symbol(name))
}

# prefixes a line of item-level information with a neutral bullet
# symbol/color; used for the scalar fields and library paths in
# format.sessioncheck_sessionstate(), which is a plain snapshot with no
# pass/fail semantics, unlike the tick/cross used for sessioncheck_status.
# Vectorized: recycles the bullet against a character vector of lines.
.bullet_line <- function(text) {
  paste(.colored_symbol("bullet"), text)
}

# formats a single expected/actual value for display in
# .message_text_detail(); option/locale/sysenv values aren't guaranteed to
# be simple length-1 strings (an option can hold an arbitrary R object), so
# this degrades gracefully instead of assuming format() always returns
# something short and readable
.format_compare_value <- function(v) {
  if (is.null(v)) return("NULL")
  if (!is.atomic(v)) return(paste0("<", class(v)[1L], ">"))
  if (length(v) != 1L) return(paste0("c(", paste(format(v), collapse = ", "), ")"))
  format(v)
}

# like .message_text(), but for checks where a problem can mean either
# "missing" or "present with the wrong value" (options/locale/sysenv --
# see #5). Uses the "expected"/"actual"/"present" attributes attached by
# .get_xiny_status() to say which, and to report the value(s) involved,
# rather than just naming the offending entry. Falls back to
# .message_text()'s plain name list when those attributes aren't present
# (e.g. a sessioncheck_status of type "options" built by hand rather than
# via .get_options_status()).
.message_text_detail <- function(prefix, status, max_len = 4L) {
  expected <- attr(status, "expected")
  actual <- attr(status, "actual")
  present <- attr(status, "present")
  if (is.null(expected) || is.null(actual) || is.null(present)) {
    return(.message_text(prefix, status, max_len))
  }

  bad <- names(status[status])
  len <- length(bad)
  symbol <- .colored_symbol(if (len == 0L) "tick" else "cross")
  if (len == 0L) return(paste(symbol, prefix, "[no issues detected]"))

  shown <- if (len <= max_len) bad else bad[seq_len(max_len)]
  detail <- vapply(
    shown,
    function(nn) {
      exp_txt <- .format_compare_value(expected[[nn]])
      if (!isTRUE(present[[nn]])) {
        sprintf("%s: missing (expected %s)", nn, exp_txt)
      } else {
        sprintf("%s: expected %s, got %s", nn, exp_txt, .format_compare_value(actual[[nn]]))
      }
    },
    character(1L)
  )
  lines <- paste0("    ", detail)
  if (len > max_len) lines <- c(lines, sprintf("    ... and %d more", len - max_len))
  paste(c(paste(symbol, prefix), lines), collapse = "\n")
}

# draws a horizontal rule with a left-aligned title, used as a section
# heading in format.sessioncheck_sessionstate() -- similar in spirit to the
# section dividers in sessioninfo::session_info() and to mcli_rule() from
# the minicli script. Dimmed when ansi is enabled so it recedes visually
# behind the content it introduces.
.rule <- function(title, width = getOption("width", 80L)) {
  width <- max(width, 10L)
  ch <- .symbol("line")
  label <- paste0(ch, " ", title, " ")
  fill <- max(0L, width - nchar(label))
  .style_dim(paste0(label, strrep(ch, fill)))
}
