# kleaflet.r 0.0.0.9000

* First version: the leaflet counterpart of kggplot.
* `kleaflet()` draws a complete map in one call: coordinates (guessed from the
  column names, or `sf` geometries), colours with a palette and a shared
  legend, sizes, opacities, popups and hover labels (columns, `{column}`
  templates, functions), groups with a layers control, base maps, titles and
  view. The result is a `kleaflet` S3 object, turned into a leaflet map when
  printed (`as_leaflet()`).
* Layer types: `circle`, `circle_m`, `marker`, `cluster`, `polygon`, `line`,
  guessed from the data when omitted.
* Colour scales: continuous, `"bin"` or `"quantile"` for numbers; discrete
  for the rest; named palettes fix the colour of each level.
* Composition: `+` between two `kleaflet` objects (shared colours and
  legend), `kleaflet(p, data)`, `kleaf_add()`, and functions of the map added
  with `+`. Modifiers: `kleaf_labs()`, `kleaf_theme()`, `kleaf_tiles()`,
  `kleaf_palette()`, `kleaf_legend()`, `kleaf_view()`, `kleaf_controls()`,
  `kleaf_save()`.
* INRAE theme (`theme = "inrae"`), following the graphic charter v4.2: light
  base map, and a style (turquoise accent, grey text) for the legend, the
  title, the popups and the layers control. `kleaf_register_theme()` takes a
  `style` to build such themes; fonts are set with
  `options(kleaflet.base_family = )` and `options(kleaflet.title_family = )`.
* INRAE palettes in `color` and `fill`: `"inrae"` (discrete),
  `"inrae_seq"` (sequential, the default for numbers under the INRAE theme)
  and `"inrae_div"` (diverging). `kleaf_register_palette()` takes a
  `continuous` palette used for numeric values.
* `as_kdata()` (S3) converts the input: `data.frame`, `sf`, `sfc`, matrix,
  named list.
* Extensible registries: `kleaf_register_type()`, `kleaf_register_theme()`,
  `kleaf_register_palette()`. Built-in `"inrae"` theme and palette.
* "Get started" vignette.
