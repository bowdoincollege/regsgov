context("regulationsdotgov access")

test_that("basic retrievals work", {
  docs1 = documents(apikey = 'DEMO_KEY', 
                    agency = "EPA",
                    postedDate1 = "2015-01-01", 
                    postedDate2 = "2015-02-01")
  expect_is(docs1$contents, "data.frame")
  expect_more_than(nrow(docs1$contents), 0)
}
)

test_that("authentication works", {
  expect_is(documents(agency = "EPA", newlyPosted = 15), "data.frame")
  expect_error(documents(agency = "EPA", newlyPosted = 15, apikey = ""))
})
