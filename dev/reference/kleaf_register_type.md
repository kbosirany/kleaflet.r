# Layer types

A *type* maps a short name (`"circle"`, `"polygon"`, ...) to a leaflet
function plus default parameters and the leaflet arguments each
aesthetic drives. Types live in a registry, so you can add your own with
`kleaf_register_type()`.

## Usage

``` r
kleaf_register_type(
  name,
  fun,
  geometry = c("point", "line", "polygon"),
  aes = character(),
  params = list(),
  fill_follows_colour = FALSE,
  size_range = c(3, 15)
)

kleaf_types()
```

## Arguments

- name:

  Name of the type.

- fun:

  A leaflet function adding a layer, e.g. leaflet::addCircleMarkers, or
  its name. It is called with the map first and, for points, `lng` and
  `lat` (for spatial `sf` data, `data`).

- geometry:

  Geometry the function draws: `"point"`, `"line"` or `"polygon"`.
  Points are drawn at the centroid of other geometries.

- aes:

  Named character vector: for each aesthetic the type understands (among
  `colour`, `fill`, `size`, `opacity`), the name of the argument of
  `fun` it sets, e.g. `c(colour = "color", size = "radius")`.

- params:

  Default arguments passed to `fun`.

- fill_follows_colour:

  If `TRUE`, `fill` takes the value of `color` when it is not given.

- size_range:

  Range of the values `size` is rescaled to when mapped to a numeric
  column.

## Value

`kleaf_register_type()` returns `name` invisibly; `kleaf_types()` a
character vector of the registered types.

## Details

Built-in types:

- `circle`: circle markers (default for points);

- `circle_m`: circles with a radius in metres;

- `marker`: standard pins (no colour, but popups and labels);

- `cluster`: pins grouped in clusters;

- `polygon`: polygons, e.g. choropleth maps (default for polygons);

- `line`: lines (default for lines).

## Examples

``` r
kleaf_types()
#> [1] "circle"   "circle_m" "marker"   "cluster"  "polygon"  "line"    
kleaf_register_type(
  "big_dot", "addCircleMarkers",
  aes = c(colour = "color"),
  params = list(radius = 12, fillOpacity = 0.9)
)
kleaflet(quakes, color = "mag", type = "big_dot")
```
