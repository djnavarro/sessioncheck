## Submission

This is a minor release, updating sessioncheck from 0.1.1 to 0.2.0. It adds
new functions (`sessionstate()`, `compare_sessionstates()`,
`check_working_directory()`), an `action_on_pass` argument across the
existing `check_*()` functions, and a bug fix -- see NEWS.md for details.

## Test environments

* local Linux (Ubuntu 24.04.4 LTS), R 4.6.1
* GitHub Actions CI (`R-CMD-check.yaml`), run on every push/PR:
  * macOS (latest), R release
  * Windows (latest), R release
  * Ubuntu (latest), R devel
  * Ubuntu (latest), R release
  * Ubuntu (latest), R oldrel-1
* R-hub v2, selected platforms chosen for diversity of OS/toolchain/dependency
  configuration not already covered above (sessioncheck contains no compiled
  code, so sanitizer/valgrind/compiler-focused R-hub platforms were skipped;
  the macOS R-hub platform was also skipped, as it has been unreliable
  recently -- macOS coverage instead comes from CI's Apple-silicon runner,
  and CRAN performs its own macOS build/check as part of the submission
  process):
  * `ubuntu-clang` -- R devel on Debian with clang (CI only covers Ubuntu
    with gcc)
  * `nosuggests` -- R devel on Fedora with Suggests packages unavailable
* win-builder
  * R-devel
  * R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

## revdepcheck results

There are currently no reverse dependencies for this package.
