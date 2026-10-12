test_that("matrices and lists are accepted", {
  expect_equal(
    first_call(kleaflet(cbind(c(1, 2), c(3, 4))))$args$lat, c(3, 4)
  )
  expect_equal(
    first_call(kleaflet(list(lon = 1:2, lat = 3:4)))$args$lng, 1:2
  )
  expect_error(kleaflet(matrix(1:3, 1)), "two columns")
  expect_error(kleaflet(list(1, 2)), "named")
  expect_error(kleaflet(data.frame()), "no column")
})

test_that("sf data is reprojected and typed by geometry", {
  skip_if_not_installed("sf")
  x <- nc()
  expect_equal(sf::st_crs(as_kdata(x)), sf::st_crs(4326))
  expect_equal(first_call(kleaflet(x))$fun, leaflet::addPolygons)
  pts <- suppressWarnings(sf::st_centroid(x))
  expect_equal(first_call(kleaflet(pts))$fun, leaflet::addCircleMarkers)
  geo <- first_call(kleaflet(sf::st_geometry(pts)))$args$data
  expect_equal(nrow(geo), nrow(x))
  # polygons can be drawn as points at their centroid
  expect_s3_class(
    as_leaflet(kleaflet(x, type = "circle", fill = "BIR74")), "leaflet"
  )
  # but points cannot be drawn as polygons
  expect_error(as_leaflet(kleaflet(pts, type = "polygon")), "polygons")
  sf::st_crs(x) <- NA
  expect_message(as_kdata(x), "EPSG:4326")
})

test_that("choropleth maps work with popups and groups", {
  skip_if_not_installed("sf")
  x <- nc()
  x$grp <- ifelse(x$SID74 > 5, "high", "low")
  r <- render(kleaflet(
    x, fill = "SID74", scale = "quantile", bins = 4, group = "grp",
    popup = "<b>{NAME}</b>: {SID74}"
  ))
  expect_equal(sum(r$methods == "addPolygons"), 2)
  expect_equal(sum(r$methods == "addLegend"), 1)
})

test_that("the view fits the data or is explicit", {
  m <- as_leaflet(kleaflet(stations))
  expect_equal(
    unlist(m$x$limits), c(lat1 = 48.84, lat2 = 48.87, lng1 = 2.3, lng2 = 2.4),
    ignore_attr = TRUE, tolerance = 1e-8
  )
  v <- as_leaflet(kleaflet(stations, view = c(2, 48, 5)))
  expect_equal(v$x$setView[[2]], 5)
  one <- as_leaflet(kleaflet(stations[1, ]))
  expect_equal(one$x$setView[[2]], 12)
})

test_that("a SpatRaster is drawn as polygons, aggregated if heavy", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  r <- terra::rast(
    nrows = 40, ncols = 40, xmin = 0, xmax = 4, ymin = 40, ymax = 44,
    crs = "EPSG:4326", vals = seq_len(1600), names = "v"
  )
  d <- as_kdata(r)
  expect_s3_class(d, "sf")
  expect_equal(nrow(d), 1600)
  expect_equal(names(d), c("v", "geometry"))
  # aggregated by a factor 2 under a limit of 500 cells
  expect_equal(nrow(as_kdata(r, max_cells = 500)), 400)
  call <- first_call(kleaflet(r, fill = "v", weight = 0))
  expect_equal(call$fun, leaflet::addPolygons)
})
