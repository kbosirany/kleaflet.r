# Add layers or leaflet steps to a kleaflet

- `kleaflet + kleaflet`: appends the layers of the right-hand map; its
  theme, titles, legend, palette and view override the left ones when
  specified.

- `kleaflet + <function>`: a function of the leaflet map returning a map
  (e.g. `function(m) leaflet::addScaleBar(m)`), stored and applied last,
  in order.

## Usage

``` r
# S3 method for class 'kleaflet'
e1 + e2
```

## Arguments

- e1:

  A `kleaflet`.

- e2:

  A `kleaflet` or a function of a leaflet map.

## Value

A `kleaflet`.

## Examples

``` r
p <- kleaflet(quakes, color = "mag")
p + function(m) leaflet::addScaleBar(m)
```
