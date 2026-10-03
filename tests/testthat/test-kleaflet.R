test_that("one call builds a leaflet map", {
  p <- kleaflet(stations, color = "kind", title = "Stations")
  expect_s3_class(p, "kleaflet")
  r <- render(p)
  expect_s3_class(r$map, "leaflet")
  expect_equal(r$methods[1:2], c("addTiles", "addCircleMarkers"))
  expect_true("addLegend" %in% r$methods)
  expect_true("addControl" %in% r$methods)
})

test_that("coordinates are guessed from the column names", {
  d <- data.frame(Longitude = c(1, 2), Latitude = c(3, 4))
  expect_equal(first_call(kleaflet(d))$args$lng, c(1, 2))
  expect_equal(first_call(kleaflet(quakes))$args$lat, quakes$lat)
  expect_equal(
    first_call(kleaflet(data.frame(a = 1, b = 2), lon = "a", lat = "b"))$args$lat,
    2
  )
  expect_error(kleaflet(data.frame(a = 1)) |> as_leaflet(), "longitude")
})

test_that("`vars`, `colour` and `lng` are aliases", {
  d <- data.frame(a = c(1, 2), b = c(3, 4), g = c("u", "v"))
  p1 <- first_call(kleaflet(d, lon = "a", lat = "b", color = "g"))
  p2 <- first_call(
    kleaflet(d, vars = list(lng = "a", lat = "b", colour = "g"))
  )
  expect_equal(p1$args, p2$args)
})

test_that("rows without coordinates are dropped", {
  d <- data.frame(lon = c(1, NA, 3), lat = c(1, 2, 3), v = 1:3)
  expect_message(cl <- first_call(kleaflet(d, color = "v")), "dropped")
  expect_equal(cl$args$lng, c(1, 3))
  expect_length(cl$args$color, 2)
})

test_that("a mapped colour gets a palette and a legend", {
  r <- render(kleaflet(stations, color = "n", palette = "Blues"))
  expect_equal(sum(r$methods == "addLegend"), 1)
  cl <- first_call(kleaflet(stations, color = "kind"))
  expect_equal(cl$args$color, cl$args$fillColor)
  expect_equal(cl$args$color[1], cl$args$color[3])
  expect_false(cl$args$color[1] == cl$args$color[2])
})

test_that("a named palette fixes the colour of the levels", {
  cl <- first_call(kleaflet(
    stations, color = "kind", palette = c(y = "#ff0000", x = "#0000ff")
  ))
  expect_equal(toupper(cl$args$color), c("#0000FF", "#FF0000", "#0000FF"))
  expect_error(
    as_leaflet(kleaflet(stations, color = "kind", palette = c(x = "red"))),
    "no colour"
  )
})

test_that("registered palettes and functions are accepted", {
  expect_s3_class(
    as_leaflet(kleaflet(stations, color = "kind", palette = "inrae")),
    "leaflet"
  )
  expect_s3_class(
    as_leaflet(
      kleaflet(stations, color = "kind", palette = grDevices::rainbow)
    ),
    "leaflet"
  )
})

test_that("numeric scales can be binned or quantile", {
  for (s in c("numeric", "bin", "quantile")) {
    r <- render(kleaflet(stations, color = "n", scale = s, bins = 3))
    expect_true("addLegend" %in% r$methods)
  }
  expect_error(kleaflet(stations, color = "n", scale = "zzz"), "should be")
})

test_that("a constant label is a legend entry shared by the layers", {
  b <- data.frame(lon = 2.5, lat = 48.9)
  p <- kleaflet(stations, color = "Stations") + kleaflet(b, color = "Sensors")
  r <- render(p)
  expect_equal(sum(r$methods == "addLegend"), 1)
  expect_equal(sum(r$methods == "addCircleMarkers"), 2)
  leg <- r$map$x$calls[[which(r$methods == "addLegend")]]$args[[1]]
  expect_setequal(leg$labels, c("Stations", "Sensors"))
})

test_that("fixed values are parameters, not mappings", {
  cl <- first_call(
    kleaflet(stations, color = I("red"), size = 9, opacity = 0.2)
  )
  expect_equal(cl$args$color, "red")
  expect_equal(cl$args$fillColor, "red")
  expect_equal(cl$args$radius, 9)
  expect_equal(cl$args$fillOpacity, 0.2)
  r <- render(kleaflet(stations, color = I("red")))
  expect_false("addLegend" %in% r$methods)
})

test_that("a numeric size is rescaled to the size range", {
  cl <- first_call(kleaflet(stations, size = "n", size_range = c(2, 20)))
  expect_equal(range(cl$args$radius), c(2, 20))
  expect_error(
    first_call(kleaflet(stations, size = "kind")), "numeric"
  )
})

test_that("geom parameters go through `...`", {
  cl <- first_call(kleaflet(stations, weight = 4, dashArray = "3"))
  expect_equal(cl$args$weight, 4)
  expect_equal(cl$args$dashArray, "3")
})

test_that("an unsupported aesthetic is reported", {
  expect_warning(
    first_call(kleaflet(stations, type = "marker", color = "kind")),
    "ignores"
  )
  expect_s3_class(
    as_leaflet(kleaflet(stations, type = "marker", popup = TRUE)), "leaflet"
  )
})

test_that("unknown columns, types and themes give clear errors", {
  expect_error(kleaflet(stations, lon = "nope"), "not found")
  expect_error(kleaflet(stations, type = "zzz"), "Unknown layer type")
  expect_error(as_leaflet(kleaflet(stations, theme = "zzz")), "Unknown theme")
  expect_error(as_leaflet(kleaflet(stations, tiles = "zzz")), "Unknown tiles")
  expect_error(as_leaflet(kleaflet(stations, view = 1)), "view")
  expect_error(kleaflet(stations, type = "polygon") |> as_leaflet(), "sf")
})

test_that("every built-in type renders", {
  for (type in c("circle", "circle_m", "marker", "cluster")) {
    expect_s3_class(render(kleaflet(stations, type = type))$map, "leaflet")
  }
  skip_if_not_installed("sf")
  x <- nc()
  expect_s3_class(render(kleaflet(x))$map, "leaflet")
  lines <- sf::st_cast(x, "MULTILINESTRING")
  expect_s3_class(render(kleaflet(lines))$map, "leaflet")
})
