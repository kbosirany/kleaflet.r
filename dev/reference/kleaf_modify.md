# Modify a kleaflet

Pipe-friendly setters. Each returns a modified `kleaflet`; unspecified
arguments are left unchanged.

## Usage

``` r
kleaf_add(p, data = NULL, ...)

kleaf_labs(p, title = NULL, caption = NULL, ...)

kleaf_theme(p, theme, tiles = NULL, palette = NULL)

kleaf_tiles(p, tiles)

kleaf_palette(p, palette, scale = NULL, bins = NULL)

kleaf_legend(p, legend)

kleaf_view(p, view)

kleaf_controls(p, scale_bar = NULL, minimap = NULL)
```

## Arguments

- p:

  A `kleaflet`.

- data:

  Data of the new layer (default: the data of the first layer, handy for
  e.g. adding markers over polygons).

- ...:

  For `kleaf_add()`: arguments of
  [`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md)
  (aesthetics, `type`, popups, ...). For `kleaf_labs()`: legend titles
  such as `color = "Magnitude"`.

- title, caption:

  Titles. `NA` removes a title.

- theme, palette, scale, bins, legend, view:

  See
  [`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md).

- tiles:

  Base map(s), see
  [`kleaflet()`](https://kbosirany.github.io/kleaflet.r/dev/reference/kleaflet.md).

- scale_bar, minimap:

  Add a scale bar / an overview map.

## Value

A `kleaflet`.

## Details

`kleaf_add()` appends a layer. Aesthetics you do not give (`color`,
`size`...) are inherited from the first layer when they refer to columns
that exist in the new data; `type` is guessed again.

## Examples

``` r
p <- kleaflet(quakes, color = "mag")
p |>
  kleaf_add(type = "marker", popup = "mag") |>
  kleaf_labs(title = "Fiji", color = "Magnitude") |>
  kleaf_theme("light", palette = "Reds") |>
  kleaf_legend("bottomleft") |>
  kleaf_view(c(176, -20, 7)) |>
  kleaf_controls(scale_bar = TRUE)
#> Warning: Layer type 'marker' ignores: colour.
```
