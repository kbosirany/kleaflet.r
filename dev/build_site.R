# Template kpkg.r 0.1.0.9000: project/build_site.R
# Build the pkgdown site, with the Quarto reports of `reports/` (see
# dev/render_reports.R), so that the links to the reports in the navbar work.
#
# Run from the package root:
#   Rscript dev/build_site.R
# Called by the GitHub Actions workflow and the GitLab CI job of the site,
# which set:
# - KPKG_DEST: folder of the site (default `docs`);
# - PKGDOWN_DEV_MODE: "release" or "devel" (the site of the dev branch is
#   written in `<destination>/dev`);
# - CI_PAGES_URL: URL of the site (GitLab).
# The navbar entries of the reports are added to those of `_pkgdown.yml`.

# The scripts are next to this one (the CI runs it from another checkout)
script_dir <- dirname(
  sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
)
script_dir <- c(script_dir, "dev")
source(file.path(
  script_dir[file.exists(file.path(script_dir, "render_reports.R"))][[1]],
  "render_reports.R"
))

override <- list(destination = Sys.getenv("KPKG_DEST", "docs"))
if (nzchar(Sys.getenv("CI_PAGES_URL"))) {
  override$url <- Sys.getenv("CI_PAGES_URL")
}

# 1. Navbar entries of the reports
pkg <- pkgdown::as_pkgdown(".", override = override)
pkg <- pkgdown::as_pkgdown(
  ".",
  override = utils::modifyList(override, reports_navbar(pkg) %||% list())
)

# 2. Build the site
if (identical(Sys.getenv("GITHUB_ACTIONS"), "true")) {
  pkgdown::build_site_github_pages(pkg, install = FALSE, new_process = FALSE)
} else {
  pkgdown::build_site(pkg, new_process = FALSE)
}

# 3. Render the reports in the site, whose folder depends on the mode (release
#    or devel)
render_reports(pkg$dst_path)
