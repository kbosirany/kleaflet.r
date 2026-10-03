# Colour scales are shared across layers: a level (or a value) has the same
# colour whatever layer it comes from, and one legend covers them all.

make_scale <- function(vals, pal, scale, bins) {
  if (all(vapply(vals, is.numeric, logical(1)))) {
    all <- unlist(vals, use.names = FALSE)
    rng <- range(all, na.rm = TRUE, finite = TRUE)
    if (!all(is.finite(rng))) {
      stop("Can't build a colour scale: no finite value.", call. = FALSE)
    }
    cols <- continuous_palette(pal)
    f <- switch(
      scale,
      numeric = leaflet::colorNumeric(cols, domain = rng),
      bin = leaflet::colorBin(cols, domain = rng, bins = bins %||% 5L),
      quantile = leaflet::colorQuantile(cols, domain = all, n = bins %||% 5L)
    )
    return(list(
      pal = f, kind = "numeric", values = if (scale == "quantile") all else rng
    ))
  }
  lv <- unique(unlist(lapply(
    vals, function(v) if (is.factor(v)) levels(v) else unique(as.character(v))
  )))
  lv <- lv[!is.na(lv)]
  f <- leaflet::colorFactor(discrete_palette(pal, lv), domain = lv)
  list(pal = f, kind = "factor", values = lv)
}

build_scales <- function(res, pal, scale = NULL, bins = NULL) {
  scale <- match.arg(scale %||% "numeric", c("numeric", "bin", "quantile"))
  out <- list()
  for (a in legend_aes) {
    vals <- Filter(Negate(is.null), lapply(res, function(r) r$vals[[a]]))
    if (length(vals)) out[[a]] <- make_scale(vals, pal, scale, bins)
  }
  # fill identical to colour everywhere: one scale, one legend
  same <- all(vapply(res, function(r) {
    is.null(r$vals$fill) || identical(r$vals$fill, r$vals$colour)
  }, logical(1)))
  if (!is.null(out$fill) && !is.null(out$colour) && same) {
    out$fill <- NULL
    out$fill_shared <- TRUE
  }
  out
}

# Replace the values of colour and fill by colours
colorize <- function(r, scales) {
  for (a in legend_aes) {
    if (is.null(r$vals[[a]])) next
    sc <- if (a == "fill" && isTRUE(scales$fill_shared)) {
      scales$colour
    } else {
      scales[[a]]
    }
    v <- r$vals[[a]]
    r$vals[[a]] <- sc$pal(if (sc$kind == "factor") as.character(v) else v)
  }
  r
}

# Legend titles: from the layers (first one wins), then user titles. NA is
# "no title".
merge_labels <- function(acc, new) {
  for (a in names(new)) {
    if (is.null(acc[[a]]) || is.na(acc[[a]])) acc[[a]] <- new[[a]]
  }
  acc
}

build_titles <- function(res, explicit) {
  lab <- Reduce(merge_labels, lapply(res, function(r) r$labels), list())
  utils::modifyList(lab, explicit)
}

legend_position <- function(legend) {
  if (is.null(legend) || isTRUE(legend)) return("bottomright")
  if (isFALSE(legend)) return(NULL)
  if (!is.character(legend) || length(legend) != 1L) {
    stop("`legend` must be a position, or FALSE/\"none\".", call. = FALSE)
  }
  if (legend == "none") return(NULL)
  match.arg(legend, c("topright", "bottomright", "bottomleft", "topleft"))
}

legend_title <- function(a, titles, scales) {
  title <- titles[[a]]
  if (a == "colour" && isTRUE(scales$fill_shared) &&
        (is.null(title) || is.na(title))) {
    title <- titles$fill
  }
  if (length(title) != 1L || is.na(title)) NULL else title
}

add_legends <- function(map, scales, titles, legend) {
  pos <- legend_position(legend)
  if (is.null(pos)) return(map)
  for (a in legend_aes) {
    sc <- scales[[a]]
    if (is.null(sc)) next
    map <- leaflet::addLegend(
      map, position = pos, pal = sc$pal, values = sc$values,
      title = legend_title(a, titles, scales), opacity = 1
    )
  }
  map
}
