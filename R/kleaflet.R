#' Draw a complete map in one call
#'
#' `kleaflet()` builds a leaflet map (coordinates, aesthetics, palette,
#' legend, popups, labels, groups, base map, view) from a data object and a
#' few short arguments, and returns a `kleaflet` object. Print it to draw
#' it, compose it with `+`, or convert it with [as_leaflet()].
#'
#' @section Mapping aesthetics:
#' `lon`, `lat`, `color`, `fill`, `size`, `opacity` and `group` take column
#' names (strings). Special values:
#' \itemize{
#'   \item `lon`, `lat` omitted: guessed from the column names (`lon`, `lng`,
#'   `long`, `longitude`, `x`; `lat`, `latitude`, `y`). `sf` data needs none.
#'   \item a column given to `color` or `fill` is coloured with the palette:
#'   a continuous scale for numbers, a discrete one otherwise, with a legend.
#'   `fill` defaults to `color` for circles and polygons.
#'   \item a string that is not a column, passed to `color`, `fill` or
#'   `group`, creates a legend entry (or a group): `color = "Stations"` names
#'   the layer.
#'   \item `I("red")` (or a number, for `size`, `opacity`) is a fixed value,
#'   not a mapping.
#'   \item a numeric column given to `size` or `opacity` is rescaled to a
#'   readable range (`size_range`); there is no legend for them.
#'   \item `group = "col"` splits the layer: one switchable overlay per
#'   value, in a layers control.
#' }
#'
#' @section Popups and labels:
#' `popup` (on click) and `label` (on hover) accept:
#' \itemize{
#'   \item `TRUE`: all the columns, as a small table;
#'   \item column names: the value (one column) or `name: value` lines;
#'   \item a template with columns in braces:
#'   `"<b>{name}</b><br>{pop} inhabitants"`;
#'   \item a function of the data returning one HTML string per row;
#'   \item one string per row, used as they are.
#' }
#' Values from the data are HTML-escaped.
#'
#' @section Extending a map:
#' `kleaflet(p, new_data, ...)` (with `p` a kleaflet), `p + kleaflet(...)`
#' and [kleaf_add()] add a layer; colours and legends are shared across
#' layers. Any function of the map can be added with `+` and is applied last
#' (`+ function(m) leaflet::addScaleBar(m)`).
#'
#' @param data A data frame with longitude/latitude columns, an `sf` object,
#'   or anything [as_kdata()] understands. If a `kleaflet`, a layer is added
#'   to it.
#' @param lon,lat,color,fill,size,opacity,group Aesthetics, see Details.
#'   `colour` is accepted as an alias of `color`, `lng` of `lon`.
#' @param popup,label Popup and hover label, see Details.
#' @param vars Optional named list of aesthetics (`list(lon = "x")`), an
#'   alternative to the arguments above (they take precedence).
#' @param type Layer type, see [kleaf_types()]; or a leaflet function. By
#'   default guessed from the data (circles for points, lines, polygons).
#' @param size_range Range of the radius / weight a numeric `size` is
#'   rescaled to (default depends on the type).
#' @param title,caption Titles displayed on the map. `NA` removes one.
#' @param labels Named list of legend titles (`color`, `fill`) and titles
#'   (`title`, `caption`). Default legend title: the mapped column name.
#' @param theme Theme: a name ([kleaf_themes()]) or a provider of
#'   [leaflet::providers]. See [kleaf_register_theme()].
#' @param tiles Base map(s), overriding the theme: names of
#'   [leaflet::providers] (several give a base map switcher),
#'   `"OpenStreetMap"` or `FALSE` for none.
#' @param palette Colours for `color`/`fill`: a vector (named to fix level
#'   colours), a palette name ([kleaf_palettes()], `"Blues"`, `"viridis"`...)
#'   or a function of `n`. Default: the theme palette.
#' @param scale How a numeric colour is cut: `"numeric"` (continuous),
#'   `"bin"` or `"quantile"`.
#' @param bins Number of classes (or breaks) for `scale = "bin"` or
#'   `"quantile"`.
#' @param legend Position of the legend (`"bottomright"`, `"bottomleft"`,
#'   `"topright"`, `"topleft"`), or `"none"`/`FALSE`.
#' @param view Initial view: `c(lon, lat, zoom)` or a bounding box
#'   `c(lon1, lat1, lon2, lat2)`. Default: fit the data.
#' @param scale_bar,minimap Add a scale bar / an overview map.
#' @param new_data For the `kleaflet` method: data of the new layer (default:
#'   the data of the first layer).
#' @param ... Extra arguments of the leaflet function of the layer type
#'   (`radius`, `weight`, `dashArray`, `popupOptions`, `labelOptions`,
#'   `clusterOptions`...).
#'
#' @return An object of class `kleaflet`.
#'
#' @examples
#' # points coloured by a column, popups and a legend: one call
#' kleaflet(quakes, color = "mag", size = "depth", popup = c("mag", "depth"))
#'
#' # discrete colours, a theme, a base map
#' q <- quakes
#' q$class <- cut(q$mag, c(4, 5, 6, 7))
#' kleaflet(q, color = "class", theme = "inrae", title = "Fiji earthquakes",
#'          label = "{mag} Mw")
#'
#' # one switchable layer per group
#' kleaflet(q, color = "class", group = "class")
#'
#' # choropleth map from an sf object
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"),
#'                     quiet = TRUE)
#'   kleaflet(nc, fill = "SID74", palette = "YlOrRd", scale = "bin",
#'            popup = "<b>{NAME}</b><br>{SID74} cases", theme = "light")
#' }
#'
#' # superpose two datasets: shared legend
#' a <- data.frame(lon = c(2.35, 2.40), lat = c(48.85, 48.87))
#' b <- data.frame(lon = c(2.30, 2.33), lat = c(48.84, 48.88))
#' kleaflet(a, color = "Stations") +
#'   kleaflet(b, color = "Sensors")
#'
#' @export
kleaflet <- function(data, ...) {
  UseMethod("kleaflet")
}

#' @export
#' @rdname kleaflet
kleaflet.default <- function(
  data,
  lon = NULL, lat = NULL, color = NULL, fill = NULL, size = NULL,
  opacity = NULL, group = NULL, popup = NULL, label = NULL,
  vars = NULL, type = NULL, size_range = NULL,
  title = NULL, caption = NULL, labels = NULL,
  theme = NULL, tiles = NULL, palette = NULL, scale = NULL, bins = NULL,
  legend = NULL, view = NULL, scale_bar = NULL, minimap = NULL,
  ...
) {
  params <- list(...)
  if (!is.null(params$colour)) {
    color <- color %||% params$colour
    params$colour <- NULL
  }
  if (!is.null(params$lng)) {
    lon <- lon %||% params$lng
    params$lng <- NULL
  }
  source <- as_kdata(data)

  args <- norm_list(list(
    lon = lon, lat = lat, colour = color, fill = fill, size = size,
    opacity = opacity, group = group
  ))
  vars <- norm_list(vars)
  for (nm in setdiff(names(vars), names(args))) args[[nm]] <- vars[[nm]]
  unknown <- setdiff(names(args), std_aes)
  if (length(unknown)) {
    stop("Unknown aesthetic(s) in `vars`: ", paste(unknown, collapse = ", "),
         call. = FALSE)
  }
  if (!is.null(scale)) {
    scale <- match.arg(scale, c("numeric", "bin", "quantile"))
  }
  explicit <- norm_list(c(
    list(title = title, caption = caption), as.list(labels)
  ))

  obj <- list(
    layers = list(new_layer(
      source, args, type, popup, label, size_range, params
    )),
    labels = explicit,
    theme = theme, tiles = tiles, palette = palette, scale = scale,
    bins = bins, legend = legend, view = view, scale_bar = scale_bar,
    minimap = minimap, extras = list()
  )
  class(obj) <- "kleaflet"
  obj
}

#' @export
#' @rdname kleaflet
kleaflet.kleaflet <- function(data, new_data = NULL, ...) {
  kleaf_add(data, new_data, ...)
}
