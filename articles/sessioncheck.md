# Introduction to sessioncheck

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

Because of this, a better practice is to **restart the R session**
immediately before running the script. By running the script in a fresh
R session, you’re much less likely to encounter these issues. By
extension, the reason for including a call to
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
at the top of a script is not to try to clean the R session (which is
very hard to automate). Instead, what it does is **prompt the user** to
take appropriate action if potential issues are detected. For additional
background, see the article on [why session checking is
useful](https://sessioncheck.djnavarro.net/articles/why-check-the-r-session.html).

## What does sessioncheck do?

The main function in **sessioncheck** is
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md),
which examines the state of the R session and informs the user if
potential issues are detected. The behaviour of
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is
[customisable](https://sessioncheck.djnavarro.net/articles/customizing-sessioncheck.html),
allowing the user to make decisions about what criteria should be used
to decide if an R session is “dirty”.

For the purposes of this article we will stick to the default checks.
The simplest of these examines the contents of the global environment,
very much in line with the “traditional” method of inserting
`rm(list=ls())` into the top of a script. At the moment there is nothing
in the global environment, so it is considered “clean”. When
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is called in a clean state, no message is printed:

``` r
sessioncheck::sessioncheck()
```

By default,
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
adheres to the R convention that variables starting with a period are
hidden variables, and so does not report any issues if the session
contains a variable like `.Random.seed` or `.Last.value`. This can be
customised, but for the purposes of this article we’ll just look at the
default behaviour:

``` r
visible_1 <- "this will get detected"
visible_2 <- "so will this"
.hidden_1 <- "but this will not"

sessioncheck::sessioncheck()
#> Warning: Session check results:
#> - Objects in global environment: visible_1, visible_2
#> - Attached packages: [no issues]
#> - Attached environments: [no issues]
```

The first line of this output indicates that the script has detected
`visible_1` and `visible_2` in the global environment, and issues a
warning to suggest that the R session may be contaminated. This can be
escalated to an error if so desired:

``` r
sessioncheck::sessioncheck(action = "error")
#> Error:
#> ! Session check results:
#> - Objects in global environment: visible_1, visible_2
#> - Attached packages: [no issues]
#> - Attached environments: [no issues]
```

Notice that there are two additional lines of output in the session
check message. By default,
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
reports the results of three checks. The first is the global environment
check discussed above. The second checks for packages that have been
attached to the search path, usually via
[`library()`](https://rdrr.io/r/base/library.html) or
[`require()`](https://rdrr.io/r/base/library.html). The third checks for
other environments that have may have been attached, perhaps by
inadvertently calling the
[`attach()`](https://rdrr.io/r/base/attach.html) function. This is
illustrated in the following example

``` r
require(knitr) # non-base packages are detected
#> Loading required package: knitr
require(stats) # base R packages are ignored
attach(iris)   # attached data frames are detected

sessioncheck::sessioncheck()
#> Warning: Session check results:
#> - Objects in global environment: visible_1, visible_2
#> - Attached packages: knitr
#> - Attached environments: iris
```

## Further reading

- [Why session checking is
  useful](https://sessioncheck.djnavarro.net/articles/why-check-the-r-session.html)
- [Customizing
  sessioncheck()](https://sessioncheck.djnavarro.net/articles/customizing-sessioncheck.html)
- [Individual check
  functions](https://sessioncheck.djnavarro.net/articles/individual-checks.html)
