# Changelog

## sessioncheck (development version)

### Bug fixes

- Fixed a broken roxygen2 comment in
  [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)
  that caused the first sentence of the `@details` help section to be
  silently dropped. The page previously opened mid-sentence with
  “(packages that have been loaded but not attached)…”; it now correctly
  reads “This checker inspects the list of loaded namespaces (packages
  that have been loaded but not attached)…”.

- Fixed argument validation in
  [`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
  to run *after* merging the `action` argument with any value set via
  `options(sessioncheck = ...)`. Previously, an invalid `action`
  supplied through [`options()`](https://rdrr.io/r/base/options.html)
  bypassed validation entirely and produced a confusing error message
  (the session-check results) rather than a clear “invalid action”
  error.

- Fixed a typo in the formatted output for locale check results:
  “Unexpected locale setttings:” is now “Unexpected locale settings:”.

- Fixed a silent failure in
  [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
  [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
  and
  [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)
  where an unnamed `required_*` list (e.g.,
  `required_options = list(0L)`) caused all checks to be silently
  skipped. The `required_*` arguments now require a named list when
  non-empty, and passing an unnamed list is an error.

## sessioncheck 0.1.0

Initial CRAN release. The package provides tools for checking whether an
R session is in a clean state. The main user-facing functions are:

- [`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
  — flags unexpected objects in `.GlobalEnv`.
- [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
  — flags non-base packages on the search path.
- [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)
  — flags non-base loaded namespaces.
- [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
  — flags non-package attachments on the search path.
- [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md)
  — flags sessions that have been running longer than a threshold
  (default 300 seconds).
- [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md)
  — flags R options that are absent or have unexpected values.
- [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md)
  — flags locale categories that have unexpected values.
- [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)
  — flags system environment variables that are absent or have
  unexpected values.
- [`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
  — a top-level orchestrator that runs multiple checks in a single call.

All check functions accept an `action` argument (`"warn"`, `"error"`,
`"message"`, or `"none"`) and return an invisible `sessioncheck_status`
object. Default behaviour and allowlists can be configured project-wide
via `options(sessioncheck = list(...))`.
