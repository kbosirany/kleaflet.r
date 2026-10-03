test_that("`+` appends layers and settings of the right side win", {
  a <- kleaflet(stations, color = "kind", theme = "light")
  b <- kleaflet(stations, color = "n", theme = "dark")
  p <- a + b
  expect_length(p$layers, 2)
  expect_equal(p$theme, "dark")
})

test_that("functions are applied last, in order", {
  p <- kleaflet(stations) +
    (function(m) leaflet::addScaleBar(m)) +
    (function(m) leaflet::addMiniMap(m))
  expect_equal(tail(render(p)$methods, 2), c("addScaleBar", "addMiniMap"))
  expect_error(kleaflet(stations) + 1, "function")
})

test_that("kleaf_add inherits aesthetics that exist in the new data", {
  p <- kleaflet(stations, color = "kind") |> kleaf_add(type = "marker")
  expect_equal(p$layers[[2]]$mapped$colour, "kind")
  q <- kleaflet(stations, color = "kind") |>
    kleaf_add(data.frame(lon = 1, lat = 1), type = "marker")
  expect_null(q$layers[[2]]$mapped$colour)
  r <- kleaflet(
    kleaflet(stations, color = "kind"), data.frame(lon = 1, lat = 1)
  )
  expect_length(r$layers, 2)
})

test_that("modifiers set the map options", {
  p <- kleaflet(stations, color = "n") |>
    kleaf_labs(title = "T", color = "Count") |>
    kleaf_theme("dark", palette = "Reds") |>
    kleaf_palette("Greens", scale = "bin", bins = 3) |>
    kleaf_legend("topleft") |>
    kleaf_view(c(2, 48, 5)) |>
    kleaf_tiles(c("CartoDB.Positron", "Esri.WorldImagery")) |>
    kleaf_controls(scale_bar = TRUE, minimap = TRUE)
  r <- render(p)
  expect_true(all(
    c("addScaleBar", "addMiniMap", "addLayersControl") %in% r$methods
  ))
  expect_equal(p$labels$colour, "Count")
  expect_equal(p$scale, "bin")
  expect_error(kleaf_legend(1, "none"), "kleaflet")
})

test_that("legends can be moved, titled or removed", {
  leg <- function(p) {
    r <- render(p)
    r$map$x$calls[r$methods == "addLegend"]
  }
  expect_length(leg(kleaflet(stations, color = "n", legend = "none")), 0)
  expect_length(leg(kleaflet(stations, color = "n", legend = FALSE)), 0)
  l <- leg(kleaflet(stations, color = "n", labels = list(color = "Count")))
  expect_match(l[[1]]$args[[1]]$title, "Count")
  expect_error(as_leaflet(kleaflet(stations, color = "n", legend = "x")))
})

test_that("groups give one layer per level and a layers control", {
  r <- render(kleaflet(stations, color = "kind", group = "kind"))
  expect_equal(sum(r$methods == "addCircleMarkers"), 2)
  expect_true("addLayersControl" %in% r$methods)
  calls <- all_calls(kleaflet(stations, group = "kind"))
  expect_equal(vapply(calls, function(cl) cl$args$group, ""), c("x", "y"))
  expect_equal(calls[[1]]$args$lng, c(2.35, 2.30))
})

test_that("several base maps give a switcher", {
  r <- render(kleaflet(
    stations, tiles = c("OpenStreetMap", "Esri.WorldImagery")
  ))
  expect_equal(sum(grepl("Tiles", r$methods)), 2)
  expect_true("addLayersControl" %in% r$methods)
  none <- render(kleaflet(stations, tiles = FALSE))$methods
  expect_equal(sum(grepl("Tiles", none)), 0)
})

test_that("as_leaflet leaves a leaflet unchanged", {
  m <- leaflet::leaflet()
  expect_identical(as_leaflet(m), m)
})

test_that("printing returns the object invisibly", {
  p <- kleaflet(stations)
  expect_invisible(print(p))
})
