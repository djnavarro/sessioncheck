
# display helpers ------

# unicode symbols used to prefix formatted status output, with an ASCII
# fallback for locales/terminals that cannot render UTF-8
.symbols_unicode <- c(
  tick  = "\u2714",
  cross = "\u2716"
)

.symbols_ascii <- c(
  tick  = "v",
  cross = "x"
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

# detects whether ANSI escape codes are safe to emit. `cli.num_colors` is
# checked first so that this defers to detection already performed by other
# packages (e.g. cli) when present; note that RStudio/Positron consoles
# report isatty(stdout()) == FALSE despite being able to render ANSI, so
# color will not appear there unless `cli.num_colors` is set explicitly
.ansi_enabled <- function() {
  opt <- getOption("cli.num_colors", NULL)
  if (!is.null(opt)) return(opt > 1)

  # https://no-color.org
  if (nzchar(Sys.getenv("NO_COLOR", ""))) return(FALSE)

  # knitr/Quarto capture output to a string buffer, not a real terminal
  if (isTRUE(getOption("knitr.in.progress"))) return(FALSE)

  # output has been redirected/captured (e.g. capture.output(), testthat)
  if (sink.number() > 0) return(FALSE)

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

# combines a symbol with the color conventionally associated with it (green
# for "ok", red for "problem"); falls back to a plain symbol when
# .ansi_enabled() is FALSE
.colored_symbol <- function(name) {
  col <- switch(name, tick = .col_green, cross = .col_red, identity)
  col(.symbol(name))
}
