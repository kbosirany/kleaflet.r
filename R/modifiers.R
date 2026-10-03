#' Modify a kleaflet
#'
#' Pipe-friendly setters. Each returns a modified `kleaflet`; unspecified
#' arguments are left unchanged.
#'
#' `kleaf_add()` appends a layer. Aesthetics you do not give (`color`,
#' `size`...) are inherited from the first layer when they refer to columns
#' that exist in the new data; `type` is guessed again.
#'
#' @param p A `kleaflet`.
#' @param data Data of the new layer (default: the data of the first layer,
#'   handy for e.g. adding markers over polygons).
#' @param ... For `kleaf_add()`: arguments of [kleaflet()] (aesthetics,
#'   `type`, popups, ...). For `kleaf_labs()`: legend titles such as
#'   `color = "Magnitude"`.
#' @param title,caption Titles. `NA` removes a title.
#' @param theme,palette,scale,bins,legend,view See [kleaflet()].
#' @param tiles Base map(s), see [kleaflet()].
#' @param scale_bar,minimap Add a scale bar / an overview map.
#'
#' @return A `kleaflet`.
#'
#' @examples
#' p <- kleaflet(quakes, color = "mag")
#' p |>
#'   kleaf_add(type = "marker", popup = "mag") |>
#'   kleaf_labs(title = "Fiji", color = "Magnitude") |>
#'   kleaf_theme("light", palette = "Reds") |>
#'   kleaf_legend("bottomleft") |>
#'   kleaf_view(c(176, -20, 7)) |>
#'   kleaf_controls(scale_bar = TRUE)
#'
#' @name kleaf_modify
NULL

#' @export
#' @rdname kleaf_modify
kleaf_add <- function(p, data = NULL, ...) {
  check_kleaflet(p)
  dots <- list(...)
  first <- p$layers[[1L]]
  given <- c(norm_aes_names(names(dots)), names(norm_list(dots$vars)))
  new_src <- if (is.null(data)) first$source else as_kdata(data)
  for (a in setdiff(names(first$mapped), given)) {
    if (all(first$mapped[[a]] %in% data_columns(new_src))) {
      dots[[a]] <- first$mapped[[a]]
    }
  }
  layer_plot <- do.call(kleaflet, c(list(new_src), dots))
  merge_kleaflet(p, layer_plot)
}

#' @export
#' @rdname kleaf_modify
kleaf_labs <- function(p, title = NULL, caption = NULL, ...) {
  check_kleaflet(p)
  new <- norm_list(c(list(title = title, caption = caption), list(...)))
  p$labels <- utils::modifyList(p$labels, new)
  p
}

#' @export
#' @rdname kleaf_modify
kleaf_theme <- function(p, theme, tiles = NULL, palette = NULL) {
  check_kleaflet(p)
  p$theme <- theme
  if (!is.null(tiles)) p$tiles <- tiles
  if (!is.null(palette)) p$palette <- palette
  p
}

#' @export
#' @rdname kleaf_modify
kleaf_tiles <- function(p, tiles) {
  check_kleaflet(p)
  p$tiles <- tiles
  p
}

#' @export
#' @rdname kleaf_modify
kleaf_palette <- function(p, palette, scale = NULL, bins = NULL) {
  check_kleaflet(p)
  p$palette <- palette
  if (!is.null(scale)) {
    p$scale <- match.arg(scale, c("numeric", "bin", "quantile"))
  }
  if (!is.null(bins)) p$bins <- bins
  p
}

#' @export
#' @rdname kleaf_modify
kleaf_legend <- function(p, legend) {
  check_kleaflet(p)
  p$legend <- legend
  p
}

#' @export
#' @rdname kleaf_modify
kleaf_view <- function(p, view) {
  check_kleaflet(p)
  p$view <- view
  p
}

#' @export
#' @rdname kleaf_modify
kleaf_controls <- function(p, scale_bar = NULL, minimap = NULL) {
  check_kleaflet(p)
  if (!is.null(scale_bar)) p$scale_bar <- scale_bar
  if (!is.null(minimap)) p$minimap <- minimap
  p
}

check_kleaflet <- function(p) {
  if (!inherits(p, "kleaflet")) {
    stop("`p` must be a kleaflet object.", call. = FALSE)
  }
}

# Combine two kleaflets: layers are appended, settings given on the right
# override those on the left.
merge_kleaflet <- function(a, b) {
  a$layers <- c(a$layers, b$layers)
  a$labels <- utils::modifyList(a$labels, b$labels)
  for (nm in c("theme", "tiles", "palette", "scale", "bins", "legend", "view",
               "scale_bar", "minimap")) {
    if (!is.null(b[[nm]])) a[[nm]] <- b[[nm]]
  }
  a$extras <- c(a$extras, b$extras)
  a
}
