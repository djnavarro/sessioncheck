# sessioncheck

The goal of **sessioncheck** is to provide simple tools that can be
called at the top of a script, and produce warnings or errors if it
detects signs that the script is not being executed in a clean R
session. The intended user for **sessioncheck** is a beginner or
intermediate level R user who wants to take reasonable precautions to
ensure that their analysis scripts execute reproducibly, but is not
looking for a full-featured solution that might require substantial time
investment to learn and deploy.

## Who is this for, and why?

A common practice when writing R scripts is to include a snippet of code
like `rm(list = ls())` at the top of the script. The reason people do
this is for reproducibility purposes, to ensure that the script is run
in the context of a “clean” R session. Unfortunately, while the goal is
a good one the solution is not. The problem with this approach is that
the only thing it does is remove objects from the global environment. If
your goal is to ensure that the R session is clean, this isn’t
sufficient. The reason it’s not enough is that the state of an R session
is defined by a *lot* of different things, and the objects in the global
environment form a very small part of that state. Yes, using
[`rm()`](https://rdrr.io/r/base/rm.html) to clear the global environment
will “clean” this specific aspect to the R session state, but it has no
effect on any of the other things. What’s worse, the
[`rm()`](https://rdrr.io/r/base/rm.html) approach can create false
confidence: if users rely on [`rm()`](https://rdrr.io/r/base/rm.html) as
an “automated” method for cleaning the session state, they may end up
executing scripts in a profoundly irreproducible way, never noticing
that something bad has happened. This is, to put it mildly, not ideal.

One of the reasons this problem is painful in real life is that it
requires a certain level of sophistication to force a script to execute
in a precisely controlled environment. There are some very powerful
tools pitched at the expert user – e.g., docker, targets, and renv –
that you can use to execute scripts in a reproducible way. There are not
as many options for beginners or intermediate level R users.

Because of this, a better practice is to **restart the R session**
immediately before running the script. By running the script in a fresh
R session, you’re much less likely to encounter these issues. By
exension, the reason for including a call to
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
`check_globalenv()`, `check_packages()` and `check_attachments()`, so
the natural place to start is examining the behaviour of the standalone
checks.

### Check 1: global environment

The first and simplest of the checks is
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
and it focuses on the same aspect of the R session that the traditional
`rm(list=ls())` method does: the contents of the global environment. At
the moment there is nothing in the global environment, so it is
considered “clean”. As a consequence, nothing happens when we run this
check:

``` r
sessioncheck::check_globalenv_objects()
```

To get the check to produce a warning, we’ll need to add some variables:

``` r
visible_1 <- "this will get detected"
visible_2 <- "so will this"
.hidden_1 <- "but this will not"

sessioncheck::check_globalenv_objects()
#> Warning: Objects in global environment: visible_1, visible_2
```

The output indicates that the script has detected `visible_1` and
`visible_2` in the global environment, and issues a warning to suggest
that the R session may be contaminated.

There are two arguments to
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md):

- `action` specifies what the function should do if an issue is
  detected. There are four allowed values: `error`, `warn` (the
  default), `message`, and `none`.
- `allow_globalenv_objects` is a character vector used to specify the
  rules that are used to decide *which* objects should trigger an
  action. A variable name that is included in the `allow` list will not
  trigger an action. There is a special case:
  `allow_globalenv_objects = NULL` will apply the same rule that
  [`ls()`](https://rdrr.io/r/base/ls.html) uses when listing the
  contents of the global environment: variables that start with a `.`
  will be ignored, and will not trigger an action.

The example below illustrates how both of these actions are used. Here,
the action taken will be to print a message rather than a warning; and
by setting the `allow_globalenv_objects` argument to an empty string,
*any* variable in the global environment will trigger the message, even
the “hidden” ones:

``` r
sessioncheck::check_globalenv_objects(action = "message", allow_globalenv_objects = "")
#> Objects in global environment: .hidden_1, .Random.seed, visible_1, visible_2
```

This time we notice that the check detects the `visible_1` and
`visible_2` like last time, but it now detects two hidden variables: the
`.hidden_1` variable that I created earlier, and also the `.Random.seed`
variable that R uses to store the state of the random number generator.

### Check 2: attached packages

``` r
sessioncheck::check_attached_packages()
```

The warning notes that the **sessioncheck** package has been attached.
This might be considered acceptable, so we can ask the check to `allow`
this package:

``` r
sessioncheck::check_attached_packages(action = "warn", allow_attached_packages = "sessioncheck")
```

### Check 3: other attachments

``` r
sessioncheck::check_attached_environments()
```
