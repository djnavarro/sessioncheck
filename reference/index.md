# Package index

## Session check

Run one or more checks at once

- [`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
  : Checks the overall status of the R session

## Session checkers

Individual session check functions

- [`check_globalenv()`](https://sessioncheck.djnavarro.net/reference/object_checks.md)
  [`check_attachments()`](https://sessioncheck.djnavarro.net/reference/object_checks.md)
  : Check global environment and attached environments
- [`check_packages()`](https://sessioncheck.djnavarro.net/reference/package_checks.md)
  [`check_namespaces()`](https://sessioncheck.djnavarro.net/reference/package_checks.md)
  : Check loaded namespaces and attached packages
- [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/sessiontime_checks.md)
  : Check session run time
- [`check_options()`](https://sessioncheck.djnavarro.net/reference/value_checks.md)
  [`check_sysenv()`](https://sessioncheck.djnavarro.net/reference/value_checks.md)
  [`check_locale()`](https://sessioncheck.djnavarro.net/reference/value_checks.md)
  : Check required values for options, locale, and environment

## Methods

S3 methods for session check classes

- [`format(`*`<sessioncheck_status>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`format(`*`<sessioncheck_sessioncheck>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`print(`*`<sessioncheck_status>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`print(`*`<sessioncheck_sessioncheck>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  : Format and print sessioncheck objects
- [`as.data.frame(`*`<sessioncheck_status>`*`)`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
  [`as.data.frame(`*`<sessioncheck_sessioncheck>`*`)`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
  : Coerce session check object to a data frame
