test_that("popup and label accept several forms", {
  html <- function(x) first_call(kleaflet(stations, popup = x))$args$popup
  expect_equal(html("name"), c("A", "B", "C"))
  expect_equal(html(c("name", "kind"))[1], "<b>name</b>: A<br/><b>kind</b>: x")
  expect_equal(html("<i>{name}</i> ({n})")[2], "<i>B</i> (200)")
  expect_equal(html(function(d) paste("row", d$name))[3], "row C")
  expect_equal(html(c("u", "v", "w")), c("u", "v", "w"))
  expect_length(html(TRUE), 3)
  expect_null(html(NULL))
})

test_that("values are HTML-escaped, numbers formatted", {
  d <- data.frame(lon = 1, lat = 1, t = "<script>", v = 1234567)
  p <- first_call(kleaflet(d, popup = "{t} {v}"))$args$popup
  expect_equal(p, "&lt;script&gt; 1234567")
})

test_that("labels are HTML", {
  cl <- first_call(kleaflet(stations, label = "name"))
  expect_length(cl$args$label, 3)
  expect_s3_class(cl$args$label[[1]], "html")
})

test_that("bad popups give clear errors", {
  expect_error(first_call(kleaflet(stations, popup = "{zzz}")), "not found")
  expect_error(first_call(kleaflet(stations, popup = c("a", "b"))), "neither")
  expect_error(
    first_call(kleaflet(stations, popup = function(d) "x")), "one string"
  )
})
