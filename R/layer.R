# A layer = source data + how to read it. The heavy work (finding the
# coordinates, building popups, standardising columns) is done lazily by
# resolve_layer() when the map is built.

# Decide what a user-supplied aesthetic value means:
#  * column name(s)                     -> "col"   (mapped to data)
#  * other string for colour/fill/group -> "const" (a legend entry, e.g. a
#    layer name such as "Observed", or a group name)
#  * I("red"), numbers, other strings   -> "fixed" (a plain value)
classify_aes <- function(name, value, cols) {
  if (inherits(value, "AsIs")) {
    class(value) <- setdiff(class(value), "AsIs")
    return(list(kind = "fixed", value = value))
  }
  if (is.character(value) || is.factor(value)) {
    return(classify_chr(name, as.character(value), cols))
  }
  if (name %in% c("lon", "lat")) {
    stop("`", name, "` must be a column name of the data.", call. = FALSE)
  }
  list(kind = "fixed", value = value)
}

classify_chr <- function(name, value, cols) {
  if (all(value %in% cols)) {
    return(list(kind = "col", value = value))
  }
  if (name %in% c("lon", "lat")) {
    stop(
      "Column(s) not found in data for `", name, "`: ",
      paste(setdiff(value, cols), collapse = ", "),
      ". Available: ", paste(cols, collapse = ", "), ".",
      call. = FALSE
    )
  }
  if (!name %in% c("colour", "fill", "group")) {
    return(list(kind = "fixed", value = value))
  }
  if (length(value) != 1L) {
    stop("`", name, "` must be a single column or label.", call. = FALSE)
  }
  list(kind = "const", value = value)
}

# Columns of the data, without the geometry of sf objects
data_columns <- function(src) {
  if (!inherits(src, "sf")) return(names(src))
  setdiff(names(src), attr(src, "sf_column"))
}

new_layer <- function(source, args, type = NULL, popup = NULL, label = NULL,
                      size_range = NULL, params = list()) {
  cols <- data_columns(source)
  kinds <- lapply(names(args), function(a) classify_aes(a, args[[a]], cols))
  names(kinds) <- names(args)
  pick <- function(kind) {
    sel <- Filter(function(cl) cl$kind == kind, kinds)
    lapply(sel, function(cl) cl$value)
  }
  if (!is.null(type)) get_type(type) # validate early
  list(
    source = source, mapped = pick("col"), const = pick("const"),
    fixed = pick("fixed"), type = type, popup = popup, label = label,
    size_range = size_range, params = params
  )
}

# Longitude / latitude columns: explicit, else the hints of as_kdata(), else
# guessed from the names
find_lonlat <- function(src, mapped) {
  cols <- names(src)
  guess <- function(explicit, hint, pattern, what) {
    if (!is.null(explicit)) return(explicit[1L])
    if (!is.null(hint)) return(hint)
    hit <- cols[grepl(pattern, cols, ignore.case = TRUE)]
    if (!length(hit)) {
      stop(
        "Can't find the ", what, " column. Use `lon` and `lat` to name the ",
        "coordinate columns, or give an sf object. Columns: ",
        paste(cols, collapse = ", "), ".",
        call. = FALSE
      )
    }
    hit[1L]
  }
  list(
    lon = guess(mapped$lon, attr(src, "kleaf_lon"),
                "^(lon|lng|long|longitude|x)$", "longitude"),
    lat = guess(mapped$lat, attr(src, "kleaf_lat"),
                "^(lat|latitude|y)$", "latitude")
  )
}

# Points of an sf object in the geometry a type draws
sf_for_type <- function(src, spec, type) {
  kind <- geometry_kind(src)
  if (kind == spec$geometry) return(src)
  if (spec$geometry == "point") {
    return(suppressWarnings(sf::st_centroid(src)))
  }
  stop(
    "Layer type '", if (is.character(type)) type else "custom",
    "' draws ", spec$geometry, "s but the data has ", kind, "s.",
    call. = FALSE
  )
}

# Default legend titles; NA means "no title"
layer_labels <- function(layer) {
  lab <- list()
  for (a in intersect(names(layer$mapped), legend_aes)) {
    lab[[a]] <- layer$mapped[[a]]
  }
  for (a in intersect(names(layer$const), legend_aes)) {
    lab[[a]] <- NA_character_
  }
  lab
}

# fill takes the colour of the layer when the type says so
apply_fill_follows <- function(spec, mapped, const, fixed) {
  given <- c(names(mapped), names(const), names(fixed))
  if (spec$fill_follows_colour && !"fill" %in% given) {
    if (!is.null(mapped$colour)) mapped$fill <- mapped$colour
    if (!is.null(const$colour)) const$fill <- const$colour
    if (!is.null(fixed$colour)) fixed$fill <- fixed$colour
  }
  list(mapped = mapped, const = const, fixed = fixed)
}

# Rows with valid coordinates; sf objects are put in the geometry of the type
resolve_geometry <- function(src, spec, type, mapped) {
  type_name <- if (is.character(type)) type else "custom"
  if (inherits(src, "sf")) {
    src <- sf_for_type(src, spec, type)
    return(list(src = src, ok = !sf::st_is_empty(src), lng = NULL, lat = NULL))
  }
  if (spec$geometry != "point") {
    stop("Layer type '", type_name, "' needs spatial data: give an sf object.",
         call. = FALSE)
  }
  xy <- find_lonlat(src, mapped)
  lng <- suppressWarnings(as.numeric(src[[xy$lon]]))
  lat <- suppressWarnings(as.numeric(src[[xy$lat]]))
  ok <- is.finite(lng) & is.finite(lat) & abs(lat) <= 90 & abs(lng) <= 360
  list(src = src, ok = ok, lng = lng, lat = lat)
}

# Sizes and opacities: columns become numbers in a range
scale_numeric_aes <- function(vals, fixed, layer, spec) {
  if (!is.null(vals$size)) {
    if (!is.numeric(vals$size)) {
      stop("A mapped `size` must be a numeric column.", call. = FALSE)
    }
    vals$size <- rescale_to(vals$size, layer$size_range %||% spec$size_range)
  }
  if (!is.null(vals$opacity)) {
    if (!is.numeric(vals$opacity)) {
      stop("A mapped `opacity` must be a numeric column.", call. = FALSE)
    }
    vals$opacity <- rescale_to(vals$opacity, c(0.2, 1))
  }
  for (a in intersect(c("size", "opacity"), names(fixed))) {
    if (!is.numeric(fixed[[a]])) {
      stop("A fixed `", a, "` must be a number.", call. = FALSE)
    }
  }
  vals
}

# Turn a layer into standardised vectors: coordinates (or sf), one value per
# row for each mapped aesthetic, fixed values, popups, labels, groups.
resolve_layer <- function(layer) {
  type <- layer$type %||% infer_type(layer$source)
  spec <- get_type(type)
  type_name <- if (is.character(type)) type else "custom"
  aes <- apply_fill_follows(spec, layer$mapped, layer$const, layer$fixed)

  geom <- resolve_geometry(layer$source, spec, type, aes$mapped)
  if (!any(geom$ok)) {
    stop("No row with valid coordinates to map.", call. = FALSE)
  }
  if (any(!geom$ok)) {
    message(sum(!geom$ok), " row(s) without valid coordinates dropped.")
  }
  idx <- which(geom$ok)
  n <- length(idx)
  src <- geom$src
  data <- as.data.frame(
    if (inherits(src, "sf")) sf::st_drop_geometry(src) else src,
    stringsAsFactors = FALSE
  )[idx, , drop = FALSE]

  vals <- list()
  for (a in setdiff(names(aes$mapped), c("lon", "lat"))) {
    if (length(aes$mapped[[a]]) != 1L) {
      stop("`", a, "` must be a single column.", call. = FALSE)
    }
    vals[[a]] <- data[[aes$mapped[[a]]]]
  }
  for (a in names(aes$const)) vals[[a]] <- const_factor(aes$const[[a]], n)
  fixed <- aes$fixed[setdiff(names(aes$fixed), c("lon", "lat"))]
  vals <- scale_numeric_aes(vals, fixed, layer, spec)

  # the aesthetics the type cannot draw
  lost <- setdiff(
    intersect(c(names(vals), names(fixed)),
              c("colour", "fill", "size", "opacity")),
    names(spec$aes)
  )
  if (length(lost)) {
    warning(
      "Layer type '", type_name, "' ignores: ", paste(lost, collapse = ", "),
      ".", call. = FALSE
    )
    vals[lost] <- NULL
    fixed[lost] <- NULL
  }

  group <- vals$group
  if (is.null(group) && !is.null(fixed$group)) {
    group <- rep_len(as.character(fixed$group[1L]), n)
  }
  # rows without group are drawn too, in a group of their own
  if (!is.null(group)) group <- ifelse(is.na(group), "NA", as.character(group))
  vals$group <- NULL
  fixed$group <- NULL

  list(
    spec = spec, type = type, n = n, lng = geom$lng[idx], lat = geom$lat[idx],
    geo = if (inherits(src, "sf")) src[idx, ],
    vals = vals, fixed = fixed,
    group = group,
    popup = build_html(layer$popup, data, n, "popup"),
    label = build_html(layer$label, data, n, "label"),
    params = layer$params, labels = layer_labels(layer)
  )
}

# The calls (function + arguments) drawing a resolved layer, one per group
layer_calls <- function(r) {
  spec <- r$spec
  fun <- type_fun(spec)
  row_args <- list()
  for (a in intersect(names(spec$aes), names(r$vals))) {
    row_args[[spec$aes[[a]]]] <- r$vals[[a]]
  }
  fixed_args <- list()
  for (a in intersect(names(spec$aes), names(r$fixed))) {
    fixed_args[[spec$aes[[a]]]] <- r$fixed[[a]]
  }
  static <- utils::modifyList(spec$params, r$params)
  static <- utils::modifyList(static, fixed_args)

  one <- function(idx, group) {
    args <- static
    for (nm in names(row_args)) args[[nm]] <- row_args[[nm]][idx]
    if (is.null(r$geo)) {
      args$lng <- r$lng[idx]
      args$lat <- r$lat[idx]
    } else {
      args$data <- r$geo[idx, ]
    }
    if (!is.null(r$popup)) args$popup <- r$popup[idx]
    if (!is.null(r$label)) {
      args$label <- lapply(r$label[idx], htmltools::HTML)
    }
    if (!is.null(group)) args$group <- group
    list(fun = fun, args = args)
  }

  if (is.null(r$group)) return(list(one(seq_len(r$n), NULL)))
  lv <- unique(r$group[!is.na(r$group)])
  lapply(lv, function(g) one(which(r$group == g), g))
}
