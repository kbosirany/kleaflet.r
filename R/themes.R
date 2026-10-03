#' Themes and palettes
#'
#' A kleaflet *theme* bundles base map tiles, (optionally) a colour palette
#' and a *style* (colours and fonts of the legend, the title, the popups and
#' the controls) under one name, so `kleaflet(..., theme = "inrae")` styles
#' the whole map. Register your own with `kleaf_register_theme()` and
#' `kleaf_register_palette()`.
#'
#' A `theme` argument accepted by [kleaflet()] can be a registered name, or
#' the name of any provider of [leaflet::providers] (`theme =
#' "Esri.WorldTopoMap"`). Built-in themes: `default` (OpenStreetMap),
#' `light`/`minimal`, `dark`, `voyager`, `satellite`, `topo`, `inrae`.
#' Set `options(kleaflet.theme = )` and `options(kleaflet.palette = )` to
#' change the defaults session-wide.
#'
#' @section The INRAE theme:
#' `theme = "inrae"` follows the INRAE graphic charter v4.2: light base map,
#' legend, title, popups and layers control in the institutional colours
#' (turquoise accent, grey text), and the INRAE palettes for `color` and
#' `fill`: `"inrae"` for discrete values and `"inrae_seq"` for numbers
#' (`"inrae_div"` is a diverging variant, to use with `palette =`). The
#' charter sets Raleway for titles and Avenir Next Pro Condensed for the
#' text. They are proprietary or need to be installed, so no font is forced:
#' set `options(kleaflet.title_family = "Raleway")` and
#' `options(kleaflet.base_family = "Avenir Next Condensed")`. The same
#' options apply to every theme.
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
#' @param style Named list of colours and fonts for the interface of the map:
#'   `accent` (title bar, popup and legend border), `text`, `background`,
#'   `font` and `title_font`. Missing entries keep the leaflet look. `NULL`
#'   for the default style.
#' @param colors Character vector of colours (or a function of `n`).
#' @param continuous Colours of the continuous scale (numeric `color` /
#'   `fill`) used with this palette: a vector of colours or the name of a
#'   registered palette. Default: `colors`.
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
kleaf_register_theme <- function(name, tiles = NULL, palette = NULL,
                                 style = NULL) {
  stopifnot(is.character(name), length(name) == 1L)
  if (!is.null(tiles) && !is.character(tiles)) {
    stop("`tiles` must be a character vector or NULL.", call. = FALSE)
  }
  bad <- setdiff(names(style), style_keys)
  if (length(style) && (is.null(names(style)) || length(bad))) {
    stop("Unknown `style` entries: ", paste(bad, collapse = ", "),
         ". Available: ", paste(style_keys, collapse = ", "), ".",
         call. = FALSE)
  }
  .kleaf$themes[[name]] <- list(
    tiles = tiles, palette = palette, style = style
  )
  invisible(name)
}

style_keys <- c("accent", "text", "background", "font", "title_font")

#' @export
#' @rdname kleaf_register_theme
kleaf_register_palette <- function(name, colors, continuous = NULL) {
  stopifnot(is.character(name), length(name) == 1L)
  stopifnot(is.character(colors) || is.function(colors))
  stopifnot(is.null(continuous) || is.character(continuous) ||
              is.function(continuous))
  .kleaf$palettes[[name]] <- list(colors = colors, continuous = continuous)
  invisible(name)
}

#' @export
#' @rdname kleaf_register_theme
kleaf_themes <- function() names(.kleaf$themes)

#' @export
#' @rdname kleaf_register_theme
kleaf_palettes <- function() names(.kleaf$palettes)

register_builtin_palettes <- function() {
  # Colours of the INRAE graphic charter v4.2 (same palette as kggplot). The
  # continuous palettes are tints built from the same colours: light blue to
  # turquoise to violet (sequential), coral to light grey to turquoise
  # (diverging).
  kleaf_register_palette(
    "inrae_seq", c("#cde9eb", "#9ed6e3", "#00a3a6", "#423089")
  )
  kleaf_register_palette("inrae_div", c("#ed6e6c", "#f4f3ef", "#00a3a6"))
  kleaf_register_palette(
    "inrae",
    c("#00a3a6", "#9dc544", "#423089", "#ed6e6c", "#c4c0b3", "#9ed6e3",
      "#797870"),
    continuous = "inrae_seq"
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
  kleaf_register_theme(
    "inrae", tiles = "CartoDB.Positron", palette = "inrae",
    style = list(accent = "#00a3a6", text = "#797870", background = "#ffffff")
  )
}

# Names of the base maps known by leaflet; NULL if they cannot be listed
known_providers <- function() {
  tryCatch(names(leaflet::providers), error = function(e) NULL)
}

# Resolve `theme` to list(tiles = <character>, palette = <colors or NULL>)
resolve_theme <- function(theme = NULL) {
  theme <- theme %||% getOption("kleaflet.theme")
  if (is.null(theme)) {
    return(list(tiles = NULL, palette = NULL, style = NULL))
  }
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
    entry <- list(tiles = theme, palette = NULL, style = NULL)
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

# Entry of a registered palette: list(colors, continuous)
palette_entry <- function(name) .kleaf$palettes[[name]]

# Resolve a palette spec to list(discrete, continuous): each a character
# vector, a function, a palette name (left to leaflet) or NULL
resolve_palette <- function(palette) {
  palette <- palette %||% getOption("kleaflet.palette")
  if (is.null(palette) || is.function(palette)) {
    return(list(discrete = palette, continuous = palette))
  }
  if (!is.character(palette)) {
    stop(
      "`palette` must be colours, a palette name or a function.",
      call. = FALSE
    )
  }
  is_name <- length(palette) == 1L && is.null(names(palette))
  entry <- if (is_name) palette_entry(palette)
  if (is.null(entry)) return(list(discrete = palette, continuous = palette))
  cont <- entry$continuous
  if (is.character(cont) && length(cont) == 1L &&
        !is.null(palette_entry(cont))) {
    cont <- palette_entry(cont)$colors
  }
  list(discrete = entry$colors, continuous = cont %||% entry$colors)
}

# Colours (exactly one per level) or a palette name for a discrete scale
discrete_palette <- function(pal, levels) {
  n <- length(levels)
  pal <- pal %||% palette_entry("okabe_ito")$colors
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

# CSS of the interface of the map. The fonts come from the style of the theme
# or from options(kleaflet.base_family) / options(kleaflet.title_family).
theme_css <- function(style) {
  font <- getOption("kleaflet.base_family") %||% style$font
  title_font <- getOption("kleaflet.title_family") %||% style$title_font %||%
    font
  if (!length(style) && is.null(font) && is.null(title_font)) return(NULL)
  decl <- function(prop, value) {
    if (!is.null(value)) paste0(prop, ": ", value, " !important;")
  }
  family <- function(f) {
    if (!is.null(f)) decl("font-family", paste0("'", f, "', sans-serif"))
  }
  rule <- function(selector, ...) {
    decl <- c(...)
    if (length(decl)) paste0(selector, " { ", paste(decl, collapse = " "), " }")
  }
  accent <- style$accent
  bar <- function(side, width) {
    if (!is.null(accent)) decl(side, paste0(width, " solid ", accent))
  }
  css <- c(
    rule(".info.legend", decl("background", style$background),
         decl("color", style$text), bar("border", "1px"), family(font)),
    rule(".kleaf-title", bar("border-left", "4px"),
         decl("color", accent), family(title_font)),
    rule(".kleaf-caption", decl("color", style$text), family(font)),
    rule(".leaflet-popup-content-wrapper", bar("border-top", "3px"),
         decl("color", style$text), family(font)),
    rule(".leaflet-control-layers", decl("color", style$text), family(font))
  )
  if (length(css)) paste(css, collapse = "\n")
}
