# sessioncheck

The goal of **sessioncheck** is to provide simple tools that can be
called at the top of a script, and produce warnings or errors if it
detects signs that the script is not being executed in a clean R
session. The intended user for **sessioncheck** is a beginner or
intermediate level R user who has learned enough about R to understand
the limitations of using `rm(list = ls())` as a method to clean the R
session, but is perhaps not at the point that they can take advantage of
sophisticated tools like [targets](https://books.ropensci.org/targets/),
[callr](https://callr.r-lib.org/), and so on.

## Why is this important?

A common practice when writing R scripts is to include a snippet of code
like `rm(list = ls())` at the top of the script. The reason people do
this is for reproducibility purposes, to ensure that the script is run
in the context of a “clean” R session. The goal is a good one, but the
method used to attain it is not very effective. The only thing that
`rm(list = ls())` does is remove any variables currently stored in the
global environment, but this is only one of many different ways in which
previously-executed code can alter the state of the R session. This
approach doesn’t provide any degree of safety from any of the following:

- packages that may have been loaded with
  [`library()`](https://rdrr.io/r/base/library.html) and change which
  functions get executed by your code
- data sets or other environments that may have been added to the search
  path with [`attach()`](https://rdrr.io/r/base/attach.html) and alter
  the variables and functions that are visible to your code
- options that may have been set with
  [`options()`](https://rdrr.io/r/base/options.html) and can alter how
  your code is interpreted
- “hidden” variables in the global environment like `.Random.seed` that
  affect R code execution and are ignored by `rm(list = ls())`
- …and many more; there’s a long list of subtler ways in which the R
  session state matters

Any of these can affect how your script executes, and `rm(list = ls())`
does not protect you against any of them. Because of this, a better
practice is to **restart the R session** immediately before running the
script. By running the script in a fresh R session, you’re much less
likely to encounter these issues. By exension, the reason for including
a call to
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
at the top of a script is to **prompt the user** when potential issues
are detected.

For additional background see the article on [why session checking is
useful](https://sessioncheck.djnavarro.net/articles/why-check-the-r-session.html).

## How does sessioncheck work?

The **sessioncheck** package is built on several functions that each
check one specific aspect to the R session: the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function itself merely aggregates the results of the individual checks.

When calling
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
you can customise exactly which checks are performed and what rules
should apply to each check, but for now let’s look at the three specific
checks that are performed by default: checks of the global environment,
checks of the attached packages, and checks of the attached non-package
environments. These can be run as standalone checks using
[`check_globalenv()`](https://sessioncheck.djnavarro.net/reference/object_checks.md),
[`check_packages()`](https://sessioncheck.djnavarro.net/reference/package_checks.md)
and
[`check_attachments()`](https://sessioncheck.djnavarro.net/reference/object_checks.md),
so the natural place to start is examining the behaviour of the
standalone checks.

### Check 1: global environment

The first and simplest of the checks is
[`check_globalenv()`](https://sessioncheck.djnavarro.net/reference/object_checks.md),
and it focuses on the same aspect of the R session that the traditional
`rm(list=ls())` method does: the contents of the global environment. At
the moment there is nothing in the global environment, so it is
considered “clean”. As a consequence, nothing happens when we run this
check:

``` r
sessioncheck::check_globalenv()
```

To get the check to produce a warning, we’ll need to add some variables:

``` r
visible_1 <- "this will get detected"
visible_2 <- "so will this"
.hidden_1 <- "but this will not"

sessioncheck::check_globalenv()
#> Warning: Objects in global environment: visible_1, visible_2
```

The output indicates that the script has detected `visible_1` and
`visible_2` in the global environment, and issues a warning to suggest
that the R session may be contaminated.

There are two arguments to
[`check_globalenv()`](https://sessioncheck.djnavarro.net/reference/object_checks.md):

- `action` specifies what the function should do if an issue is
  detected. There are four allowed values: `error`, `warn` (the
  default), `message`, and `none`.
- `allow` is a character vector used to specify the rules that are used
  to decide *which* objects should trigger an action. A variable name
  that is included in the `allow` list will not trigger an action. There
  is a special case: `allow = NULL` will apply the same rule that
  [`ls()`](https://rdrr.io/r/base/ls.html) uses when listing the
  contents of the global environment: variables that start with a `.`
  will be ignored, and will not trigger an action.

The example below illustrates how both of these actions are used. Here,
the action taken will be to print a message rather than a warning; and
by setting the `allow` argument to an empty string, *any* variable in
the global environment will trigger the message, even the “hidden” ones:

``` r
sessioncheck::check_globalenv(action = "message", allow = "")
#> Objects in global environment: .hidden_1, .Random.seed, visible_1, visible_2
```

This time we notice that the check detects the `visible_1` and
`visible_2` like last time, but it now detects two hidden variables: the
`.hidden_1` variable that I created earlier, and also the `.Random.seed`
variable that R uses to store the state of the random number generator.

### Check 2: attached packages

``` r
sessioncheck::check_packages()
```

The warning notes that the **sessioncheck** package has been attached.
This might be considered acceptable, so we can ask the check to `allow`
this package:

``` r
sessioncheck::check_packages(action = "warn", allow = "sessioncheck")
```

### Check 3: other attachments

``` r
sessioncheck::check_attachments()
```

### Other checks

There are other checks that are not called by default. One is an “allow
list” check, where the user must specify exactly which entities are
permitted (i.e. the list of things that *don’t* trigger an action):

- [`check_namespaces()`](https://sessioncheck.djnavarro.net/reference/package_checks.md)
  looks for packages that have been loaded but not attached

The others are “block list” checks, where the user specifies which cases
are to be blocked (i.e., the list of things that *do* trigger an action)

- TODO:
  [`check_options()`](https://sessioncheck.djnavarro.net/reference/value_checks.md)
  looks for specific options that might be of concern
- TODO:
  [`check_sysenv()`](https://sessioncheck.djnavarro.net/reference/value_checks.md)
  looks for system environment variables
