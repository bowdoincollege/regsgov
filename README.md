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
remotes::install_github('stephenhouser/regsgov')
library(regulations)
```

### Example Code ###

Below are some examples of possible uses of the package.

Simple use to search regulations.gov for documents with the keyword `katahdin` in them.

```r
katahdin <- documents(apikey='DEMO_KEY', keywords='katahdin')
katahdin$totalNumRecords
katahdin$content[[1]]
```

Find documents related to a specific docketID. In this case we are looking
for the comments on a particular regulation. As the API is limited to 1,000
documents per request, we loop through the results and collect the results
into a single data.frame. This example does not fetch all ~780,000 but could
easily be adapted to do so.

```r
# Create a data frame to hold the collected results
comments <- data.frame(NULL)

# Start at first (`start_offset`) and accumulate `end_offset` documents
start_offset <- 0
end_offset   <- 100
# fetch `nresults` documents at a time... 
nresults     <- 10

# Loop through and accumulate documents into `comments` data.frame
offset <- start_offset
while (offset < end_offset) {
    # Fetch the next chunk
    temp <- documents(apikey='DEMO_KEY', docketID = 'DOI-2017-0002', 
                        offset = offset, nresults = nresults)
    print(paste(offset, "to", offset+nresults, "of", temp$totalNumRecords, "documents"))
    # Add result to collected results
    comments <- rbind(comments, temp$content)
    # Advance to next offset
    offset <- offset + nresults
}

# Display some of the data
head(comments$commentText)
```

### API Key ###

To do more than a few small queries you will need to request an `API Key` to replace the `DEMO_KEY` shown above. The process is simple and quick using the [API Key Requetst](http://regulationsgov.github.io/developers/key/) form on the [regulations.gov](regulations.gov) site. Your unique individual key will be emailed to you. Replace `DEMO_KEY` in the examples above with your key.

### Developing ###

Some notes for how to load while developing, using `devtools`:

```r
if (!require('devtools')) {
    install.packages('devtools')
}
devtools::load_all()
devtools::use_testthat()
devtools::test()
devtools::check()
```
