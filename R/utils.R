`%||%` <- function(x, y) if (is.null(x)) y else x

# Constant factor of length n (cheap: no character vector is allocated)
const_factor <- function(label, n) {
  structure(rep.int(1L, n), levels = as.character(label), class = "factor")
}

# Aesthetics understood by kleaflet (US spelling "color" is normalised, and
# "lng" is an alias of "lon")
std_aes <- c("lon", "lat", "colour", "fill", "size", "opacity", "group")

# Aesthetics that get a legend
legend_aes <- c("colour", "fill")

norm_aes_names <- function(nm) {
  if (is.null(nm)) return(nm)
  nm <- sub("^color$", "colour", nm)
  sub("^lng$", "lon", nm)
}

# Normalise a named list: US -> UK spelling, drop NULL entries
norm_list <- function(x) {
  if (!length(x)) return(list())
  names(x) <- norm_aes_names(names(x))
  x[!vapply(x, is.null, logical(1))]
}

# Linear rescaling of a numeric vector to `range` (constant input -> middle)
rescale_to <- function(x, range) {
  r <- base::range(x, na.rm = TRUE, finite = TRUE)
  if (!all(is.finite(r)) || r[1L] == r[2L]) {
    return(ifelse(is.na(x), NA_real_, mean(range)))
  }
  range[1L] + (x - r[1L]) / (r[2L] - r[1L]) * (range[2L] - range[1L])
}

is_color <- function(x) {
  vapply(x, function(v) {
    !is.na(v) && (
      grepl("^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$", v) ||
        v %in% grDevices::colors()
    )
  }, logical(1), USE.NAMES = FALSE)
}

check_sf <- function() {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Spatial (sf) data needs the 'sf' package.", call. = FALSE)
  }
}
