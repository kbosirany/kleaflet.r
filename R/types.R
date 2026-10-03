#' Layer types
#'
#' A *type* maps a short name (`"circle"`, `"polygon"`, ...) to a leaflet
#' function plus default parameters and the leaflet arguments each
#' aesthetic drives. Types live in a registry, so you can add your own with
#' `kleaf_register_type()`.
#'
#' Built-in types:
#' \itemize{
#'   \item `circle`: circle markers (default for points);
#'   \item `circle_m`: circles with a radius in metres;
#'   \item `marker`: standard pins (no colour, but popups and labels);
#'   \item `cluster`: pins grouped in clusters;
#'   \item `polygon`: polygons, e.g. choropleth maps (default for polygons);
#'   \item `line`: lines (default for lines).
#' }
#'
#' @param name Name of the type.
#' @param fun A leaflet function adding a layer, e.g.
#'   [leaflet::addCircleMarkers], or its name. It is called with the map
#'   first and, for points, `lng` and `lat` (for spatial `sf` data, `data`).
#' @param geometry Geometry the function draws: `"point"`, `"line"` or
#'   `"polygon"`. Points are drawn at the centroid of other geometries.
#' @param aes Named character vector: for each aesthetic the type
#'   understands (among `colour`, `fill`, `size`, `opacity`), the name of the
#'   argument of `fun` it sets, e.g. `c(colour = "color", size = "radius")`.
#' @param params Default arguments passed to `fun`.
#' @param fill_follows_colour If `TRUE`, `fill` takes the value of `color`
#'   when it is not given.
#' @param size_range Range of the values `size` is rescaled to when mapped
#'   to a numeric column.
#'
#' @return `kleaf_register_type()` returns `name` invisibly; `kleaf_types()`
#'   a character vector of the registered types.
#'
#' @examples
#' kleaf_types()
#' kleaf_register_type(
#'   "big_dot", "addCircleMarkers",
#'   aes = c(colour = "color"),
#'   params = list(radius = 12, fillOpacity = 0.9)
#' )
#' kleaflet(quakes, color = "mag", type = "big_dot")
#'
#' @export
kleaf_register_type <- function(
  name, fun, geometry = c("point", "line", "polygon"), aes = character(),
  params = list(), fill_follows_colour = FALSE, size_range = c(3, 15)
) {
  geometry <- match.arg(geometry)
  stopifnot(
    is.character(name), length(name) == 1L,
    is.function(fun) || (is.character(fun) && length(fun) == 1L)
  )
  bad <- setdiff(names(aes), c("colour", "fill", "size", "opacity"))
  if (length(bad)) {
    stop("Unknown aesthetic(s) in `aes`: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
  .kleaf$types[[name]] <- type_spec(
    fun, geometry, aes, params, fill_follows_colour, size_range
  )
  invisible(name)
}

#' @export
#' @rdname kleaf_register_type
kleaf_types <- function() names(.kleaf$types)

type_spec <- function(fun, geometry = "point", aes = character(),
                      params = list(), fill_follows_colour = FALSE,
                      size_range = c(3, 15)) {
  list(
    fun = fun, geometry = geometry, aes = aes, params = params,
    fill_follows_colour = fill_follows_colour, size_range = size_range
  )
}

get_type <- function(type) {
  if (is.function(type)) return(type_spec(type))
  if (!is.character(type) || length(type) != 1L) {
    stop("`type` must be a single string or a leaflet function.",
         call. = FALSE)
  }
  spec <- .kleaf$types[[type]]
  if (is.null(spec)) {
    stop(
      "Unknown layer type '", type, "'. Available: ",
      paste(kleaf_types(), collapse = ", "), ".",
      call. = FALSE
    )
  }
  spec
}

# The leaflet function of a type (looked up when drawing)
type_fun <- function(spec) {
  if (is.character(spec$fun)) {
    getExportedValue("leaflet", spec$fun)
  } else {
    spec$fun
  }
}

# Kind of geometry of an sf object: "point", "line" or "polygon"
geometry_kind <- function(src) {
  g <- unique(as.character(sf::st_geometry_type(src)))
  if (all(g %in% c("POINT", "MULTIPOINT"))) return("point")
  if (all(g %in% c("LINESTRING", "MULTILINESTRING"))) return("line")
  if (all(g %in% c("POLYGON", "MULTIPOLYGON"))) return("polygon")
  stop(
    "Mixed or unsupported geometry types (", paste(g, collapse = ", "),
    "). Cast them first, e.g. with sf::st_cast().",
    call. = FALSE
  )
}

# Pick a sensible type from the shape of the data
infer_type <- function(src) {
  hint <- attr(src, "kleaf_type")
  if (!is.null(hint)) return(hint)
  if (!inherits(src, "sf")) return("circle")
  switch(
    geometry_kind(src), point = "circle", line = "line", polygon = "polygon"
  )
}

register_builtin_types <- function() {
  reg <- kleaf_register_type
  reg(
    "circle", "addCircleMarkers",
    aes = c(colour = "color", fill = "fillColor", size = "radius",
            opacity = "fillOpacity"),
    params = list(radius = 5, weight = 1, opacity = 1, fillOpacity = 0.7,
                  color = "white", fillColor = "#3388ff"),
    fill_follows_colour = TRUE
  )
  reg(
    "circle_m", "addCircles",
    aes = c(colour = "color", fill = "fillColor", size = "radius",
            opacity = "fillOpacity"),
    params = list(radius = 1000, weight = 1, opacity = 1, fillOpacity = 0.5,
                  color = "white", fillColor = "#3388ff"),
    fill_follows_colour = TRUE, size_range = c(500, 20000)
  )
  reg("marker", "addMarkers")
  reg(
    "cluster", "addMarkers",
    params = list(clusterOptions = leaflet::markerClusterOptions())
  )
  reg(
    "polygon", "addPolygons", geometry = "polygon",
    aes = c(colour = "color", fill = "fillColor", size = "weight",
            opacity = "fillOpacity"),
    params = list(color = "white", weight = 1, opacity = 1,
                  fillOpacity = 0.7),
    fill_follows_colour = TRUE, size_range = c(1, 6)
  )
  reg(
    "line", "addPolylines", geometry = "line",
    aes = c(colour = "color", size = "weight", opacity = "opacity"),
    params = list(weight = 3, opacity = 0.8), size_range = c(1, 8)
  )
}
