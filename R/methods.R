#' @export
print.kleaflet <- function(x, ...) {
  print(as_leaflet(x), ...)
  invisible(x)
}

#' @export
plot.kleaflet <- function(x, ...) {
  print(as_leaflet(x), ...)
  invisible(x)
}

#' @exportS3Method knitr::knit_print
knit_print.kleaflet <- function(x, ...) {
  knitr::knit_print(as_leaflet(x), ...)
}

#' Add layers or leaflet steps to a kleaflet
#'
#' * `kleaflet + kleaflet`: appends the layers of the right-hand map; its
#'   theme, titles, legend, palette and view override the left ones when
#'   specified.
#' * `kleaflet + <function>`: a function of the leaflet map returning a map
#'   (e.g. `function(m) leaflet::addScaleBar(m)`), stored and applied last,
#'   in order.
#'
#' @param e1 A `kleaflet`.
#' @param e2 A `kleaflet` or a function of a leaflet map.
#'
#' @return A `kleaflet`.
#'
#' @examples
#' p <- kleaflet(quakes, color = "mag")
#' p + function(m) leaflet::addScaleBar(m)
#'
#' @export
`+.kleaflet` <- function(e1, e2) {
  if (missing(e2)) stop("Cannot use `+` with a single argument.", call. = FALSE)
  if (!inherits(e1, "kleaflet")) {
    stop("The left-hand side of `+` must be a kleaflet.", call. = FALSE)
  }
  if (inherits(e2, "kleaflet")) return(merge_kleaflet(e1, e2))
  if (!is.function(e2)) {
    stop("Add a kleaflet or a function of the map to a kleaflet.",
         call. = FALSE)
  }
  e1$extras <- c(e1$extras, list(e2))
  e1
}
