#' Themes and palettes
#'
#' A kleaflet *theme* bundles base map tiles and (optionally) a colour
#' palette under one name, so `kleaflet(..., theme = "inrae")` styles the
#' whole map. Register your own with `kleaf_register_theme()` and
#' `kleaf_register_palette()`.
#'
#' A `theme` argument accepted by [kleaflet()] can be a registered name, or
#' the name of any provider of [leaflet::providers] (`theme =
#' "Esri.WorldTopoMap"`). Built-in themes: `default` (OpenStreetMap),
#' `light`/`minimal`, `dark`, `voyager`, `satellite`, `topo`, `inrae`.
#' Set `options(kleaflet.theme = )` and `options(kleaflet.palette = )` to
#' change the defaults session-wide.
#'
#' A `palette` is: a vector of colours (named to fix the colour of each
#' level), the name of a registered palette ([kleaf_palettes()]), the name
#' of an 'RColorBrewer' or viridis palette (`"Blues"`, `"viridis"`...), or a
#' function of `n`. Discrete scales take the first colours of a vector (or
#' interpolate if there are not enough); continuous scales interpolate
#' between them.
#'
#' @param name Name of the theme or palette.
#' @param tiles Base map(s) of the theme: names of [leaflet::providers], or
#'   `"OpenStreetMap"` for the default tiles. Several tiles give a base map
#'   switcher. `NULL` for the default tiles.
#' @param palette Colours of the theme: a vector of colours, the name of a
#'   registered palette, or `NULL`.
#' @param colors Character vector of colours (or a function of `n`).
#'
#' @return `kleaf_register_*()` return `name` invisibly; `kleaf_themes()` and
#'   `kleaf_palettes()` return the registered names.
#'
#' @examples
#' kleaf_themes()
#' kleaf_register_palette("traffic", c("#2ecc71", "#f1c40f", "#e74c3c"))
#' kleaf_register_theme("traffic", tiles = "CartoDB.Positron",
#'                      palette = "traffic")
#' kleaflet(quakes, color = "mag", theme = "traffic")
#'
#' @export
kleaf_register_theme <- function(name, tiles = NULL, palette = NULL) {
  stopifnot(is.character(name), length(name) == 1L)
  if (!is.null(tiles) && !is.character(tiles)) {
    stop("`tiles` must be a character vector or NULL.", call. = FALSE)
  }
  .kleaf$themes[[name]] <- list(tiles = tiles, palette = palette)
  invisible(name)
}

#' @export
#' @rdname kleaf_register_theme
kleaf_register_palette <- function(name, colors) {
  stopifnot(is.character(name), length(name) == 1L)
  stopifnot(is.character(colors) || is.function(colors))
  .kleaf$palettes[[name]] <- colors
  invisible(name)
}

#' @export
#' @rdname kleaf_register_theme
kleaf_themes <- function() names(.kleaf$themes)

#' @export
#' @rdname kleaf_register_theme
kleaf_palettes <- function() names(.kleaf$palettes)

register_builtin_palettes <- function() {
  kleaf_register_palette(
    "inrae",
    c("#00a3a6", "#9dc544", "#423089", "#ed6e6c", "#c4c0b3", "#9ed6e3",
      "#797870")
  )
  kleaf_register_palette(
    "okabe_ito",
    c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00",
      "#CC79A7", "#999999")
  )
}

register_builtin_themes <- function() {
  kleaf_register_theme("default", tiles = "OpenStreetMap")
  kleaf_register_theme("light", tiles = "CartoDB.Positron")
  kleaf_register_theme("minimal", tiles = "CartoDB.Positron")
  kleaf_register_theme("voyager", tiles = "CartoDB.Voyager")
  kleaf_register_theme("dark", tiles = "CartoDB.DarkMatter")
  kleaf_register_theme("satellite", tiles = "Esri.WorldImagery")
  kleaf_register_theme("topo", tiles = "OpenTopoMap")
  # Colours of the INRAE graphic charter v4.2 (same palette as kggplot)
  kleaf_register_theme("inrae", tiles = "CartoDB.Positron", palette = "inrae")
}

# Names of the base maps known by leaflet; NULL if they cannot be listed
known_providers <- function() {
  tryCatch(names(leaflet::providers), error = function(e) NULL)
}

# Resolve `theme` to list(tiles = <character>, palette = <colors or NULL>)
resolve_theme <- function(theme = NULL) {
  theme <- theme %||% getOption("kleaflet.theme")
  if (is.null(theme)) return(list(tiles = NULL, palette = NULL))
  if (!is.character(theme) || length(theme) != 1L) {
    stop("`theme` must be a theme name.", call. = FALSE)
  }
  entry <- .kleaf$themes[[theme]]
  if (is.null(entry)) {
    prov <- known_providers()
    if (is.null(prov) || !theme %in% prov) {
      stop(
        "Unknown theme '", theme, "'. Registered: ",
        paste(kleaf_themes(), collapse = ", "),
        "; any name of leaflet::providers also works.",
        call. = FALSE
      )
    }
    entry <- list(tiles = theme, palette = NULL)
  }
  entry
}

# Normalise the base maps: character vector of tile names (empty = none)
resolve_tiles <- function(tiles) {
  if (is.null(tiles)) return("OpenStreetMap")
  if (isFALSE(tiles)) return(character())
  if (!is.character(tiles)) {
    stop("`tiles` must be provider names, or FALSE for no base map.",
         call. = FALSE)
  }
  prov <- known_providers()
  bad <- setdiff(tiles, c("OpenStreetMap", prov))
  if (!is.null(prov) && length(bad)) {
    stop(
      "Unknown tiles: ", paste(bad, collapse = ", "),
      ". See names(leaflet::providers).",
      call. = FALSE
    )
  }
  unique(tiles)
}

# Resolve a palette spec to a character vector, a function, a palette name
# (left to leaflet) or NULL
resolve_palette <- function(palette) {
  palette <- palette %||% getOption("kleaflet.palette")
  if (is.null(palette) || is.function(palette)) return(palette)
  if (!is.character(palette)) {
    stop(
      "`palette` must be colours, a palette name or a function.",
      call. = FALSE
    )
  }
  is_name <- length(palette) == 1L && is.null(names(palette))
  if (is_name && !is.null(.kleaf$palettes[[palette]])) {
    return(.kleaf$palettes[[palette]])
  }
  palette
}

# Colours (exactly one per level) or a palette name for a discrete scale
discrete_palette <- function(pal, levels) {
  n <- length(levels)
  pal <- pal %||% .kleaf$palettes[["okabe_ito"]]
  if (is.function(pal)) return(pal(n))
  if (!is.null(names(pal))) {
    missing <- setdiff(levels, names(pal))
    if (length(missing)) {
      stop(
        "`palette` has no colour for: ", paste(missing, collapse = ", "), ".",
        call. = FALSE
      )
    }
    return(unname(pal[levels]))
  }
  # a brewer or viridis name is left to leaflet
  if (length(pal) == 1L && !is_color(pal)) return(pal)
  if (n <= length(pal)) return(pal[seq_len(n)])
  grDevices::colorRampPalette(pal)(n)
}

# Palette of a continuous scale: leaflet interpolates colours and knows
# the palette names
continuous_palette <- function(pal) {
  if (is.null(pal)) return("viridis")
  if (is.function(pal)) return(pal(7L))
  unname(pal)
}
