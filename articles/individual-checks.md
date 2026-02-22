# Individual session check functions

The **sessioncheck** package is built on several functions that each
check one specific aspect to the R session: the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function itself merely aggregates the results of individual check
functions. Currently available checks are:

- [`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
- [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
- [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
- [`check_loaded_namespaces()`](https://sessioncheck.djnavarro.net/reference/check_loaded_namespaces.md)
- [`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md)
- [`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md)
- [`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md)
- [`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

All of these functions take an `action` argument, specifying the action
to be taken if the check does not pass. Allowed values for this argument
are `error`, `warn` (the default), `message`, and `none`. However, each
of them has a second argument that can be used to customize the behavior
of the check.

``` r
library(sessioncheck)
```

### Check the global environment

The
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
function performs a session check that is roughly analogous to the one
that is implicitly performed by the traditional method of including
`rm(list=ls())` at the top of the script. It inspects the contents of
the global environment using [`ls()`](https://rdrr.io/r/base/ls.html),
but instead of removing any variables detected in this way, it triggers
a warning in order to prompt the user to take the appropriate action.

At present there are no variables in the global environment that would
be detected by [`ls()`](https://rdrr.io/r/base/ls.html), so the
environment is considered clean and nothing happens when
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md)
is called:

``` r
check_globalenv_objects()
```

If we add variables to the global environment, the warning is triggered:

``` r
visible_1 <- "this will get detected"
visible_2 <- "so will this"
.hidden_1 <- "but this will not"

check_globalenv_objects()
#> Warning: Objects in global environment: visible_1, visible_2
```

The output indicates that the script has detected `visible_1` and
`visible_2` in the global environment, and issues a warning to suggest
that the R session may be contaminated.

The `allow_globalenv_objects` argument is used to customize the behavior
of this check. It takes a character vector as input, and is used as an
“allow list”. Any variable name that is listed in this argument will not
trigger an action. There is a special case:
`allow_globalenv_objects = NULL` will apply the same rule that
[`ls()`](https://rdrr.io/r/base/ls.html) uses when listing the contents
of the global environment: variables that start with a `.` will be
ignored, and will not trigger an action. If the desired behavior is to
detect all variables in the global environment regardless of their name,
set `allow_globalenv_objects = ""`:

``` r
check_globalenv_objects(allow_globalenv_objects = "")
#> Warning: Objects in global environment: .hidden_1, .Random.seed, visible_1,
#> visible_2
```

This time the check detects the `.hidden_1` variable and the
`.Random.seed` variable. To see this in a little more detail, we can
convert the result to a data frame:

``` r
as.data.frame(check_globalenv_objects(action = "none"))
#>        type       entity status
#> 1 globalenv    .hidden_1  FALSE
#> 2 globalenv .Random.seed  FALSE
#> 3 globalenv    visible_1   TRUE
#> 4 globalenv    visible_2   TRUE
```

This coercion is permitted for any of the check functions, and always
returns a data frame with three columns: `type` column specifies the
name of the check that was performed, the `entity` column specifies the
entity that was detected, and `status` is a flag indicating whether that
entity would trigger an action. In the example above, we see that
“hidden” variables are always detected, but by default these have
`status = FALSE` and accordingly will not trigger warnings, errors, or
messages.

### Check the attached packages

The role of
[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
is to inspect the search path to see which packages have been attached:

``` r
check_attached_packages()
#> Warning: Attached packages: sessioncheck
```

The warning notes that in addition to the base R packages (which are
always ignored), the **sessioncheck** package has been attached. To see
this a little more explicitly, we can coerce the output to a data frame:

``` r
as.data.frame(check_attached_packages())
#> Warning: Attached packages: sessioncheck
#>      type       entity status
#> 1 package sessioncheck   TRUE
#> 2 package        stats  FALSE
#> 3 package     graphics  FALSE
#> 4 package    grDevices  FALSE
#> 5 package        utils  FALSE
#> 6 package     datasets  FALSE
#> 7 package      methods  FALSE
#> 8 package         base  FALSE
```

In this output, we can see that there are several base R packages that
have been attached to the search path, but are listed with
`status = FALSE` and therefore do not trigger a warning. However,
because **sessioncheck** itself has been attached via the call to
[`library()`](https://rdrr.io/r/base/library.html) earlier in this
document, it too is detected, and so triggers the warning.

The user can customize which packages should be permitted, using the
`allow_attached_packages` argument. For example, we could choose to
whitelist **sessioncheck**, as illustrated in the example below:

``` r
check_attached_packages(allow_attached_packages = "sessioncheck")
```

Having done so, the warning is no longer triggered.

### Check other attached environments

The
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
function is complementary to
[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md).
Both functions inspect the state of the R search path, but they look for
different things:

- [`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md)
  looks for package environments in the search path, usually added via
  [`library()`](https://rdrr.io/r/base/library.html) or
  [`require()`](https://rdrr.io/r/base/library.html). It ignores
  non-package environments.
- [`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
  looks for non-package environments in the search path, usually added
  via [`attach()`](https://rdrr.io/r/base/attach.html). It ignores
  package environments.

As with the other check functions, when called in a clean R session
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md)
does nothing:

``` r
check_attached_environments()
```

This does not mean that no environments have been detected. Coercing the
result to a data frame shows that various package environments have been
detected (and ignored), the global environment has been detected (and
ignored), and two “special” environments have been detected and ignored:

``` r
as.data.frame(check_attached_environments())
#>          type               entity status
#> 1  attachment           .GlobalEnv  FALSE
#> 2  attachment package:sessioncheck  FALSE
#> 3  attachment        package:stats  FALSE
#> 4  attachment     package:graphics  FALSE
#> 5  attachment    package:grDevices  FALSE
#> 6  attachment        package:utils  FALSE
#> 7  attachment     package:datasets  FALSE
#> 8  attachment      package:methods  FALSE
#> 9  attachment            Autoloads  FALSE
#> 10 attachment          tools:callr  FALSE
#> 11 attachment         package:base  FALSE
```

At present, there are four environments (besides packages and the global
environment) that are whitelisted by default, namely `"tools:rstudio"`,
`"tools:positron"`, `"tools:callr"`, and `"Autoloads"`. If the user
would prefer to have these trigger an action, the
`allowed_attached_environments` argument can be used to manually specify
the names of allowed non-package environments:

``` r
check_attached_environments(allow_attached_environments = "Autoloads")
#> Warning: Attached environments: tools:callr
```

The warning is now triggered because `"Autoloads"` is whitelisted, but
`"tools:callr"` is not.

### Check loaded namespaces

``` r
check_loaded_namespaces()
#> Warning: Loaded namespaces: digest, desc, R6, fastmap, and 19 more
```

To understand this result, it is important to recall that the current
document is rendered using [**pkgdown**](https://pkgdown.r-lib.org/),
with the consequence that **pkgdown** and its dependencies appear as
loaded namespaces even though none of them have been attached to the
search path. To see this in a little more detail, we can coerce the
result to a data frame:

``` r
as.data.frame(check_loaded_namespaces(action = "none"))
#>         type       entity status
#> 1  namespace       digest   TRUE
#> 2  namespace      methods  FALSE
#> 3  namespace         desc   TRUE
#> 4  namespace           R6   TRUE
#> 5  namespace      fastmap   TRUE
#> 6  namespace         xfun   TRUE
#> 7  namespace       cachem   TRUE
#> 8  namespace sessioncheck  FALSE
#> 9  namespace        knitr   TRUE
#> 10 namespace    htmltools   TRUE
#> 11 namespace    rmarkdown   TRUE
#> 12 namespace    lifecycle   TRUE
#> 13 namespace        utils  FALSE
#> 14 namespace          cli   TRUE
#> 15 namespace         sass   TRUE
#> 16 namespace      pkgdown   TRUE
#> 17 namespace     graphics  FALSE
#> 18 namespace  textshaping   TRUE
#> 19 namespace    jquerylib   TRUE
#> 20 namespace    grDevices  FALSE
#> 21 namespace  systemfonts   TRUE
#> 22 namespace        stats  FALSE
#> 23 namespace     compiler  FALSE
#> 24 namespace         base  FALSE
#> 25 namespace        tools  FALSE
#> 26 namespace         ragg   TRUE
#> 27 namespace        bslib   TRUE
#> 28 namespace     evaluate   TRUE
#> 29 namespace         yaml   TRUE
#> 30 namespace     jsonlite   TRUE
#> 31 namespace        rlang   TRUE
#> 32 namespace           fs   TRUE
#> 33 namespace     datasets  FALSE
```

Notice that namespaces associated with base R are listed (e.g.,
`"base"`, “`stats`”, etc) but always have `status = FALSE`: these
namespaces will never trigger a warning/error/message. Similarly the
`"sessioncheck"` namespace never triggers an action, since the namespace
must be loaded in order for the package to be used. All other packages
that are involved in rendering this document are listed with
`status = TRUE`.

To permit those namespaces to be loaded without triggering an action,
use the `allow_loaded_namespaces` argument:

``` r
check_loaded_namespaces(
  allow_loaded_namespaces = c(
    "digest", "desc", "R6", "fastmap", "xfun", "cachem",
    "knitr", "htmltools", "rmarkdown", "lifecycle", "cli",
    "sass", "pkgdown", "textshaping", "jquerylib", 
    "systemfonts", "ragg", "bslib", "evaluate", "yaml",
    "jsonlite", "rlang", "fs", "htmlwidgets"
  )
)
```

Having whitelisted these namespaces, the check now passes and the
warning is no longer triggered.

### Check session runtime

Another heuristic that can sometimes be useful when checking the R
session is to examine how long the current R session has been running. A
long-running R session does not mean anything in and of itself (the
session does not magically become contaminated if it sits idle for a
long time), but in everyday workflow the session runtime can be an
indicator that previous actions have taken place in the R session, and
in some circumstances it may be useful check this.

``` r
check_sessiontime()
```

The behavior of this check can be customized using the `max_sessiontime`
argument, which specifies the maximum length of time (in seconds) that
the R session can be running before an action is triggered. If no value
is supplied, it defaults to 300 seconds. The customization is
illustrated below:

``` r
check_sessiontime(max_sessiontime = .0001)
#> Warning: Session runtime: 1.732 sec elapsed
```

Note that this check is not one of the default checks performed by the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function.

### Other checks

There are three other check functions supplied by **sessioncheck**,
which can be used to examine the session options, the locale settings,
and the system environment variables. However, all three of these are
somewhat limited in their capabilities. They can be used as a way to
require a specific value for an option, a locale setting, or an
environment variable, and not much else. By default, all three of these
checks do nothing: the user must manually specify the precise check that
should be performed.

``` r
check_required_options()
check_required_locale()
check_required_sysenv()
```

Please see the documentation for the individual functions for
information on how these checks work.
