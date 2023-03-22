#!/bin/bash
args = commandArgs(trailingOnly=TRUE)

options(Ncpus = args[1])
### Utilities for R Jupyter Kernel
install.packages(c("base64enc","evaluate","IRdisplay","jsonlite","uuid","digest"), repos="http://cran.us.r-project.org", dependencies=TRUE)
### Install R Jupyter Kernel
install.packages(c("repr", "IRdisplay", "crayon", "pbdZMQ", "devtools"),repos="http://cran.us.r-project.org", dependencies=TRUE)
devtools::install_github("IRkernel/IRkernel")
### Install R kernel
IRkernel::installspec(user = FALSE, name = "ir405", displayname = "R 4.0.5")