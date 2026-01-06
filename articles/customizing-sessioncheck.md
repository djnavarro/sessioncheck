# Customizing sessioncheck() behavior

This article discusses how to customise the checks that are performed
when
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is called. The easiest way to alter its behavior is via the `action`
argument, which specifies what action should be taken if an issue is
detected (allowed values: `"warn"`, `"error"`, `"message"`, `"none"`),
and via the `checks` argument, which specifies which checks should be
performed. The default behaviour corresponds to this:

``` r
sessioncheck::sessioncheck(
  action = "warn",
  checks = c(
    "globalenv_objects", 
    "attached_packages", 
    "attached_environments"
  )
)
```

In this case, three checks are performed:

- `"globalenv_objects"` indicates that
  [`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
  should be used
- `"attached_packages"` indicates that
  [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
  should be used
- `"attached_environments"` indicates that
  [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
  should be used

Several other options can be specified:

- `"loaded_namespaces"` indicates that
  [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)
  should be used
- `"sessiontime"` indicates that
  [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md)
  should be used
- `"required_options"` indicates that
  [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md)
  should be used
- `"required_locale"` indicates that
  [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md)
  should be used
- `"required_sysenv"` indicates that
  [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)
  should be used

For example, this checks the loaded namespaces only:

``` r
sessioncheck::sessioncheck(
  action = "warn",
  checks = "loaded_namespaces"
)
#> Warning: Session check results:
#> - Loaded namespaces: digest, desc, R6, fastmap, and 19 more
```

The individual checks can themselves be customized. Each check function
has one extra argument that is used to control its behavior, and these
can be passed to the check function via `...`. For example, you can do
this:

``` r
sessioncheck::sessioncheck(
  action = "warn",
  checks = c("loaded_namespaces", "required_options"),
  allow_loaded_namespaces = c("knitr", "vctrs", "cli"),
  required_options = list(scipen = 0L, max.print = 50L)
)
#> Warning: Session check results:
#> - Loaded namespaces: digest, desc, R6, fastmap, and 17 more
#> - Unexpected options: max.print
```

The relevant arguments that can be passed via `...` are as follows:

- `allow_globalenv_objects` is passed to
  [`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
- `allow_attached_packages` is passed to
  [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
- `allow_attached_environments` is passed to
  [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
- `allow_loaded_namespaces` is passed to
  [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)
- `max_sessiontime` is passed to
  [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md)
- `required_options` is passed to
  [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md)
- `required_locale` is passed to
  [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md)
- `required_sysenv` is passed to
  [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

To make life a little easier, the default values for all arguments can
be specified via [`options()`](https://rdrr.io/r/base/options.html). For
example, you could include something like this in the `.Rprofile`:

``` r
options(
  sessioncheck = list(
    action = "message",
    checks = c("loaded_namespaces", "required_options"),
    allow_loaded_namespaces = c("knitr", "vctrs", "cli"),
    required_options = list(scipen = 0L, max.print = 50L)
  )
)
```

When called,
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
will now use these values:

``` r
sessioncheck::sessioncheck()
#> Session check results:
#> - Loaded namespaces: digest, desc, R6, fastmap, and 17 more
#> - Unexpected options: max.print
```

For more information on the specifics of each check, please see the
documentation of the relevant check function or the article on
[individual
checks](https://sessioncheck.djnavarro.net/articles/individual-checks.html).
