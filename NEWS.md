# sessioncheck (development version)

## New features

- Added `sessionstate()`, a companion to `sessioncheck()` intended for use at
  the *end* of a script as an audit log. It reports platform details (R
  version, OS, matrix products, locale, timezone), selected machine
  information from `Sys.info()`, session timing, and an inventory of
  attached and loaded-namespace packages (including GitHub remote tracking,
  similar to `sessioninfo::session_info()`). Returns an object of class
  `sessioncheck_sessionstate` with `format()`, `print()`, and
  `as.data.frame()` methods.

- Improved the robustness of the package `source` classification used by
  `sessionstate()`. It now distinguishes r-universe installs and other
  named repositories from CRAN (rather than mislabeling every non-empty
  `Repository` field as `"CRAN"`), detects Bioconductor packages via the
  `biocViews` DESCRIPTION field (independent of how they were installed),
  and formats GitLab, Bitbucket, and generic git/SVN/URL remotes (e.g.
  Codeberg or self-hosted Gitea via `remotes::install_git()`) using the
  same `user/repo@sha` style as GitHub, falling back to the remote URL
  when there is no user/repo pair to show.

- Fixed `source` reporting for packages installed via `pak::local_install()`
  or `pak::pkg_install("local::<path>")`, which record the install path
  only in `RemotePkgRef` (with a `"local::"` prefix) rather than
  `RemoteUrl`; these previously showed up as an uninformative
  `"local (unknown)"`.

- Fixed `source` reporting for packages installed via
  `remotes::install_bioc()`. Verified against a real install that this
  records `RemoteType` as `"bioc_git2r"` or `"bioc_xgit"` (depending on
  whether the `git2r` package is available) along with `RemoteRepo` and
  `RemoteMirror`, but no `RemoteUsername` or `RemoteUrl`; these previously
  fell through to a raw, unlabeled `"bioc_xgit (sha)"`-style string and now
  correctly report as `"Bioconductor (repo@sha)"`.

- Fixed `source` reporting for two more cases, found by auditing
  `sessionstate()` against `sessioninfo`'s internals: packages installed
  via very old, pre-`RemoteType` versions of `devtools::install_github()`
  (which recorded `GithubUsername`/`GithubRepo`/`GithubSHA1` fields
  directly) now report as `"Github (user/repo@sha)"` instead of falling
  through to `"local"`; and packages loaded via `devtools::load_all()`
  (which have no install metadata at all) now report as `"load_all()"`
  instead of the misleading `"local"`.

- Added version-mismatch detection to `sessionstate()`'s package inventory,
  following the same audit against `sessioninfo`'s internals. The `version`
  column is renamed to `ondisk_version` (the version recorded in the
  installed package's `DESCRIPTION`), and two new columns are added:
  `loaded_version` (the version of the namespace actually loaded into
  memory) and `version_mismatch` (`TRUE` when the two disagree, e.g.
  because the package was updated on disk after this session loaded it).
  This is a breaking change for any code reading the `version` column by
  name from `as.data.frame(sessionstate())`.

- Added `path_mismatch` and `removed_from_disk` detection to
  `sessionstate()`'s package inventory, completing the `sessioninfo` audit
  started with `version_mismatch`. New columns `ondisk_path` and
  `loaded_path` record the library path a package currently resolves to
  versus where its loaded namespace actually came from; `path_mismatch` is
  `TRUE` when both exist but disagree (e.g. after a `.libPaths()` change
  mid-session), and `removed_from_disk` is `TRUE` when the namespace is
  loaded but no longer found on disk at all (kept distinct from
  `path_mismatch` since these are different failure modes). Because
  library paths often embed a home directory, the same privacy caution
  already noted for `machine` now also applies to these two columns.

- Added `platform`, `machine`, `timing`, and `packages` arguments to
  `format()`/`print()` for `sessioncheck_sessionstate` objects, letting
  users restrict which fields/columns are displayed (e.g.
  `print(sessionstate(), packages = c("package", "attached", "source"))`).
  Selection is display-only: `sessionstate()` itself always captures every
  field, and `as.data.frame()` always returns the full package inventory
  regardless of what was requested at print time. Unknown field names
  raise an informative error listing the valid choices.

- These field-selection arguments are resolved through the same precedence
  used by `sessioncheck()`: an explicit argument wins; otherwise
  `options(sessioncheck = list(sessionstate_platform = ..., sessionstate_machine
  = ..., sessionstate_timing = ..., sessionstate_packages = ...))` supplies a
  project-wide default; otherwise a built-in default applies. The built-in
  default for `packages` is now the trimmed-down
  `c("package", "attached", "loaded_version", "source")` view, rather than
  every column; `platform`, `machine`, and `timing` still default to showing
  every field.

- Simplified `ui` detection in `sessionstate()`'s platform info to use the
  base R `.Platform$GUI` signal (falling back to `"non-interactive"` first,
  via `interactive()`, for batch/render execution) instead of hand-rolled
  `Sys.getenv()` checks for Positron, RStudio, and R.app specifically.
  Confirmed empirically that `.Platform$GUI` reports `"Positron"` inside
  Positron; other frontends (RStudio, R.app, Rgui, ...) are expected to be
  reported correctly based on documented `.Platform$GUI` behavior, though
  not independently verified here.

# sessioncheck 0.1.1

## Bug fixes

- Fixed a broken roxygen2 comment in `check_loaded_namespaces()` that caused the
  first sentence of the `@details` help section to be silently dropped. The page
  previously opened mid-sentence with "(packages that have been loaded but not
  attached)..."; it now correctly reads "This checker inspects the list of loaded
  namespaces (packages that have been loaded but not attached)...".

- Fixed argument validation in `sessioncheck()` to run *after* merging the
  `action` argument with any value set via `options(sessioncheck = ...)`. Previously,
  an invalid `action` supplied through `options()` bypassed validation entirely and
  produced a confusing error message (the session-check results) rather than a
  clear "invalid action" error.

- Fixed a typo in the formatted output for locale check results: "Unexpected locale
  settings:" is now "Unexpected locale settings:".

- Fixed a silent failure in `check_required_options()`, `check_required_locale()`,
  and `check_required_sysenv()` where an unnamed `required_*` list (e.g.,
  `required_options = list(0L)`) caused all checks to be silently skipped. The
  `required_*` arguments now require a named list when non-empty, and passing an
  unnamed list is an error.

- Fixed a latent bug in the internal `.action()` helper where passing a `status`
  object of an unexpected class left the variable `is_ok` undefined, causing an
  uninformative `object 'is_ok' not found` error. The function now uses `else if`
  branching and raises an explicit "unexpected status class" error for unrecognized
  inputs.

- Fixed `sessioncheck()` to validate the `checks` argument. Previously, unrecognized
  check names (e.g. from a typo) were silently ignored; they now produce an error
  listing the valid check names.

- Fixed a misleading mock in the `sessioncheck()` test suite: the mock for
  `.get_locale_status()` was returning a bare string instead of a
  `sessioncheck_status` object, making the associated assertion meaningless. The
  mock now returns a properly-constructed status object.

## Testing

- Added `spelling` to `Suggests` and added a spell-check test
  (`tests/testthat/test-spelling.R`) so that `spelling::spell_check_package()`
  runs automatically with `devtools::test()`. The test is skipped on CRAN.

## Documentation

- Updated the `DESCRIPTION` to accurately reflect the full scope of the package.
  The previous description mentioned only the global environment and loaded
  namespaces; it now covers all eight check types (global environment, attached
  packages, loaded namespaces, attached environments, session run time, R options,
  locale settings, and system environment variables).

- Fixed the `@details` section of `check_attached_packages()`, which referred to
  the parameter as `allow` rather than its correct name `allow_attached_packages`.

- Fixed the `@examples` block of `check_required_locale()`, which passed
  `required = list(...)` instead of `required_locale = list(...)`. The call
  worked only through R's partial argument matching, which is fragile and
  misleading in documentation.

- Removed self-referential links from the `@seealso` section of each check
  function. Each function previously listed itself among the "see also" links.

# sessioncheck 0.1.0

Initial CRAN release. The package provides tools for checking whether an R session
is in a clean state. The main user-facing functions are:

- `check_globalenv_objects()` — flags unexpected objects in `.GlobalEnv`.
- `check_attached_packages()` — flags non-base packages on the search path.
- `check_loaded_namespaces()` — flags non-base loaded namespaces.
- `check_attached_environments()` — flags non-package attachments on the search path.
- `check_sessiontime()` — flags sessions that have been running longer than a
  threshold (default 300 seconds).
- `check_required_options()` — flags R options that are absent or have unexpected values.
- `check_required_locale()` — flags locale categories that have unexpected values.
- `check_required_sysenv()` — flags system environment variables that are absent
  or have unexpected values.
- `sessioncheck()` — a top-level orchestrator that runs multiple checks in a
  single call.

All check functions accept an `action` argument (`"warn"`, `"error"`, `"message"`,
or `"none"`) and return an invisible `sessioncheck_status` object. Default behavior
and allowlists can be configured project-wide via `options(sessioncheck = list(...))`.
