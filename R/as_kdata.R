#' Convert an input object to a data frame (or sf) for kleaflet
#'
#' `as_kdata()` is the S3 entry point that turns whatever you hand to
#' [kleaflet()] into a data frame, or an `sf` object in longitude/latitude
#' (WGS84). Add a method to teach kleaflet a new input class. A method may
#' set the attributes `kleaf_lon`, `kleaf_lat` (default coordinate columns)
#' and `kleaf_type` (default layer type) on the result; they are only used
#' when the call does not specify `lon`, `lat` or `type`.
#'
#' Built-in methods: `data.frame` (and tibbles), `sf` (reprojected to WGS84),
#' `sfc`, two-column `matrix` (longitude, latitude), `list` of equal-length
#' vectors.
#'
#' @param x Object to convert.
#' @param ... Unused, for method extensions.
#'
#' @return A data frame or an `sf` object.
#'
#' @examples
#' as_kdata(matrix(c(2.35, 48.85, -0.12, 51.5), ncol = 2, byrow = TRUE))
#' as_kdata(list(lon = c(2.35, -0.12), lat = c(48.85, 51.5)))
#'
#' @export
as_kdata <- function(x, ...) {
  UseMethod("as_kdata")
}

#' @export
#' @rdname as_kdata
as_kdata.data.frame <- function(x, ...) {
  if (ncol(x) == 0L) stop("`data` has no column.", call. = FALSE)
  as.data.frame(x)
}

#' @export
#' @rdname as_kdata
as_kdata.sf <- function(x, ...) {
  check_sf()
  if (is.na(sf::st_crs(x))) {
    message("`data` has no CRS: assuming longitude/latitude (EPSG:4326).")
    sf::st_crs(x) <- 4326
  } else if (sf::st_crs(x) != sf::st_crs(4326)) {
    x <- sf::st_transform(x, 4326)
  }
  x
}

#' @export
#' @rdname as_kdata
as_kdata.sfc <- function(x, ...) {
  check_sf()
  as_kdata.sf(sf::st_sf(geometry = x))
}

#' @export
#' @rdname as_kdata
as_kdata.matrix <- function(x, ...) {
  if (is.null(colnames(x))) {
    if (ncol(x) != 2L) {
      stop(
        "An unnamed matrix given to kleaflet() must have two columns ",
        "(longitude, latitude).",
        call. = FALSE
      )
    }
    colnames(x) <- c("lon", "lat")
  }
  as_kdata.data.frame(as.data.frame(x, stringsAsFactors = FALSE))
}

#' @export
#' @rdname as_kdata
as_kdata.list <- function(x, ...) {
  if (is.null(names(x)) || !all(nzchar(names(x)))) {
    stop("A list given to kleaflet() must be fully named.", call. = FALSE)
  }
  as_kdata.data.frame(as.data.frame(x, stringsAsFactors = FALSE))
}

#' @export
#' @rdname as_kdata
as_kdata.default <- function(x, ...) {
  out <- tryCatch(
    as.data.frame(x),
    error = function(e) {
      stop(
        "Don't know how to map an object of class '", class(x)[1L], "'. ",
        "Define a method as_kdata.", class(x)[1L], "().",
        call. = FALSE
      )
    }
  )
  as_kdata.data.frame(out)
}
