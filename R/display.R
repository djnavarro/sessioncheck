
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
