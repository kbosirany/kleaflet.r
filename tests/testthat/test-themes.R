test_that("registries are populated and extensible", {
  expect_true(all(c("default", "inrae", "dark") %in% kleaf_themes()))
  expect_true(all(c("inrae", "okabe_ito") %in% kleaf_palettes()))
  expect_true(all(c("circle", "polygon", "line", "marker") %in% kleaf_types()))
  kleaf_register_palette("tmp_pal", c("#111111", "#eeeeee"))
  kleaf_register_theme(
    "tmp_theme", tiles = "CartoDB.Positron", palette = "tmp_pal"
  )
  cl <- first_call(kleaflet(stations, color = "kind", theme = "tmp_theme"))
  expect_equal(cl$args$color[1], "#111111")
  kleaf_register_type("tmp_type", "addCircleMarkers", aes = c(colour = "color"),
                      params = list(radius = 12))
  cl <- first_call(kleaflet(stations, type = "tmp_type"))
  expect_equal(cl$args$radius, 12)
  expect_error(
    kleaf_register_type("bad", "addMarkers", aes = c(zzz = "a")), "Unknown"
  )
  expect_error(kleaf_register_theme("bad", tiles = 1), "character")
})

test_that("the theme sets tiles and palette, `tiles` and `palette` win", {
  tiles <- function(p) {
    m <- render(p)$map
    m$x$calls[[1]]$args[[1]]
  }
  dark <- tiles(kleaflet(stations, theme = "dark"))
  expect_match(dark, "dark", ignore.case = TRUE)
  expect_match(
    tiles(kleaflet(stations, theme = "dark", tiles = "Esri.WorldImagery")),
    "Esri", ignore.case = TRUE
  )
  inrae <- first_call(kleaflet(stations, color = "kind", theme = "inrae"))
  expect_equal(inrae$args$color[1], "#00A3A6")
  own <- first_call(kleaflet(
    stations, color = "kind", theme = "inrae", palette = c("black", "white")
  ))
  expect_equal(own$args$color[1], "#000000")
  # a provider name works as a theme
  expect_s3_class(
    as_leaflet(kleaflet(stations, theme = "Esri.WorldTopoMap")), "leaflet"
  )
})

test_that("session options set the defaults", {
  withr::local_options(kleaflet.theme = "inrae")
  expect_equal(
    first_call(kleaflet(stations, color = "kind"))$args$color[1], "#00A3A6"
  )
  withr::local_options(
    kleaflet.theme = NULL, kleaflet.palette = c("#123456", "#654321")
  )
  expect_equal(
    first_call(kleaflet(stations, color = "kind"))$args$color[1], "#123456"
  )
})

test_that("more levels than colours interpolates", {
  d <- data.frame(lon = 1:5, lat = 1:5, g = letters[1:5])
  cl <- first_call(kleaflet(d, color = "g", palette = c("red", "blue")))
  expect_length(unique(cl$args$color), 5)
})
