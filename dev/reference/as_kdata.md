# Convert an input object to a data frame (or sf) for kleaflet

`as_kdata()` is the S3 entry point that turns whatever you hand to
[`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md)
into a data frame, or an `sf` object in longitude/latitude (WGS84). Add
a method to teach kleaflet a new input class. A method may set the
attributes `kleaf_lon`, `kleaf_lat` (default coordinate columns) and
`kleaf_type` (default layer type) on the result; they are only used when
the call does not specify `lon`, `lat` or `type`.

## Usage

``` r
as_kdata(x, ...)

# S3 method for class 'data.frame'
as_kdata(x, ...)

# S3 method for class 'sf'
as_kdata(x, ...)

# S3 method for class 'sfc'
as_kdata(x, ...)

# S3 method for class 'matrix'
as_kdata(x, ...)

# S3 method for class 'list'
as_kdata(x, ...)

# Default S3 method
as_kdata(x, ...)
```

## Arguments

- x:

  Object to convert.

- ...:

  Unused, for method extensions.

## Value

A data frame or an `sf` object.

## Details

Built-in methods: `data.frame` (and tibbles), `sf` (reprojected to
WGS84), `sfc`, two-column `matrix` (longitude, latitude), `list` of
equal-length vectors.

## Examples

``` r
as_kdata(matrix(c(2.35, 48.85, -0.12, 51.5), ncol = 2, byrow = TRUE))
#>     lon   lat
#> 1  2.35 48.85
#> 2 -0.12 51.50
as_kdata(list(lon = c(2.35, -0.12), lat = c(48.85, 51.5)))
#>     lon   lat
#> 1  2.35 48.85
#> 2 -0.12 51.50
```
