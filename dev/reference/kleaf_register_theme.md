# Themes and palettes

A kleaflet *theme* bundles base map tiles, (optionally) a colour palette
and a *style* (colours and fonts of the legend, the title, the popups
and the controls) under one name, so `kleaflet(..., theme = "inrae")`
styles the whole map. Register your own with `kleaf_register_theme()`
and `kleaf_register_palette()`.

## Usage

``` r
kleaf_register_theme(name, tiles = NULL, palette = NULL, style = NULL)

kleaf_register_palette(name, colors, continuous = NULL)

kleaf_themes()

kleaf_palettes()
```

## Arguments

- name:

  Name of the theme or palette.

- tiles:

  Base map(s) of the theme: names of
  [leaflet::providers](https://rstudio.github.io/leaflet/reference/providers.html),
  or `"OpenStreetMap"` for the default tiles. Several tiles give a base
  map switcher. `NULL` for the default tiles.

- palette:

  Colours of the theme: a vector of colours, the name of a registered
  palette, or `NULL`.

- style:

  Named list of colours and fonts for the interface of the map: `accent`
  (title bar, popup and legend border), `text`, `background`, `font` and
  `title_font`. Missing entries keep the leaflet look. `NULL` for the
  default style.

- colors:

  Character vector of colours (or a function of `n`).

- continuous:

  Colours of the continuous scale (numeric `color` / `fill`) used with
  this palette: a vector of colours or the name of a registered palette.
  Default: `colors`.

## Value

`kleaf_register_*()` return `name` invisibly; `kleaf_themes()` and
`kleaf_palettes()` return the registered names.

## Details

A `theme` argument accepted by
[`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md)
can be a registered name, or the name of any provider of
[leaflet::providers](https://rstudio.github.io/leaflet/reference/providers.html)
(`theme = "Esri.WorldTopoMap"`). Built-in themes: `default`
(OpenStreetMap), `light`/`minimal`, `dark`, `voyager`, `satellite`,
`topo`, `inrae`. Set `options(kleaflet.theme = )` and
`options(kleaflet.palette = )` to change the defaults session-wide.

## The INRAE theme

`theme = "inrae"` follows the INRAE graphic charter v4.2: light base
map, legend, title, popups and layers control in the institutional
colours (turquoise accent, grey text), and the INRAE palettes for
`color` and `fill`: `"inrae"` for discrete values and `"inrae_seq"` for
numbers (`"inrae_div"` is a diverging variant, to use with `palette =`).
The charter sets Raleway for titles and Avenir Next Pro Condensed for
the text. They are proprietary or need to be installed, so no font is
forced: set `options(kleaflet.title_family = "Raleway")` and
`options(kleaflet.base_family = "Avenir Next Condensed")`. The same
options apply to every theme.

A `palette` is: a vector of colours (named to fix the colour of each
level), the name of a registered palette (`kleaf_palettes()`), the name
of an 'RColorBrewer' or viridis palette (`"Blues"`, `"viridis"`...), or
a function of `n`. Discrete scales take the first colours of a vector
(or interpolate if there are not enough); continuous scales interpolate
between them.

## Examples

``` r
kleaf_themes()
#> [1] "default"   "light"     "minimal"   "voyager"   "dark"      "satellite"
#> [7] "topo"      "inrae"    
kleaf_register_palette("traffic", c("#2ecc71", "#f1c40f", "#e74c3c"))
kleaf_register_theme("traffic", tiles = "CartoDB.Positron",
                     palette = "traffic")
kleaflet(quakes, color = "mag", theme = "traffic")
```
