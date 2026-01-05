# Why is it important to check the R session?

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

This is by no means an exhaustive list, but it’s enough to illustrate
the many different factors that can can affect how your script executes:
`rm(list = ls())` does not protect you against any of them. Jenny Bryan
provides a good discussion of the [problems with the “object nuking”
approach](https://www.tidyverse.org/blog/2017/12/workflow-vs-script/) on
the tidyverse blog.

Because of this, a better practice is to **restart the R session**
immediately before running the script. By running the script in a fresh
R session, you’re much less likely to encounter these issues.

## How does sessioncheck help?

The principle that underpins **sessioncheck** is that scripts should not
attempt a “clean up” of the environment. The “state” of an R session is
complicated, and so if your script detects evidence that the
pre-existing R state isn’t “clean”, the thing it should do is produce an
error – it is the users responsibility to ensure a clean session. The
script itself doesn’t have the power to make that happen, and it
shouldn’t try.

If you accept this as the core principle, then the thing you want to do
– within that little snippet of code you insert at the top of the script
– is to have your script look at the state of the R session, and look
for signs that it isn’t being run in a clean environment. If it detects
any such signs, it should warn the user, or (in cases where strict
controls are required) produce an error that prevents the rest of the
script from running. The purpose of **sessioncheck** is to provide tools
that can do this. They are – necessarily! – based on heuristic rules
that scan the session for signs that there might be an issue, so it will
not be perfect. But at a bare minimum it can be guaranteed that this
approach is strictly superior to using `rm(list = ls())`.

The core idea is very simple. In the typical case, you wouldn’t load the
package with [`library()`](https://rdrr.io/r/base/library.html).
Instead, you would put this as the very line of their R script:

``` r
sessioncheck::sessioncheck("error")
```

When executed in a clean R session this function does nothing, and the
script continues to run as it normally would. However, if the session is
“contaminated” – for some specific interpretation of what that means to
call the session “contaminated” – it will produce an error, prevent the
script from running, and prompt the user to consider restarting the R
session.

To illustrate what happens in a contaminated R session, I’ll do two
things that most R users would agree fit the definition of a
contaminated R environment: creating objects in the global environment
and attaching packages or environments:

``` r
library(sessioncheck)                     # trigger check_packages
my_data = data.frame(T = FALSE, F = TRUE) # trigger check_globalenv
attach(my_data)                           # trigger check_attachments
#> The following objects are masked from package:base:
#> 
#>     F, T
```

These prior actions vary considerably in their riskiness. For the
example above, here’s a quick risk assessment

- **Attaching packages**. Yes, it’s possible that attaching the
  **sessioncheck** package with
  [`library()`](https://rdrr.io/r/base/library.html) might cause
  problems, but I’ve tried to design it safely so it likely won’t be a
  problem. Nevertheless, it is still something where the script should
  notify the user. By design, the typical use case for this package is
  to call
  [`sessioncheck::sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md).
  In the normal course of events you wouldn’t be writing
  [`library(sessioncheck)`](https://github.com/djnavarro/sessioncheck)
  in your script, so yes, the user should probably be informed, as an
  act of politeness.

- **Adding to the global environment**. Adding the `my_data` data frame
  as a variable in the global environment is not in itself a bad thing,
  but in practice when you’re running the same script over and over in
  an interactive context – which is a thing that data analysts have to
  do a lot, much more so than software engineers – you can quickly build
  up a lot of “detritus”, bits and pieces and objects left behind from
  code you tried out previously, and over time it becomes a big problem.
  The user should definitely be informed, because there are serious risk
  shere.

- **Attaching a (malicious!) environment to the search path**. Attaching
  data sets using [`attach()`](https://rdrr.io/r/base/attach.html) has
  been considered an extremely high-risk behaviour in R for a long time.
  It creates chaos in the R session and the potential for horrific
  outcomes is very high. The example I construced above is deliberately
  malicious, just to highlight how bad it can be. If your script
  executes in an environment when `attach(my_data)` has previously been
  executed, you can no longer rely on R to make sensible judgements
  about arithmetic:

  ``` r
  (2 + 2 == 5) == T
  #> [1] TRUE
  ```

  On the face of it, R now believes that `2 + 2 = 5`. It doesn’t
  actually believe this. The result happens because the prior call to
  [`attach()`](https://rdrr.io/r/base/attach.html) ensures that you can
  no longer rely on the shorthand that assumes `T == TRUE`. Indeed:

  ``` r
  T == TRUE
  #> [1] FALSE
  ```

  and in fact:

  ``` r
  T
  #> [1] FALSE
  ```

  In an ideal world an R script should never be using `T` as a shorthand
  for `TRUE` because it exposes the code to exactly this problem, but
  unfortunately there is a *massive* amount of old R code in current use
  that relies on the shortcut. The risk is real.

Noting that the R session is now contaminated in three ways, we can see
what happens when
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is called in a contaminated environment:

``` r
sessioncheck::sessioncheck("error")
#> Error:
#> ! Session check results:
#> - Objects in global environment: my_data
#> - Attached packages: sessioncheck
#> - Attached environments: my_data
```

If this code were placed at the top of the user script, that script
would simply refuse to run in this contaminated environment. It would
produce an error that indicates which checks were performed, and lists
specific issues that were detected in each test. Not only that, because
this is an error (rather than a warning) it supplies a prompt to the
user that it may be necessary to restart R.

By way of comparison, consider what would happen if the traditional
`rm(list=ls())` approach were employed. Executing this code will fix
only one of the three problems:

``` r
rm(list = ls())
```

The global environment is now clean, but any code that relies on `T` to
mean `TRUE` will now break, because the
[`rm()`](https://rdrr.io/r/base/rm.html) command has *not* detached the
malicious environment:

``` r
T
#> [1] FALSE
```

Even though `rm(list = ls())` has been invoked, the R session is not
safe, and it will corrupt the behaviour of any script that executes in
this session. Importantly, notice that because
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
is stricter than the [`rm()`](https://rdrr.io/r/base/rm.html) approach,
it still produces an error:

``` r
sessioncheck::sessioncheck("error")
#> Error:
#> ! Session check results:
#> - Objects in global environment: [no issues]
#> - Attached packages: sessioncheck
#> - Attached environments: my_data
```

Under normal circumstances the thing that the user – a human being –
would likely do next is restart the R session, and all of these problems
would go away. That is the intended way to use **sessioncheck**. It is
designed primarily for analysts who design their code in a
human-in-the-loop fashion. It is explicitly *not* recommended for
production code or any other situation where R code is executed without
direct human oversight.

Nevertheless, because the author of this vignette is also the person who
created the contaminated R session, she also knows how to reverse it:

``` r
detach("my_data")
detach("package:sessioncheck")
sessioncheck::sessioncheck("error")
```

In general though, the job of cleaning the session or restarting it
should be reserved for the human analyst. Tools such as **sessioncheck**
should not attempt to do so.
