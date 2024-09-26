# Check if renv/activate.R exists and source it
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
}

# Set CRAN mirror to use HTTP instead of HTTPS
options(repos=c(CRAN="http://ftp.osuosl.org/pub/cran/",
                RSPM="http://p3m.dev/cran/"))

# Force R to use HTTP for downloads
Sys.setenv("CURL_SSL_BACKEND" = "none")  # This will disable SSL, forcing HTTP

# Force devtools or remotes package installations to use HTTP
options(download.file.method = "libcurl")


Sys.setenv(RENV_CONFIG_REPOS_RSPM = "http://packagemanager.rstudio.com/cran/latest")
Sys.setenv(RENV_DOWNLOAD_METHOD = "curl")
Sys.setenv(RENV_DOWNLOAD_FILE_METHOD = "curl")
Sys.setenv(CURL_SSL_NO_VERIFY = "1")
