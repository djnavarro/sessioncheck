---
name: write-roxygen-docs
description: Guidance for writing and reviewing roxygen2 documentation comments in the sessioncheck R package. Use whenever adding a new exported function, editing an existing @param/@returns/@details/@examples block, or reviewing a roxygen comment before running devtools::document().
---

# Writing roxygen2 Documentation

Roxygen comments become the content of `?function` and the pkgdown reference
site — they are read by a human user deciding whether and how to call a
function, not by a future contributor or an agent. Getting the mechanics
right (tags, `@export`, blank lines) is the easy part; agents reliably get
that right already. The failure modes worth guarding against are about
*content*: putting the wrong thing in a section, writing at the wrong level
of detail, or leaking information that shouldn't be there at all.

This skill assumes familiarity with roxygen2 basics. For deeper background on
any topic below, see [R Packages (2e), ch. 16](https://r-pkgs.org/man.html).

## What goes where

Each part of the introduction has a distinct job. Don't let content drift
into the wrong one:

- **Title** (first sentence, sentence case, no full stop): what the function
  does, distinguishing it from sibling functions. For sessioncheck's
  `check_*()` family, the title should name *what session state* is being
  checked (e.g. "Check attached packages"), not restate "check" generically.
- **Description** (next paragraph): one paragraph on *this* function's
  purpose, in different words than the title — not a restatement of it, and
  not a template copied from a sibling function. It's easy to start a new
  `check_*()` function's docs by copying an existing one and forget to
  re-target the description; the tell is a description that reads correctly
  for the *family* of functions but never actually says what this specific
  function does (that's a sign the real description got left in `@details`
  instead).
- **`@details`**: everything else — default behavior, edge cases, how an
  argument being `NULL` is treated, interactions with `sessioncheck()`. It's
  fine for this to be a few sentences to a short paragraph. Details render
  *after* arguments and return value on the help page, so don't put anything
  here that a reader needs before they can parse `@param`.
- **`@param`**: a succinct summary of what the argument controls and, if it
  has a fixed set of values (like `action`), what they are. State the
  default inline (e.g. "The default is `action = \"warn\"`") since the usage
  block and the argument description are far apart on the rendered page.
- **`@returns`**: the shape of the return value — here, always "Invisibly
  returns an object of class `sessioncheck_status`" (or
  `sessioncheck_sessioncheck` for the orchestrator). Every exported function
  must have this tag.
- **`@examples`**: runnable code showing typical usage. Not a place to
  re-explain arguments already covered in `@param`.

## Calibrating detail

Match documentation density to how novel the content actually is:

- Across the `check_*()` family, the shape is identical (action argument,
  allow/required/max argument, returns a status object) — that similarity
  belongs in the title/description pattern, not restated at length in every
  `@details`. Spend the words on what's actually distinctive: what session
  state this particular check inspects and what triggers a flag.
- A dense wall of text is harder to scan than the same information broken
  into a sentence or two per idea, or a short bullet list (roxygen2 markdown
  supports `* item` lists in any prose section). Prefer that when an
  argument has more than two or three possible values or behaviors.
- Don't pad a short, genuinely simple function's documentation just to make
  it look thorough. If the description already says everything, an empty or
  one-line `@details` — or omitting the tag — is correct.
- Once `@details` covers more than three or four distinct sub-topics (e.g.
  `sessionstate()` documenting each element of the list it returns), break
  it into markdown headings or `@section` blocks, one per sub-topic, instead
  of one long unbroken block of paragraphs. A reader looking for one specific
  fact shouldn't have to read the whole section serially to find it.
- `@section` titles must be capitalized (R Core's own
  [Rd file guidelines](https://developer.r-project.org/Rds.html) state this
  explicitly for both `\title` and `\section` titles). Don't just reuse a
  lowercase identifier (e.g. a returned list element's name) verbatim as a
  heading -- prefer a short, readable capitalized phrase (e.g. "Library
  paths" rather than "libpaths"), and refer to the actual identifier in the
  body text instead, in backticks.

## Keep it user-facing

Roxygen documentation ships to end users via `?function` and pkgdown. It is
governed by the same boundary as `NEWS.md` (see the `write-news-entries`
skill), and a couple of sessioncheck-specific ones:

- **Never reference agent- or contributor-facing material.** No mentions of
  skills, `AGENTS.md`, internal helper naming conventions, or "how this is
  implemented internally." A user reading `?check_globalenv_objects` has no
  use for the fact that it calls `.get_globalenv_objects_status()`.
- **Don't describe internal implementation details that could change.**
  Explain behavior in terms of what the function does and what the user
  observes (inputs accepted, outputs produced, what counts as a "problem"),
  not the private helper functions or data structures used to get there.
  Beyond being noise, naming a dot-prefixed internal function in
  documentation invites users to reach for it with `:::` — something this
  package's zero-dependency, stable-surface design explicitly wants to
  avoid. If you find yourself writing "internally, this calls..." or
  "`.validate_action()` is used to...", cut it.
- **Write for a reader who has never seen the source.** Avoid phrasing that
  only makes sense with the R script open (e.g. "as shown above", "the
  status vector described earlier" referring to code, not prose already in
  the same doc).
- **Cross-reference with square brackets, not just backticks.** Writing
  `` `check_globalenv_objects()` `` renders as code but produces no link;
  `[check_globalenv_objects()]` (or `[pkg::fn()]` for another package) is
  what roxygen2/pkgdown turn into an actual hyperlink. A backtick-only
  mention anywhere a function is referenced — in `@details`, `@seealso`, or
  prose — is a broken cross-reference, not a stylistic choice.

## Checklist before finishing a roxygen block

- [ ] Title names what's distinctive about this function; description
      says the same thing in different words, not a restatement of the title.
- [ ] Description actually describes *this* function, not a template
      inherited from a sibling function that describes the family in
      general instead.
- [ ] Everything in `@details` is genuinely additional to the description,
      not filler to make the section non-empty.
- [ ] If `@details` covers more than three or four sub-topics, it's broken
      into headings/`@section`s rather than left as one long block.
- [ ] Every `@section` title is capitalized, and reads as a short phrase
      rather than a bare lowercase identifier copied from the code.
- [ ] Every `@param` states the default where one exists, and enumerates
      fixed value sets.
- [ ] `@returns` is present and names the concrete class returned.
- [ ] Every reference to another function (in `@details`, `@seealso`, or
      prose) uses square brackets so it actually renders as a link, not
      backticks alone.
- [ ] No mention of skills, `AGENTS.md`, internal dot-prefixed functions, or
      other agent/contributor-facing material.
- [ ] No description of implementation details a user would need `:::` to
      verify — only observable inputs/outputs/behavior.
- [ ] Ran `devtools::document()` and skimmed the rendered `man/*.Rd` (or
      `?function` output) rather than just the roxygen comment source.
