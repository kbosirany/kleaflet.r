# Build the map for real: catches errors that only appear at render time
render <- function(p) {
  m <- as_leaflet(p)
  list(map = m, methods = vapply(m$x$calls, `[[`, "", "method"))
}

# Arguments of the (single) call a layer is drawn with
first_call <- function(p, i = 1L) layer_calls(prepare(p)$res[[i]])[[1L]]
all_calls <- function(p, i = 1L) layer_calls(prepare(p)$res[[i]])

stations <- data.frame(
  lon = c(2.35, 2.40, 2.30), lat = c(48.85, 48.87, 48.84),
  name = c("A", "B", "C"), kind = c("x", "y", "x"), n = c(10, 200, 3000)
)

nc <- function() {
  sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
}
