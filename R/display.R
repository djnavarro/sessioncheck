
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
# Positron has no documented equivalent as of this writing, so it is not
# handled here; isatty(stdout()) is FALSE in the Positron console too, so
# color will only appear there when `cli.num_colors` is set explicitly.
.rstudio_console_with_color <- function() {
  if (!identical(Sys.getenv("RSTUDIO", ""), "1")) return(FALSE)
  cols <- Sys.getenv("RSTUDIO_CONSOLE_COLOR", "")
  !is.na(suppressWarnings(as.numeric(cols)))
}

# detects whether ANSI escape codes are safe to emit. `cli.num_colors` is
# checked first so that this defers to detection already performed by other
# packages (e.g. cli) when present.
.ansi_enabled <- function() {
  opt <- getOption("cli.num_colors", NULL)
  if (!is.null(opt)) return(opt > 1)

  # https://no-color.org
  if (nzchar(Sys.getenv("NO_COLOR", ""))) return(FALSE)

  # knitr/Quarto capture output to a string buffer, not a real terminal
  if (isTRUE(getOption("knitr.in.progress"))) return(FALSE)

  # output has been redirected/captured (e.g. capture.output(), testthat)
  if (sink.number() > 0) return(FALSE)

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
