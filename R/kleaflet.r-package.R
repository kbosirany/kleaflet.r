#' @keywords internal
"_PACKAGE"

# Internal registries (types, themes, palettes), filled in .onLoad().
.kleaf <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .kleaf$types <- list()
  .kleaf$themes <- list()
  .kleaf$palettes <- list()
  register_builtin_palettes()
  register_builtin_themes()
  register_builtin_types()
}
NULL
