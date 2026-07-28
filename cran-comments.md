## Summary

Patch release (0.1.1). Changes since 0.1.0:

- Seven bug fixes: argument validation in `sessioncheck()`, silent failures in
  `check_required_options()` / `check_required_locale()` / `check_required_sysenv()`
  with unnamed lists, latent bug in the internal `.action()` helper, unrecognized
  check names silently ignored, misleading test mock, and minor output formatting.
- Documentation corrections: wrong parameter name in `check_attached_packages()`
  help page, self-referential `@seealso` links, broken `@details` in
  `check_loaded_namespaces()`, wrong argument in `check_required_locale()` example.
- Spelling and language fixes: added `Language: en-US` to DESCRIPTION, created
  `inst/WORDLIST`, corrected non-US spellings throughout.

Thank you for your consideration.

Kind regards
Danielle Navarro


## R CMD check results

0 errors | 0 warnings | 0 notes

## Platforms tested

**Local**

- R 4.6.1 on Ubuntu 24.04.4 LTS (x86_64)

**GitHub Actions (R CMD check)**

- R 4.6.1 on macOS Tahoe 26.4 (ARM64)
- R 4.6.1 on Ubuntu 24.04.4 LTS (x86_64)
- R 4.6.1 on Windows Server 2022 (x86_64)
- R 4.5.3 (oldrel-1) on Ubuntu 24.04.4 LTS (x86_64)
- R-devel (r90185) on Ubuntu 24.04.4 LTS (x86_64)

**R-hub**

- R-devel on Ubuntu 24.04.4 LTS (linux)
- R-devel on macOS Tahoe 26.4 (macos-arm64)
- R-devel on Windows Server 2022 (windows)
- R 4.6.1 RC on Ubuntu 24.04.4 LTS (ubuntu-next)
- R-devel on Fedora Linux 42, without suggested packages (nosuggests)
- R-devel on Ubuntu 22.04.5 LTS, with `\donttest{}` examples run (donttest)

**win-builder**

- R-devel (r90304 ucrt) on Windows Server 2022 x64 (build 20348)
