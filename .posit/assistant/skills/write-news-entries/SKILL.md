---
name: write-news-entries
description: Guidance for writing entries in NEWS.md for the sessioncheck R package. Use whenever adding, updating, or reviewing a NEWS.md entry, e.g. after implementing a new feature, fixing a bug, or making an API change.
---

# Writing NEWS.md Entries

`NEWS.md` is a user-facing changelog, not a commit log or a design document.
Unreleased changes accumulate under the `# sessioncheck (development version)`
heading at the top of the file, grouped into `## New features`,
`## Improvements`, `## Bug fixes`, `## Testing`, and `## Documentation`
subsections. When a release is cut, that heading is replaced with a version
number (e.g. `# sessioncheck 0.1.1`) and a fresh `(development version)`
heading is added above it for the next cycle.

Two failure modes recur when writing entries here: restating information that
already lives elsewhere (function documentation, a linked GitHub issue), and
describing changes to code that was never in a CRAN release in the first
place. The rules below exist to avoid both.

## Rules

1. **Keep it short.** One sentence is usually enough; two only if the change
   genuinely needs it. A bare function name like `` check_working_directory() ``
   is auto-linked by pkgdown straight to its help page, so do not restate
   parameter names, defaults, algorithmic detail, or examples that are already
   covered in that function's `@details`/`@examples`. The NEWS entry's job is
   to say *that* something changed and give just enough context to decide
   whether to click through — not to duplicate the documentation.

2. **NEWS.md is strictly user-facing.** Never reference or link to
   agent-facing or contributor-facing material: skills, `AGENTS.md`/
   `DATABOT.md`, internal dot-prefixed helper functions, CI configuration, or
   "how we implemented this" narrative. If a change has no visible effect on
   the public API, documented behavior, or output (e.g. an internal helper
   was refactored, a private function gained an argument nothing exported
   uses), it does not belong in NEWS.md at all — skip it rather than finding
   a way to phrase it.

3. **Only describe what changed since the last CRAN release.** Check the
   heading at the top of the file: everything under
   `# sessioncheck (development version)` is unreleased. If a bug being fixed
   was introduced by a feature added earlier in the *same* development cycle
   (i.e. that feature has never shipped to CRAN), it is not a user-visible
   "bug fix" — it's the feature working correctly. Don't add a `## Bug fixes`
   entry for it; either revise the original feature's own bullet if it needs
   correcting, or just fix the code silently. Only regressions in code that
   already shipped in a previous numbered release deserve their own
   `## Bug fixes` bullet.

4. **Point to the issue/PR instead of re-explaining it.** Append `(#N)` to the
   end of the bullet when a GitHub issue or PR number exists. Don't restate
   the issue's background, discussion, or design rationale — that history is
   already written down in the issue itself, one click away.

5. **Match the existing structure and voice.** Group each bullet under the
   closest matching heading (`## New features`, `## Improvements`,
   `## Bug fixes`, `## Testing`, `## Documentation`), only adding a new
   heading if none fits. Start each bullet with a past-tense verb ("Added",
   "Fixed", "Changed", "Removed", "Deprecated").

## Example

Too long — restates documentation detail and mentions an internal helper:

```md
- Added `check_working_directory()`, which flags a session whose working
  directory (`getwd()`) does not match a `required_wd` path. Paths are
  compared via `normalizePath()`, so trailing slashes and relative vs.
  absolute forms don't produce false positives. When `required_wd = NULL`
  (the default), the check always passes and simply reports the current
  working directory. Integrates with `sessioncheck()` via
  `checks = "working_directory"` and the `required_wd` argument (#11).

- `.session_snapshot()` (used internally by `.onLoad()`) now also records the
  working directory (`wd`), for use by a future snapshot-based working
  directory check (#11).
```

Right level of detail — says what changed, links to the function for the rest,
skips the internal-only change entirely:

```md
- Added `check_working_directory()`, which checks the session's working
  directory against an expected path (#11).
```

## Checklist before adding an entry

- [ ] Is this visible to a user of the package, not just to future
      contributors? If not, skip NEWS.md entirely.
- [ ] If this is a bug fix, did the bug exist in a previously released
      version (`# sessioncheck 0.1.1` or earlier), rather than being a
      same-cycle regression in unreleased code?
- [ ] Is the bullet one or two sentences, with parameter/implementation
      detail left to the function's own documentation?
- [ ] Does it rely on pkgdown's auto-linking of bare function names rather
      than re-describing what that link leads to?
- [ ] Does it append `(#N)` instead of re-explaining the linked issue/PR?
- [ ] Does it avoid mentioning skills, `AGENTS.md`, internal dot-prefixed
      helpers, or other agent/contributor-facing material?
