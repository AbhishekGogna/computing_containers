#!/bin/bash
args = commandArgs(trailingOnly=TRUE)

options(Ncpus = args[1])
### Install base pkgs
<<<<<<< HEAD
install.packages(c("renv", "rJava"), repos="http://cran.us.r-project.org", dependencies=TRUE, quiet = TRUE)
=======
install.packages("renv", repos="http://cran.us.r-project.org", dependencies = TRUE, quiet = TRUE)
>>>>>>> 4d32f349c7fad1ce9aa819f11aa8f9e51eb64759
