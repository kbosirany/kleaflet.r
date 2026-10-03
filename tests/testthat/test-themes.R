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

test_that("inrae colours discrete and numeric color and fill", {
  d <- stations
  # discrete: the INRAE palette
  disc <- first_call(kleaflet(d, color = "kind", theme = "inrae"))
  expect_equal(disc$args$color[1:2], c("#00A3A6", "#9DC544"))
  expect_equal(disc$args$fillColor, disc$args$color)
  # numeric: the sequential INRAE palette, from light blue to violet
  num <- first_call(kleaflet(d, color = "n", theme = "inrae"))
  expect_equal(num$args$color[which.min(d$n)], "#CDE9EB")
  expect_equal(num$args$color[which.max(d$n)], "#423089")
  # fill and color are scaled independently, both with INRAE colours
  both <- first_call(kleaflet(d, color = "kind", fill = "n", theme = "inrae"))
  expect_equal(both$args$color[1], "#00A3A6")
  expect_equal(both$args$fillColor[which.max(d$n)], "#423089")
  # also when asked by name, without the theme
  by_name <- first_call(kleaflet(d, fill = "n", palette = "inrae_seq"))
  expect_equal(by_name$args$fillColor[which.max(d$n)], "#423089")
  div <- first_call(kleaflet(d, fill = "n", palette = "inrae_div"))
  expect_equal(div$args$fillColor[which.min(d$n)], "#ED6E6C")
})

test_that("polygons take the INRAE palette in fill", {
  skip_if_not_installed("sf")
  x <- nc()
  cl <- first_call(kleaflet(x, fill = "SID74", theme = "inrae"))
  expect_equal(cl$args$fillColor[which.max(x$SID74)[1]], "#423089")
  expect_equal(cl$args$color, "white")
})

test_that("a palette can have its own continuous colours", {
  kleaf_register_palette(
    "tmp_dual", c("#ff0000", "#00ff00"), continuous = c("#000000", "#ffffff")
  )
  d <- stations
  disc <- first_call(kleaflet(d, color = "kind", palette = "tmp_dual"))
  expect_equal(disc$args$color[1], "#FF0000")
  num <- first_call(kleaflet(d, color = "n", palette = "tmp_dual"))
  expect_equal(num$args$color[which.max(d$n)], "#FFFFFF")
  expect_error(kleaf_register_palette("bad", "red", continuous = 1))
})

test_that("a theme style is injected as CSS", {
  css <- function(p) paste(unlist(render(p)$map$prepend), collapse = " ")
  expect_match(css(kleaflet(stations, theme = "inrae")), "#00a3a6")
  expect_match(css(kleaflet(stations, theme = "inrae")), "leaflet-popup")
  expect_equal(css(kleaflet(stations)), "")
  expect_equal(css(kleaflet(stations, theme = "dark")), "")
  kleaf_register_theme(
    "tmp_style", style = list(accent = "#ff0000", text = "#111111")
  )
  expect_match(css(kleaflet(stations, theme = "tmp_style")), "#ff0000")
  expect_error(kleaf_register_theme("bad", style = list(zzz = 1)), "style")
})

test_that("title and caption carry the classes of the theme", {
  m <- render(kleaflet(stations, theme = "inrae", title = "T", caption = "C"))
  html <- paste(vapply(
    m$map$x$calls[m$methods == "addControl"],
    function(cl) as.character(cl$args[[1]]), ""
  ), collapse = " ")
  expect_match(html, "kleaf-title")
  expect_match(html, "kleaf-caption")
})

test_that("fonts come from the options, for any theme", {
  css <- function(p) paste(unlist(render(p)$map$prepend), collapse = " ")
  withr::local_options(
    kleaflet.title_family = "Raleway", kleaflet.base_family = "Avenir"
  )
  out <- css(kleaflet(stations, theme = "inrae"))
  expect_match(out, "Raleway")
  expect_match(out, "Avenir")
  expect_match(css(kleaflet(stations)), "Avenir")
})
