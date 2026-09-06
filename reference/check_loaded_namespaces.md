# Check loaded namespaces

Individual session check function that inspects the loaded namespaces.
Session checkers can produce errors, warnings, or messages if requested.

## Usage

``` r
check_loaded_namespaces(action = "warn", allow_loaded_namespaces = NULL)
```

## Arguments

- action:

  Behavior to take if the status is not clean. Possible values are
  "error", "warn", "message", and "none". The default is
  `action = "warn"`.

- allow_loaded_namespaces:

  Character vector containing names of packages that are "allowed", and
  will not trigger an action if loaded via namespace.

## Value

Invisibly returns an object of class `sessioncheck_status`.

## Details

This checker inspects the list of loaded namespaces (packages that have
been loaded but not attached). Regardless of the value of
`allow_loaded_namespaces`, R packages that have "base" priority (e.g.,
**base**, **utils**, and **grDevices**) do not trigger an action, nor
does the **sessioncheck** package itself, since the package namespace
must be loaded in order to call the function.

## See also

[`check_attached_packages()`](https://sessioncheck.djnavarro.net/reference/check_attached_packages.md),
[`check_globalenv_objects()`](https://sessioncheck.djnavarro.net/reference/check_globalenv_objects.md),
[`check_attached_environments()`](https://sessioncheck.djnavarro.net/reference/check_attached_environments.md),
[`check_sessiontime()`](https://sessioncheck.djnavarro.net/reference/check_sessiontime.md),
[`check_required_options()`](https://sessioncheck.djnavarro.net/reference/check_required_options.md),
[`check_required_locale()`](https://sessioncheck.djnavarro.net/reference/check_required_locale.md),
[`check_required_sysenv()`](https://sessioncheck.djnavarro.net/reference/check_required_sysenv.md)

## Examples

``` r
check_loaded_namespaces(action = "message")
#> ✖ Unexpected namespaces: jsonlite, brio, xml2, jquerylib, and 42 more

# a session with no unexpected namespaces loaded: a passing check is
# always silent regardless of `action`, so print() the returned status
# directly to see the "no issues" wording
print(check_loaded_namespaces(action = "none", allow_loaded_namespaces = loadedNamespaces()))
#> ✔ No unexpected namespaces loaded
 
```
