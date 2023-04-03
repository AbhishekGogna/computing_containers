#!/bin/bash
args = commandArgs(trailingOnly=TRUE)

options(Ncpus = args[1])
### Utilities for R Jupyter Kernel
install.packages(c("base64enc","evaluate","jsonlite","uuid","digest"), repos="http://cran.us.r-project.org", dependencies=TRUE, quite = TRUE) # nolint
### Install R Jupyter Kernel
install.packages(c("repr", "IRdisplay", "crayon", "pbdZMQ", "devtools"),repos="http://cran.us.r-project.org", dependencies=TRUE, quite= TRUE)
devtools::install_github("IRkernel/IRkernel")
### Install R kernel
IRkernel::installspec(user = FALSE, name = "ir405", displayname = "R 4.0.5")