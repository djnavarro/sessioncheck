# Package index

## Core functions

Check and report the session state

- [`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
  : Checks the overall status of the R session
- [`sessionstate()`](https://sessioncheck.djnavarro.net/reference/sessionstate.md)
  : Report the current state of the R session

## Session checkers

Individual session check functions

- [`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
  : Check global environment objects
- [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
  : Check environments attached to the search path
- [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
  : Check attached packages
- [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)
  : Check loaded namespaces
- [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md)
  : Check session run time
- [`check_working_directory()`](https://sessioncheck.djnavarro.net/reference/check_working_directory.md)
  : Check the working directory
- [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md)
  : Check required values for options
- [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md)
  : Check required values for locale settings
- [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)
  : Check required values for system environment variables

## Methods

S3 methods for session check classes

- [`format(`*`<sessioncheck_status>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`format(`*`<sessioncheck_sessioncheck>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`print(`*`<sessioncheck_status>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`print(`*`<sessioncheck_sessioncheck>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`format(`*`<sessioncheck_sessionstate>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  [`print(`*`<sessioncheck_sessionstate>`*`)`](https://sessioncheck.djnavarro.net/reference/display_methods.md)
  : Format and print sessioncheck objects
- [`as.data.frame(`*`<sessioncheck_status>`*`)`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
  [`as.data.frame(`*`<sessioncheck_sessioncheck>`*`)`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
  [`as.data.frame(`*`<sessioncheck_sessionstate>`*`)`](https://sessioncheck.djnavarro.net/reference/coercion_methods.md)
  : Coerce session check object to a data frame
