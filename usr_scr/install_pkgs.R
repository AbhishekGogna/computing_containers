#!/bin/bash
args = commandArgs(trailingOnly=TRUE)

options(Ncpus = args[1])
### Utilities for R Jupyter Kernel
<<<<<<< HEAD
install.packages(c("base64enc","evaluate","jsonlite","uuid","digest"), repos="http://cran.us.r-project.org", dependencies=TRUE, quiet = TRUE) # nolint
### Install R Jupyter Kernel
install.packages(c("repr", "IRdisplay", "crayon", "pbdZMQ", "devtools"),repos="http://cran.us.r-project.org", dependencies=TRUE, quiet= TRUE)
=======
install.packages(c("base64enc","evaluate","jsonlite","uuid","digest"), repos="http://cran.us.r-project.org", dependencies = TRUE, quiet = TRUE) # nolint
### Install R Jupyter Kernel
install.packages(c("repr", "IRdisplay", "crayon", "pbdZMQ", "devtools"),repos="http://cran.us.r-project.org", dependencies = TRUE, quiet= TRUE)
>>>>>>> 4d32f349c7fad1ce9aa819f11aa8f9e51eb64759
devtools::install_github("IRkernel/IRkernel")
### Install R kernel
IRkernel::installspec(user = FALSE, name = "ir405", displayname = "R 4.0.5")
