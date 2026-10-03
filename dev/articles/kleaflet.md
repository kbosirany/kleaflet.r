# Get started with kleaflet.r

A leaflet map with a palette, a legend and popups normally needs a pile
of `addX()` calls, `~column` formulas and `color*()` helpers.
[`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md)
does the bookkeeping from a single call, and returns a `kleaflet` object
that you can compose, modify, or turn into a regular leaflet map.

## Input data

[`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md)
takes a data frame with longitude and latitude columns (guessed from
names such as `lon`, `lng`, `long`, `longitude`, `lat`, `latitude`; or
given with `lon` and `lat`), an `sf` object (reprojected to WGS84), a
two-column matrix or a named list.

``` r

kleaflet(quakes)
```

``` r

kleaflet(data.frame(x = c(2.35, 2.4), y = c(48.85, 48.87)),
         lon = "x", lat = "y")
```

## Colours, sizes and legends

A column given to `color` is coloured with a palette: a continuous scale
for numbers, a discrete one otherwise. The legend and its title come for
free. `size` and `opacity` rescale a numeric column to a readable range.

``` r

kleaflet(quakes, color = "mag", size = "depth", opacity = "stations",
         size_range = c(2, 12))
```

Numeric colours can be cut in classes with `scale = "bin"` or
`"quantile"`, and `bins`:

``` r

kleaflet(quakes, color = "mag", palette = "YlOrRd", scale = "quantile",
         bins = 4, labels = list(color = "Magnitude"))
```

A palette is a vector of colours (named to fix the colour of each
level), a registered name
([`kleaf_palettes()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md)),
the name of an RColorBrewer or viridis palette, or a function of `n`.

``` r

q <- quakes
q$class <- cut(q$mag, c(4, 5, 6, 7), labels = c("low", "mid", "high"))
kleaflet(q, color = "class",
         palette = c(low = "#2ecc71", mid = "#f1c40f", high = "#e74c3c"))
```

Fixed values are not mappings: wrap colours in
[`I()`](https://rdrr.io/r/base/AsIs.html), or give numbers.

``` r

kleaflet(quakes, color = I("tomato"), size = 3, opacity = 0.4)
```

## Popups and labels

`popup` (on click) and `label` (on hover) accept `TRUE` (all columns),
column names, a template with `{column}`, a function of the data
returning HTML, or one string per row. Values are HTML-escaped.

``` r

kleaflet(q, color = "class",
         popup = "<b>Magnitude {mag}</b><br>Depth: {depth} km",
         label = "{class}")
```

``` r

kleaflet(q, color = "class", popup = c("mag", "depth", "stations"))
```

## Spatial data

With `sf` data the layer type follows the geometry: polygons, lines or
circles. Choropleth maps are one call away.

``` r

nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
kleaflet(nc, fill = "SID74", palette = "YlOrRd", scale = "bin", bins = 5,
         popup = "<b>{NAME}</b><br>{SID74} cases", theme = "light",
         labels = list(fill = "SID74 (1974)"))
```

## Groups

`group` splits a layer in one overlay per value, with a layers control.

``` r

kleaflet(q, color = "class", group = "class")
```

## Layer types

[`kleaf_types()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_type.md)
lists them: `circle` (default for points), `circle_m` (radius in
metres), `marker`, `cluster`, `polygon`, `line`.

``` r

kleaf_types()
#> [1] "circle"   "circle_m" "marker"   "cluster"  "polygon"  "line"
kleaflet(quakes, type = "cluster", popup = "mag")
```

## Themes: base map and palette

A theme bundles base map tiles and a palette. `tiles` overrides the base
map (several give a switcher), `theme` can also be the name of any
provider of
[`leaflet::providers`](https://rstudio.github.io/leaflet/reference/providers.html).

``` r

kleaf_themes()
#> [1] "default"   "light"     "minimal"   "voyager"   "dark"      "satellite"
#> [7] "topo"      "inrae"
kleaflet(q, color = "class", theme = "inrae", title = "Fiji earthquakes",
         caption = "Source: datasets::quakes")
```

``` r

kleaflet(q, tiles = c("CartoDB.Positron", "Esri.WorldImagery"))
```

Add your own with
[`kleaf_register_theme()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md)
and
[`kleaf_register_palette()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md);
`options(kleaflet.theme = "inrae")` sets a session default.

### The INRAE theme

`theme = "inrae"` follows the INRAE graphic charter: a light base map,
and the institutional colours (turquoise accent, grey text) on the
legend, the title, the popups and the layers control. The palette
applies to `color` and `fill` alike: the discrete INRAE palette for
classes, the sequential `"inrae_seq"` for numbers. `"inrae_div"` is a
diverging variant, to be asked for with `palette = "inrae_div"`.

``` r

kleaflet(q, color = "class", theme = "inrae", title = "Fiji earthquakes")
```

``` r

kleaflet(q, fill = "depth", color = I("white"), theme = "inrae",
         popup = c("mag", "depth"), title = "Depth")
```

The charter sets Raleway for titles and Avenir Next Pro Condensed for
the text. They are not forced, since they need to be installed: set
`options(kleaflet.title_family = "Raleway")` and
`options(kleaflet.base_family = "Avenir Next Condensed")`.

A theme of your own is a base map, a palette and a style:

``` r

kleaf_register_theme(
  "forest", tiles = "CartoDB.Voyager", palette = c("#2d6a4f", "#95d5b2"),
  style = list(accent = "#2d6a4f", text = "#1b4332", background = "#f1faee")
)
kleaflet(q, color = "class", theme = "forest", title = "Forest theme")
```

## Composing maps

`+` adds the layers of another `kleaflet`; colours and legends are
shared. Settings of the right-hand side (theme, titles, view…) win.

``` r

a <- data.frame(lon = c(2.35, 2.40), lat = c(48.85, 48.87))
b <- data.frame(lon = c(2.30, 2.33), lat = c(48.84, 48.88))
kleaflet(a, color = "Stations") + kleaflet(b, color = "Sensors")
```

Pipe-friendly modifiers return a modified `kleaflet`:
[`kleaf_add()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
[`kleaf_labs()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
[`kleaf_theme()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
[`kleaf_tiles()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
[`kleaf_palette()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
[`kleaf_legend()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
[`kleaf_view()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md)
and
[`kleaf_controls()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md).

``` r

kleaflet(q, color = "mag") |>
  kleaf_add(type = "marker", popup = "mag") |>
  kleaf_labs(title = "Fiji", color = "Magnitude") |>
  kleaf_palette("Reds", scale = "bin", bins = 4) |>
  kleaf_legend("bottomleft") |>
  kleaf_view(c(176, -20, 5)) |>
  kleaf_controls(scale_bar = TRUE, minimap = TRUE)
#> Warning: Layer type 'marker' ignores: colour.
```

A function of the map, added with `+`, runs last: it is the escape hatch
for anything leaflet (or one of its extensions) can do.

``` r

kleaflet(quakes, color = "mag") + (function(m) leaflet::addScaleBar(m))
```

## Going back to leaflet

[`as_leaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/as_leaflet.md)
returns the regular leaflet map, to continue with `|>`, to use in Shiny
(`leaflet::renderLeaflet(as_leaflet(p))`) or to save, with
`kleaf_save(p, "map.html")`.

``` r

as_leaflet(kleaflet(quakes, color = "mag")) |>
  leaflet::addCircleMarkers(lng = 178, lat = -20, radius = 20, color = "red")
```

## Extending kleaflet.r

- **Input classes**: define `as_kdata.<class>()` returning a data frame
  or an `sf` object. It may set the attributes `kleaf_lon`, `kleaf_lat`
  and `kleaf_type` as defaults.
- **Layer types**:
  `kleaf_register_type(name, fun, geometry, aes, params)` says which
  leaflet function to call and which of its arguments each aesthetic
  sets.
- **Themes and palettes**:
  [`kleaf_register_theme()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md)
  and
  [`kleaf_register_palette()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md).

``` r

kleaf_register_type(
  "big_dot", "addCircleMarkers", aes = c(colour = "color"),
  params = list(radius = 12, fillOpacity = 0.9)
)
kleaflet(quakes, color = "mag", type = "big_dot")
```
