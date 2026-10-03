# Popups and hover labels. A `popup` / `label` specification is, in order:
#  * TRUE                      -> every column, as a small table
#  * a function                -> called with the data, returns HTML strings
#  * one string with {column}  -> a template, e.g. "<b>{name}</b>: {pop}"
#  * column name(s)            -> the value (one column) or name: value lines
#  * strings, one per row      -> used as they are

cell_text <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  out <- if (is.numeric(x)) {
    format(x, trim = TRUE, scientific = FALSE, digits = 7L,
           drop0trailing = TRUE)
  } else {
    as.character(x)
  }
  out[is.na(x)] <- ""
  htmltools::htmlEscape(out)
}

template_vars <- function(template) {
  m <- regmatches(template, gregexpr("\\{[^{}]+\\}", template))[[1L]]
  unique(substring(m, 2L, nchar(m) - 1L))
}

fill_template <- function(template, data) {
  vars <- template_vars(template)
  unknown <- setdiff(vars, names(data))
  if (length(unknown)) {
    stop(
      "Column(s) not found in data for the template: ",
      paste(unknown, collapse = ", "), ".",
      call. = FALSE
    )
  }
  lit <- regmatches(
    template, gregexpr("\\{[^{}]+\\}", template), invert = TRUE
  )[[1L]]
  found <- regmatches(template, gregexpr("\\{[^{}]+\\}", template))[[1L]]
  found <- substring(found, 2L, nchar(found) - 1L)
  parts <- vector("list", length(lit) + length(found))
  parts[seq(1L, length(parts), by = 2L)] <- as.list(lit)
  parts[seq(2L, length(parts), by = 2L)] <- lapply(
    found, function(v) cell_text(data[[v]])
  )
  do.call(paste0, parts)
}

# One value per row from column names: the value, or name: value lines
columns_html <- function(spec, data) {
  if (length(spec) == 1L) return(cell_text(data[[spec]]))
  lines <- lapply(spec, function(cn) {
    paste0("<b>", htmltools::htmlEscape(cn), "</b>: ", cell_text(data[[cn]]))
  })
  do.call(paste, c(lines, sep = "<br/>"))
}

# Rows -> HTML. `kind` is only used in error messages.
build_html <- function(spec, data, n, kind = "popup") {
  if (is.null(spec) || isFALSE(spec)) return(NULL)
  cols <- names(data)
  if (isTRUE(spec)) spec <- cols
  if (is.function(spec)) {
    out <- as.character(spec(data))
    if (length(out) != n) {
      stop("The `", kind, "` function must return one string per row (",
           n, ").", call. = FALSE)
    }
    return(out)
  }
  if (!is.character(spec) && !is.factor(spec)) {
    stop("`", kind, "` must be TRUE, column names, a template, a function ",
         "or one string per row.", call. = FALSE)
  }
  spec <- as.character(spec)
  if (length(spec) == 1L && length(template_vars(spec)) > 0L) {
    return(fill_template(spec, data))
  }
  if (all(spec %in% cols)) return(columns_html(spec, data))
  if (length(spec) == n) return(spec)
  stop(
    "`", kind, "` is neither column names of the data, a template ",
    "(\"{column}\"), a function, nor one string per row (", n, ").",
    call. = FALSE
  )
}
