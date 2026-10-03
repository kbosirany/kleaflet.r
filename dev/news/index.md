# Changelog

## kleaflet.r 0.0.0.9000

- First version: the leaflet counterpart of kggplot.
- [`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md)
  draws a complete map in one call: coordinates (guessed from the column
  names, or `sf` geometries), colours with a palette and a shared
  legend, sizes, opacities, popups and hover labels (columns, `{column}`
  templates, functions), groups with a layers control, base maps, titles
  and view. The result is a `kleaflet` S3 object, turned into a leaflet
  map when printed
  ([`as_leaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/as_leaflet.md)).
- Layer types: `circle`, `circle_m`, `marker`, `cluster`, `polygon`,
  `line`, guessed from the data when omitted.
- Colour scales: continuous, `"bin"` or `"quantile"` for numbers;
  discrete for the rest; named palettes fix the colour of each level.
- Composition: `+` between two `kleaflet` objects (shared colours and
  legend), `kleaflet(p, data)`,
  [`kleaf_add()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  and functions of the map added with `+`. Modifiers:
  [`kleaf_labs()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_theme()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_tiles()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_palette()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_legend()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_view()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_controls()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_modify.md),
  [`kleaf_save()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_save.md).
- INRAE theme (`theme = "inrae"`), following the graphic charter v4.2:
  light base map, and a style (turquoise accent, grey text) for the
  legend, the title, the popups and the layers control.
  [`kleaf_register_theme()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md)
  takes a `style` to build such themes; fonts are set with
  `options(kleaflet.base_family = )` and
  `options(kleaflet.title_family = )`.
- INRAE palettes in `color` and `fill`: `"inrae"` (discrete),
  `"inrae_seq"` (sequential, the default for numbers under the INRAE
  theme) and `"inrae_div"` (diverging).
  [`kleaf_register_palette()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md)
  takes a `continuous` palette used for numeric values.
- [`as_kdata()`](https://kbosirany.github.io/kleaflet.r/dev/reference/as_kdata.md)
  (S3) converts the input: `data.frame`, `sf`, `sfc`, matrix, named
  list.
- Extensible registries:
  [`kleaf_register_type()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_type.md),
  [`kleaf_register_theme()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md),
  [`kleaf_register_palette()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaf_register_theme.md).
  Built-in `"inrae"` theme and palette.
- “Get started” vignette.
