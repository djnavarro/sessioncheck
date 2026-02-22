## Summary

This is a new package designed to allow users to easily detect signs that an R script is not being executed in a clean session. The intent is to be a drop-in replacement for the common practice of using `rm(list=ls())` at the top of the script, allowing users to make informed choices about whether to restart the R session.

Tests run on github, Rhub, and win-builder generally did not produce errors or warnings, and only the new release note. The one case where Rhub failures appeared is noted below, and is innocuous as far as I can tell. 

Thank you for your consideration.

Kind regards
Danielle Navarro


## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Rhub platforms tested

Checked on all 31 platforms currently available via Rhub. Passes on 30 with no warnings or errors:

https://github.com/djnavarro/sessioncheck/actions/runs/22267933955

 [1] "linux"          "m1-san"         "macos"          "macos-arm64"   
 [5] "windows"        "atlas"          "c23"            "clang-asan"    
 [9] "clang-ubsan"    "clang16"        "clang17"        "clang18"       
[13] "clang19"        "clang20"        "donttest"       "gcc-asan"      
[17] "gcc13"          "gcc14"          "gcc15"          "intel"         
[21] "lto"            "mkl"            "nold"           "noremap"       
[25] "nosuggests"     "rchk"           "ubuntu-clang"   "ubuntu-gcc12"  
[29] "ubuntu-next"    "ubuntu-release" "valgrind" 

The one failure is "rchk", and as far as I can tell it is innocuous:

https://github.com/djnavarro/sessioncheck/actions/runs/22267933955/job/64417470871

## Win-builder platforms tested

R-release: https://win-builder.r-project.org/66J95sB0M5d3/

R CMD check logs look okay. The R-devel win-builder did not send an email after three attempts, but as the R-devel checks passed on GitHub I am reasonably confident in this.


