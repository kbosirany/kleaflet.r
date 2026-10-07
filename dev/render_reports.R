# Template kpkg.r 0.1.0.9000: project/render_reports.R
# Render the Quarto books of `reports/` in the pkgdown site
#
# Run from the package root:
#   Rscript dev/render_reports.R [site]
# `site` is the folder of the pkgdown site, by default the destination of
# `_pkgdown.yml` (`docs`). Called by dev/build_site.R, which builds the site
# first: the books are written afterwards, as pkgdown may clean the folder.
#
# A book is a folder of `reports/` with a `_quarto.yml`. It is rendered in
# `<site>/reports/<book>/`, where the navbar of the site links to it (see
# `reports_navbar()`). Needs the Quarto CLI and the quarto R package.

`%||%` <- function(x, y) if (is.null(x)) y else x

# Folder names of the books
list_reports <- function(path = "reports") {
  yml <- Sys.glob(file.path(path, "*", "_quarto.yml"))
  sort(basename(dirname(yml)))
}

# Packages used by the code of the reports (`library(x)`, `require(x)`,
# `requireNamespace("x")`, `x::f()`) in the R chunks of the `.qmd` and `.Rmd`
# files and in the `.R` files, that are not installed. The package itself and
# the packages of `DESCRIPTION` are not looked for: they are installed with it.
report_packages <- function(path = "reports") {
  files <- list.files(
    path, pattern = "\\.(qmd|Rmd|R)$", recursive = TRUE, full.names = TRUE
  )
  code <- unlist(lapply(files, function(file) {
    lines <- readLines(file, warn = FALSE)
    if (grepl("\\.R$", file)) {
      return(lines)
    }
    # lines of the R chunks
    keep <- logical(length(lines))
    in_r <- FALSE
    in_other <- FALSE
    for (i in seq_along(lines)) {
      if (grepl("^\\s*```", lines[[i]])) {
        if (in_r || in_other) {
          in_r <- in_other <- FALSE
        } else {
          in_r <- grepl("^\\s*```\\{r[ ,}]|^\\s*```r\\s*$", lines[[i]])
          in_other <- !in_r
        }
      } else {
        keep[[i]] <- in_r
      }
    }
    lines[keep]
  }))
  code <- code[!grepl("^\\s*#", code)]
  find <- function(pattern) {
    matches <- regmatches(code, gregexpr(pattern, code, perl = TRUE))
    sub(pattern, "\\1", unlist(matches), perl = TRUE)
  }
  load_call <- "(?:library|require|requireNamespace|loadNamespace)\\("
  used <- unique(c(
    find(paste0(load_call, "\\s*[\"']?([A-Za-z][A-Za-z0-9.]*)")),
    find("\\b([A-Za-z][A-Za-z0-9.]*):::?[A-Za-z_.]")
  ))
  known <- character()
  if (file.exists("DESCRIPTION")) {
    fields <- read.dcf(
      "DESCRIPTION", fields = c("Package", "Depends", "Imports", "Suggests")
    )
    known <- c(
      fields[, "Package"],
      trimws(sub("\\(.*", "", unlist(strsplit(fields[, -1], ","))))
    )
  }
  used <- setdiff(used, known)
  sort(used[!vapply(used, requireNamespace, logical(1), quietly = TRUE)])
}

# Installs the packages of the reports that are missing, in the CI (the
# environment variable `CI` is "true"). Elsewhere, only tells which are
# missing, rather than changing the library.
install_report_packages <- function(path = "reports") {
  missing <- report_packages(path)
  if (length(missing) == 0) {
    return(invisible(character()))
  }
  if (identical(Sys.getenv("CI"), "true")) {
    message("Installing the packages of the reports: ", toString(missing))
    pak::pkg_install(missing)
  } else {
    warning(
      "Packages of the reports are not installed: ", toString(missing),
      call. = FALSE
    )
  }
  invisible(missing)
}

# Renders the books in `<site>/reports/<book>/`, and checks that each one has
# an `index.html`. Returns the folders of the books, invisibly.
render_reports <- function(site, path = "reports") {
  books <- list_reports(path)
  if (length(books) == 0) {
    message("No Quarto book in ", path)
    return(invisible(character()))
  }
  if (!requireNamespace("quarto", quietly = TRUE)) {
    stop("The 'quarto' package is required to render the reports.")
  }
  install_report_packages(path)
  output_dirs <- file.path(site, "reports", books)
  for (i in seq_along(books)) {
    unlink(output_dirs[[i]], recursive = TRUE)
    dir.create(output_dirs[[i]], recursive = TRUE)
    # Absolute path: Quarto resolves a relative one from the book folder,
    # and the book would not be in the site
    quarto::quarto_render(
      input = file.path(path, books[[i]]),
      quarto_args = c("--output-dir", normalizePath(output_dirs[[i]]))
    )
  }
  index <- file.path(output_dirs, "index.html")
  if (!all(file.exists(index))) {
    stop(
      "Report(s) not rendered in the site: ",
      paste(books[!file.exists(index)], collapse = ", ")
    )
  }
  message("Reports rendered in ", site, ": ", paste(books, collapse = ", "))
  invisible(output_dirs)
}

# The menu of the books: a header by language when there are several
# languages (English, then French, then the books without language), none
# otherwise.
reports_menu <- function(lang, titles, hrefs) {
  languages <- c("English", "Fran\u00e7ais", "Other")
  names(languages) <- c("en", "fr", "")
  present <- intersect(names(languages), unique(lang))
  items <- function(i) {
    lapply(i, function(k) list(text = titles[[k]], href = hrefs[[k]]))
  }
  if (length(present) == 1) {
    return(items(seq_along(lang)))
  }
  menu <- list()
  for (l in present) {
    if (length(menu) > 0) {
      menu <- c(menu, list(list(text = "---------")))
    }
    menu <- c(menu, list(list(text = languages[[l]])), items(which(lang == l)))
  }
  menu
}

# Navbar entry of the books, as a pkgdown `override` list: one menu,
# `reports`, with the title of each book, and a header by language (the
# `-en` or `-fr` end of the folder name) when there are several languages (see
# `reports_menu()`). A component `reports` already defined in `_pkgdown.yml` is
# kept as it is, and the books that the components already link to get no
# entry. `NULL` if there is nothing to add.
reports_navbar <- function(pkg, path = "reports") {
  books <- list_reports(path)
  navbar <- pkg$meta$navbar
  linked <- as.character(unlist(lapply(navbar$components, function(x) {
    vapply(x$menu, function(item) item$href %||% "", character(1))
  })))
  books <- books[!vapply(books, function(book) {
    any(startsWith(linked, file.path("reports", book, "")))
  }, logical(1))]
  if (length(books) == 0 || "reports" %in% names(navbar$components)) {
    return(NULL)
  }
  lang <- ifelse(
    grepl("-(fr|en)$", books), sub(".*-(fr|en)$", "\\1", books), ""
  )
  titles <- vapply(books, function(book) {
    title <- yaml::read_yaml(file.path(path, book, "_quarto.yml"))$book$title
    if (is.null(title)) book else as.character(title)
  }, character(1))
  new <- list(reports = list(
    text = "Reports",
    menu = reports_menu(
      lang, unname(titles), file.path("reports", books, "index.html")
    )
  ))
  left <- navbar$structure$left
  if (is.null(left)) {
    left <- c("intro", "reference", "articles", "tutorials", "news")
  }
  after <- if ("intro" %in% left) match("intro", left) else 0L
  left <- append(left, setdiff(names(new), left), after = after)
  list(navbar = list(structure = list(left = left), components = new))
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  site <- if (length(args)) args[[1]] else pkgdown::as_pkgdown(".")$dst_path
  render_reports(site)
}
