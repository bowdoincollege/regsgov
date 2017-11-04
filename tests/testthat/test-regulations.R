context("regulationsdotgov access")

test_that("basic retrievals work", {
  docs1 = documents(apikey = 'DEMO_KEY', 
                    agency = "EPA",
                    postedDate1 = "2015-01-01", 
                    postedDate2 = "2015-02-01")
  expect_is(docs1$content, "data.frame")
  expect_gt(nrow(docs1$content), 0)
})

test_that("authentication works", {
  expect_is(documents(apikey = 'DEMO_KEY', 
                      agency = "EPA", 
                      newlyPosted = 15)$content, 
            "data.frame")
  expect_error(documents(agency = "EPA", newlyPosted = 15, apikey = ""))
})
