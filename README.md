# R Client for the U.S. Federal Regulations API #

<!-- [![CRAN Version](http://www.r-pkg.org/badges/version/federalregister)](http://cran.r-project.org/package=federalregister) -->
<!-- ![Downloads](http://cranlogs.r-pkg.org/badges/federalregister) -->

[![Build Status](https://travis-ci.org/stephenhouser/regulations.png?branch=master)](https://travis-ci.org/stephenhouser/regulations)

This package provides access to the API for United States regulations at regulations.gov. The API provides access to all regulations, associated documents, and comments collected. The API returns basic details about each regulation and associated documents and provides the URLs for HTML, PDF, and plan text versions when available.

## Installing the package ##

The package can be installed from GitHub:

```r
if (!require('remotes')) {
    install.packages('remotes')
    library('remotes')
}
remotes::install_github('stephenhouser/us-regulations')
library('regulations')
```

### Example Code ###

Below are some examples of possible uses of the package.

```r
remotes::install_github('stephenhouser/us-regulations')
library('regulations')
katahdin <- usreg_documents(apikey='DEMO_KEY', keywords='katahdin', nresults=1000)
katahdin$totalNumRecords
katahdin$content[[1]]

katahdin2 <- usreg_documents(apikey='DEMO_KEY', keywords='katahdin', nresults=1000, offset=1000)
```

### Developing

Some notes for how to load while developing...

```r
if (!require('devtools')) {
    install.packages('devtools')
    library('devtools')
}
load_all()
```