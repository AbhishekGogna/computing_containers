#!/bin/bash
args = commandArgs(trailingOnly=TRUE)

options(Ncpus = args[1])
### Install base pkgs
install.packages(c("renv", "rJava"), repos="http://cran.us.r-project.org", dependencies=TRUE, quiet = TRUE)