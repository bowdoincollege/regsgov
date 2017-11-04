# R Client for the U.S. Federal Regulations API #

<!-- [![CRAN Version](http://www.r-pkg.org/badges/version/federalregister)](http://cran.r-project.org/package=federalregister) -->
<!-- ![Downloads](http://cranlogs.r-pkg.org/badges/federalregister) -->

[![Build Status](https://travis-ci.org/stephenhouser/regsgov.svg?branch=master)](https://travis-ci.org/stephenhouser/regsgov)

This package provides access to the API for United States regulations at regulations.gov. The API provides access to all regulations, associated documents, and comments collected. The API returns basic details about each regulation and associated documents and provides the URLs for HTML, PDF, and plan text versions when available.

## Installing the package ##

The package can be installed from GitHub as follows:

```r
if (!require('remotes')) {
    install.packages('remotes')
}
remotes::install_github('stephenhouser/us-regulations')
library('regulations')
```

### Example Code ###

Below are some examples of possible uses of the package.

```r
# Get first 1,000 documents with keyword 'katahdin'
katahdin <- documents(apikey='DEMO_KEY', keywords='katahdin', nresults=1000)
katahdin$totalNumRecords
katahdin$content[[1]]

# Get second 1,000 documents with keyword 'katahdin'
katahdin2 <- documents(apikey='DEMO_KEY', keywords='katahdin', nresults=1000, offset=1000)
```

### Developing

Some notes for how to load while developing, using `devtools`:

```r
if (!require('devtools')) {
    install.packages('devtools')
    library('devtools')
}
devtools::load_all()
devtools::use_testthat()
devtools::test()
devtools::check()
```