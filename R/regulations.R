# reg_documents.R
# Stephen Houser
# 10/19/2017

# Original Mark Hagemann
# 1/19/2016
# Following https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html
# Also hijacks code from rnoaa package.

library('dplyr')
library('httr')
library('assertthat')
library('jsonlite')

regulationsApi <- "https://api.data.gov/regulations/v3/documents.json"
# For some reason doing it this way causes a need for xml2 package...
#documentsApiURL = modify_url(regulationsApi, path = "/documents.json")
documentsApiURL <- regulationsApi

ua <- user_agent("http://github.com/bowdoincollege/regsgov")
ua
#> <request>
#> Options:
#> * useragent: http://github.com/bowdoincollege/regsgov

.compact <- function(l) {
  out <- Filter(Negate(is.null), l)
  out
}

.nullToNA = function(df) {
  df[sapply(df, is.null)] = NA
  df
}

#' @importFrom assertthat assert_that
.datestring <- function(date1, date2) {
	null1 <- is.null(date1)
	null2 <- is.null(date2)
  	if (null1 && null2) {
    	return(NULL)
	} else if (null1) {
    	return(format(as.Date(date2), "%m/%d/%y"))
	} else if (null2) {
    	return (format(as.Date(date1), "%m/%d/%y"))
	} else {
    	assertthat::assert_that(as.Date(date1) < as.Date(date2))
    	return(paste(format(as.Date(date1), "%m/%d/%y"),
                     format(as.Date(date2), "%m/%d/%y"), sep = "-"))
  	}
}

#' Parse (and return) JSON data out of HTTP Response
#' @importFrom httr content warn_for_status
.parseResponse <- function(response) {
  if (!response$status_code == 200) {
    stnames <- names(httr::content(response))
    if (!is.null(stnames)) {
      if ("developerMessage" %in% stnames | "message" %in% stnames) {
        warning(sprintf("Error: (%s) - %s", response$status_code,
                        .compact(list(httr::content(response)$developerMessage,
                                      httr::content(response)$message))))
      } else {
        warning(sprintf("Error: (%s)", response$status_code))
      }
    } else {
      httr::warn_for_status(response)
    }
  } else {
    stopifnot(response$headers$`content-type` == "application/json")
    res <- httr::content(response, as = "text", encoding = "UTF-8")
    out <- jsonlite::fromJSON(res, simplifyVector = FALSE)
    if (!"results" %in% names(out)) {
      if (length(out) == 0) {
        warning("Sorry, no data found")
      }
    } else {
      if (class(try(out$results, silent = TRUE)) == "try-error" |
          is.null(try(out$results, silent = TRUE)))
        warning("Sorry, no data found")
    }

    return(out)
  }
}

#' Verify or find regulations.gov API key in environment
#' @param apikey Access key for accessing the regulations.gov API.
#' Get one at https://regulationsgov.github.io/developers/key/.
.apikey <- function(apikey) {
	tmpkey <- if (is.null(apikey)) {
		Sys.getenv("REGULATIONS_APIKEY", "")
	} else {
		apikey
	}

	if (identical(tmpkey, "")) {
		getOption("REGULATIONS_APIKEY", stop("need an API key for regulations.gov data"))
	} else {
		tmpkey
	}
}

#' Set regulations.gov rate limiting number
#' @return number of documents to return on each call
.ratelimit <- function() {
	1000
}

#' Retrieve regulations.gov documents
#' @param apikey Access key for accessing the regulations.gov API.
#' Get one at https://regulationsgov.github.io/developers/key/.
#' @param countsOnly 1 (will return only the document count for a search query) 0 (will return documents as well)
#' @param encoded 1 (will accept Regulations.gov style encoded parameters) 0 (will not accept such encoded parameters)
#' @param keywords Keywords associated with the document
#' @param docType Document Type: N: Notice; PR: Proposed Rule; FR: Rule;
#' O: Other; SR: Supporting & Related Material; PS: Public Submission
#' @param docketID Valid Docket ID (ex. SEC-2012-0044)
#' @param docketType "Docket Type: R: Rulemaking; N: Nonrulemaking
#' @param commentPeriod Comment Period: O: Open; C: Closed
#' @param agency Federal Agency: List of accepted Federal Agency values. This field allows multiple values. ex: c(FMCSA, EPA, FDA)
#' @param nresults Results Per Page 10, 25, 100, 500, 1000.  Results per page may not exceed 1000.
#' @param offset Page offset (always starts with 0). This is used in
#' conjunction with results per page to provide large data sets. For example,
#' if a search produces 82 results and the result per page is set to 25, this
#' will generate 4 pages. 3 pages will have 25 results and the last page will
#' have 7 results. Page offset values for each page will be: Page 1: po=0
#' Page 2: po=25 Page 3: po=50 Page 4: po=75. The total number of pages
#' is [total results/results per page] and page offset for page X is
#' [X-1 * results per page]"
#' @param closingSoon Comment Period Closing Soon: 0 (closing today);
#' 3 (closing within 3 days); 15 (closing within 15 days);
#' 30 (closing within 30 days); 90 (closing within 90 days)"
#' @param newlyPosted Newly Posted: 0 (posted today);
#' 3 (posted within last 3 days); 15 (posted within last 15 days);
#' 30 (posted within last 30 days); 90 (posted within last 90 days).
#' For periods of time beyond 90-days, please use a date range with the Posted
#' Date parameter.
#' @param comStartDate Comment Period Start Date
#' @param comEndDate Comment Period End Date. Comment Period Start and
#' End Dates are mutually exclusive with the 'closing soon' parameter.
#' If both are provided, 'closing soon' will be ignored.
#' @param createDate1 Beginning of date-of-creation range
#' @param createDate2 End of date-of-creation range
#' @param receivedDate1 Beginning of date-of-reception range
#' @param receivedDate2 End of date-of-reception range
#' @param postedDate1 Beginning of date-of-posting range
#' @param postedDate2 End of date-of-posting range
#' @param category Document Category: AD (Aerospace and Transportation);
#' AEP (Agriculture, Environment, and Public Lands);
#' BFS (Banking and Financial); CT (Commerce and International);
#' LES (Defense, Law Enforcement, and Security);
#' EELS (Education, Labor, Presidential, and Government Services);
#' EUMM (Energy, Natural Resources, and Utilities);
#' HCFP (Food Safety, Health, and Pharmaceutical);
#' PRE (Housing, Development, and Real Estate);
#' ITT (Technology and Telecommunications)
#' @param sortBy Sort By: docketId (Docket ID); docId (Document ID);
#' title (Title); postedDate (Posted Date); agency (Agency);
#' documentType (Document Type); submitterName (Submitter Name);
#' organization (Organization). Sort Order is REQUIRED if this parameter is
#' included.
#' @param sortOrder Sort Order: ASC: Ascending; DESC: Descending
#' @param docketSubtype Docket Subtype: Only one docket subtype at a time may
#' be selected. One or more agency values must be part of the request.
#' Only values valid for the selected agency will be returned.
#' @param docketSubSubtype Docket Sub-subtype: Only one docket sub-subtype at
#' a time may be selected. One or more agency values must be part of the
#' request. Only values valid for the selected agency will be returned.
#' @param docSubtype Document Subtype: Single or multiple document subtypes may 
#' be included.
#' @param ... Additional request parameters. Passed directly to httr request.
#' @details A Docket Type is either Rulemaking or Nonrulemaking. A Rulemaking 
#' docket includes the type of regulation that establishes a rule.
#' While a Non-Rulemaking docket does not include a rule.
#' @importFrom assertthat assert_that
#' @importFrom httr GET timeout
#' @importFrom stats setNames
#' @export
documents <- function(apikey = NULL, countsOnly = NULL, encoded = NULL,
						keywords = NULL, docType = NULL, docketID = NULL,
						docketType = NULL, commentPeriod = NULL, agency = NULL,
						nresults = 1000, offset = NULL, closingSoon = NULL,
						newlyPosted = NULL, comStartDate = NULL,
						comEndDate = NULL, createDate1 = NULL,
						createDate2 = NULL, receivedDate1 = NULL,
						receivedDate2 = NULL,
						postedDate1 = NULL, postedDate2 = NULL, 
						category = NULL, sortBy = NULL, sortOrder = NULL, 
						docketSubtype = NULL, docketSubSubtype = NULL, 
						docSubtype = NULL, ...) {

	calls <- names(sapply(match.call(), deparse))[-1]

	# Validate passed parameters
	apikey <- .apikey(apikey)
	countsOnly <- as.integer(as.logical(countsOnly))
	encoded <- as.integer(as.logical(encoded))
	if(!is.null(docType)) {
    	assertthat::assert_that(all(docType %in%  c("N", "PR", "FR", "O", 
													"SR", "PS")))
  	}

  	if (!is.null(docketType)) {
    	assertthat::assert_that(docketType) %in% c("R", "N")
  	}

  	if (!is.null(commentPeriod)) {
    	assertthat::assert_that(commentPeriod) %in% c("O", "C")
  	}

  	if (!is.null(nresults)) {
    	assertthat::assert_that(nresults %in% c(10, 25, 100, 500, 1000))
  	}

  	if (!is.null(closingSoon)) {
    	assertthat::assert_that(closingSoon %in% c(0, 3, 15, 30, 90))
  	}

  	if (!is.null(newlyPosted)) {
    	assertthat::assert_that(newlyPosted %in% c(0, 3, 15, 30, 90))
	  }

  	if(!is.null(agency)) {
    	agency <- paste(agency, collapse = "+")
	}
  
  	comStartDate <- .datestring(comStartDate, NULL)
  	comEndDate <- .datestring(comEndDate, NULL)
  	createDate <- .datestring(createDate1, createDate2)
  	receivedDate <- .datestring(receivedDate1, receivedDate2)
  	postedDate <- .datestring(postedDate1, postedDate2)
  	keywords <- paste(keywords, collapse = "+")

  	if (!is.null(category)) {
    	assertthat::assert_that(all(category %in% c("AD", "AEP", "BFS", "LES", 
													"EELS", "EUMM", "HCFP", 
													"PRE", "ITT")))
	}

  	if (!is.null(sortBy)) {
    	assertthat::assert_that(all(sortBy %in% c("docketId", "docId", "title",
                                       				"postedDate", "agency",
                                       				"documentType", 
													"submitterName",
                                       				"organization")))
    	assertthat::assert_that(sortOrder %in% c("ASC", "DESC"))
  	}

  	queryArgs <- .compact(list(response_format = "json",
								api_key = apikey, countsOnly = countsOnly,
								encoded = encoded,
								s = keywords, dct = docType, dktid = docketID,
								dkt = docketType, cp = commentPeriod,
								a = agency,
								rpp = nresults, po = offset,
								cs = closingSoon,
								np = newlyPosted, cmsd = comStartDate,
								cmd = comEndDate, crd = createDate,
								rd = receivedDate,
								pd = postedDate, cat = category,
								sb = sortBy, so = sortOrder,
								dktst = docketSubtype,
								dktst2 = docketSubSubtype, docst = docSubtype))
  	queryArgs <- as.list(unlist(queryArgs))
  	names(queryArgs) <- gsub("[0-9]+", "", names(queryArgs))
  	if (length(queryArgs) == 0) {
    	queryArgs <- NULL
		}

  	httpResponse <- httr::GET(documentsApiURL, 
	  							query = queryArgs, 
	  							httr::timeout(getOption("timeout")), ...)
  	jsonData <- .parseResponse(httpResponse)
	allnames = Reduce(unique, lapply(jsonData$documents, names))
  	allrows = lapply(jsonData$documents, `[`, allnames)
  	allrows = lapply(allrows, stats::setNames, allnames)
  	allrows = lapply(allrows, .nullToNA)
  	documents <- dplyr::bind_rows(allrows)

	structure(
    	list(content = documents,
      		response = httpResponse,
			totalNumRecords = jsonData$totalNumRecords
    	),
    	class = "regulations_documents"
  	)
}
