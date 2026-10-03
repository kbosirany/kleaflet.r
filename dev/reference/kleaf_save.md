# Save a kleaflet to an HTML file

Thin wrapper around
[`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html)
that accepts a `kleaflet`.

## Usage

``` r
kleaf_save(p, file, selfcontained = TRUE, ...)
```

## Arguments

- p:

  A `kleaflet` or `leaflet` map.

- file:

  File to save to (`.html`).

- selfcontained:

  Whether to embed everything in the file (needs pandoc).

- ...:

  Passed to
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html).

## Value

The file name, invisibly.
