# make a project in rstudio with name eg KIBREED_gen_3
project_dir <- "/proj" # if you have a different path to the project directory. Change the string

# initialize dependency management with renv
renv::init(project = project_dir, bare = TRUE,
           settings = list(use.cache = FALSE,
                           external.libraries = c("/proj/rst/R/x86_64-pc-linux-gnu-library/4.0", 
                                                  "/usr/local/lib/R/library")),
           force = TRUE)

# Modify rprofile 
cat('if(getwd() == "/proj") source("renv/activate.R")\n', 
    file = sprintf("%s/%s", project_dir, ".Rprofile"))

# Packages ----------------------------------------------------------------
packs <- c("remotes", # for version specific install
           "tidyverse:1.3.2", "hablar", "qs")

## remotes is the key package
if(!sapply("remotes", require, character.only = TRUE)){
  install.packages("remotes")
}

## extract packs info and install them
pack_list <- strsplit(packs, ":")
pack_names <- do.call(c, lapply(pack_list, function(x) x[[1]]))
pack_versions <- do.call(c, lapply(pack_list, function(x) {
  if(!is.na(x[2])) {
    out <- x[2]
  } else {
    out <- "NULL"
  }
  return(out)
}))
names(pack_versions) <- pack_names
success <- suppressWarnings(sapply(pack_names, require, character.only = TRUE))
for(pack in names(success[which(success == FALSE)])){
  vrn = pack_versions[pack]
  if (vrn == "NULL") {vrn <- NULL}
  remotes::install_version(pack, version = vrn,  Ncpus = 30) # modify available cpu's if you have low computing power
}

# to install asreml you need to put the tar file ar /proj/renv/cellar formatted as asreml_version.tar.gz
cellar_at <- sprintf("%s/renv/cellar", project_dir) # make a cellar for user defined packages
asreml_tar_name <-grep("asreml", list.files("/proj/renv/cellar/"), value = TRUE)[1]
if(identical(asreml_tar_name, character(0))){
  print("Asreml tar file not found. Please check.")
} else {
  install.packages(sprintf("%s/%s", cellar_at, asreml_tar_name), repos = NULL, type = "source")
}

#multtest # use source code from bioconductor

# OpenBLAS ----------------------------------------------------------------
# You need to install OpenBLAS on a host from within the container. 
# To do this start shell in the rserver and execute the following
#git clone -b v0.3.18 https://github.com/xianyi/OpenBLAS
#cd OpenBLAS
#make
#make install PREFIX="inst/$(hostname)"
# now use 
#sessionInfo()
# to get the default location of the BLAS library in R. Then go outside and bind 
# the absolute path of installed blas library to the path given by sessionInfo.
# eg "${OpenBLAS_lib}:/usr/local/lib/R/lib/libRblas.so" where 
# OpenBLAS_lib="/qg-10/data/AGR-QG/Gogna/computing_containers/OpenBLAS/inst/qg-10.ipk-gatersleben.de/lib/libopenblas.so"
# you can benchmark OpenBLAS with https://mac.r-project.org/benchmarks/R-benchmark-25.R # With OpenBLAS was completed in 8 secs on qg-10