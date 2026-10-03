#' Convert to a leaflet map
#'
#' `as_leaflet()` renders a [kleaflet()] specification into a regular
#' `leaflet` htmlwidget, which you can then customise with any leaflet
#' function (`|> leaflet::addScaleBar()`), use in Shiny
#' (`leaflet::renderLeaflet(as_leaflet(p))`) or save with [kleaf_save()].
#' Printing a kleaflet does this implicitly.
#'
#' @param x A `kleaflet` (or a `leaflet` map, returned unchanged).
#' @param ... Unused.
#'
#' @return A `leaflet` map.
#'
#' @examples
#' p <- kleaflet(quakes, color = "mag")
#' m <- as_leaflet(p)
#' class(m)
#' m |> leaflet::addScaleBar()
#'
#' @export
as_leaflet <- function(x, ...) {
  UseMethod("as_leaflet")
}

#' @export
#' @rdname as_leaflet
as_leaflet.leaflet <- function(x, ...) x

#' @export
#' @rdname as_leaflet
as_leaflet.kleaflet <- function(x, ...) {
  prep <- prepare(x)
  res <- prep$res
  tiles <- prep$tiles

  map <- add_tiles(leaflet::leaflet(), tiles)
  for (r in res) {
    for (cl in layer_calls(r)) map <- do.call(cl$fun, c(list(map), cl$args))
  }
  map <- add_legends(map, prep$scales, prep$titles, x$legend)
  map <- add_layers_control(map, res, tiles)
  map <- add_view(map, res, x$view)
  map <- add_map_titles(map, x$labels)
  map <- add_theme_css(map, prep$style)
  if (isTRUE(x$scale_bar)) map <- leaflet::addScaleBar(map)
  if (isTRUE(x$minimap)) map <- leaflet::addMiniMap(map)

  for (e in x$extras) map <- e(map)
  map
}

# Resolve the layers and the settings shared by all of them: colour scales
# (colours replace the mapped values), legend titles and base maps
prepare <- function(x) {
  res <- lapply(x$layers, resolve_layer)
  theme <- resolve_theme(x$theme)
  pal <- resolve_palette(x$palette %||% theme$palette)
  scales <- build_scales(res, pal, x$scale, x$bins)
  list(
    res = lapply(res, colorize, scales = scales), scales = scales,
    titles = build_titles(res, x$labels),
    tiles = resolve_tiles(x$tiles %||% theme$tiles), style = theme$style
  )
}

add_tiles <- function(map, tiles) {
  for (tl in tiles) {
    map <- if (tl == "OpenStreetMap") {
      leaflet::addTiles(map, group = tl)
    } else {
      leaflet::addProviderTiles(map, tl, group = tl)
    }
  }
  map
}

# A layers control as soon as there are groups or several base maps
add_layers_control <- function(map, res, tiles) {
  groups <- unique(unlist(lapply(res, function(r) r$group)))
  base <- if (length(tiles) > 1L) tiles else character()
  if (!length(groups) && !length(base)) return(map)
  leaflet::addLayersControl(
    map, baseGroups = base, overlayGroups = groups,
    options = leaflet::layersControlOptions(collapsed = length(groups) > 6L)
  )
}

# Bounding box c(lon1, lat1, lon2, lat2) of the layers
data_bounds <- function(res) {
  boxes <- lapply(res, function(r) {
    if (is.null(r$geo)) {
      c(range(r$lng), range(r$lat))[c(1L, 3L, 2L, 4L)]
    } else {
      unname(as.numeric(sf::st_bbox(r$geo)))
    }
  })
  boxes <- do.call(rbind, boxes)
  c(min(boxes[, 1L]), min(boxes[, 2L]), max(boxes[, 3L]), max(boxes[, 4L]))
}

add_view <- function(map, res, view) {
  if (is.null(view)) view <- data_bounds(res)
  if (!is.numeric(view) || !length(view) %in% c(3L, 4L)) {
    stop("`view` must be c(lon, lat, zoom) or c(lon1, lat1, lon2, lat2).",
         call. = FALSE)
  }
  if (length(view) == 3L) {
    return(leaflet::setView(map, view[1L], view[2L], view[3L]))
  }
  if (view[1L] == view[3L] && view[2L] == view[4L]) {
    return(leaflet::setView(map, view[1L], view[2L], zoom = 12))
  }
  leaflet::fitBounds(map, view[1L], view[2L], view[3L], view[4L])
}

# Title and caption as map controls
add_map_titles <- function(map, labels) {
  box <- function(text, size, weight, class) {
    htmltools::tags$div(
      class = class,
      style = paste0(
        "background:rgba(255,255,255,.85);padding:4px 10px;",
        "border-radius:4px;font-size:", size, ";font-weight:", weight
      ),
      text
    )
  }
  title <- labels$title
  if (length(title) == 1L && !is.na(title)) {
    map <- leaflet::addControl(
      map, box(title, "16px", "bold", "kleaf-title"), position = "topright"
    )
  }
  caption <- labels$caption
  if (length(caption) == 1L && !is.na(caption)) {
    map <- leaflet::addControl(
      map, box(caption, "11px", "normal", "kleaf-caption"),
      position = "bottomleft"
    )
  }
  map
}

#' Save a kleaflet to an HTML file
#'
#' Thin wrapper around [htmlwidgets::saveWidget()] that accepts a
#' `kleaflet`.
#'
#' @param p A `kleaflet` or `leaflet` map.
#' @param file File to save to (`.html`).
#' @param selfcontained Whether to embed everything in the file (needs
#'   pandoc).
#' @param ... Passed to [htmlwidgets::saveWidget()].
#'
#' @return The file name, invisibly.
#'
#' @export
kleaf_save <- function(p, file, selfcontained = TRUE, ...) {
  htmlwidgets::saveWidget(
    as_leaflet(p), file = file, selfcontained = selfcontained, ...
  )
  invisible(file)
}

# Colours and fonts of the theme, as a style sheet added to the page
add_theme_css <- function(map, style) {
  css <- theme_css(style)
  if (is.null(css)) return(map)
  htmlwidgets::prependContent(map, htmltools::tags$style(htmltools::HTML(css)))
}
