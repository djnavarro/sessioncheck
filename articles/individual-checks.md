# Individual session check functions

The **sessioncheck** package is built on several functions that each
check one specific aspect to the R session: the
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md)
function itself merely aggregates the results of individual check
functions like `check_globalenv()`, `check_packages()` and
`check_attachments()`. In a typical workflow the user would be unlikely
to use these directly, relying instead on the high-level interface
provided by
[`sessioncheck()`](https://sessioncheck.djnavarro.net/reference/sessioncheck.md).
Nevertheless, it’s useful to look at what each one does in a little more
detail.

### Check the global environment

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

### Check the attached packages

``` r
sessioncheck::check_attached_packages()
```

The warning notes that the **sessioncheck** package has been attached.
This might be considered acceptable, so we can ask the check to `allow`
this package:

``` r
sessioncheck::check_attached_packages(action = "warn", allow_attached_packages = "sessioncheck")
```

### Check other attached environments

``` r
sessioncheck::check_attached_environments()
```

### Check loaded namespaces

``` r
sessioncheck::check_loaded_namespaces()
#> Warning: Loaded namespaces: digest, desc, R6, fastmap, and 19 more
```

### Check session runtime

``` r
sessioncheck::check_sessiontime()
```

### Check required options

``` r
sessioncheck::check_required_options()
```

### Check required locale

``` r
sessioncheck::check_required_locale()
```

### Check required environment variables

``` r
sessioncheck::check_required_sysenv()
```
