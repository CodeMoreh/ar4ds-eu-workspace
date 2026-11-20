##############################################################################
# Title:        get_data.R – fetch the country-year panel the way a researcher would
# Purpose:      Optional: fetch europeanisation_cy.csv from the Open Science
#               Framework. The file ships in data/, so the report renders
#               without this script. The steps are tried in order, each
#               announced by a message(): (1) the file is present, and nothing
#               is fetched; (2) osfr fetches it from the main folder of OSF
#               node 6zqct, the fork of the analyst; (3) the mirror on the
#               workshop's website, https://codemoreh.github.io/
#               ar4ds-eu/data/europeanisation_cy.csv.
#               The fork osf.io/6zqct ("Multi100 | Teney_EurSocioRev_2016 |
#               Analyst_C6HJR") is maintained for teaching; the archival
#               record of the robustness study is osf.io/8rtwe.
# Author:       Chris Moreh
# Last updated: 2026-11-19
# Sourced by:   index.qmd (Task 2, optional), which writes or confirms
#               data/europeanisation_cy.csv
##############################################################################

get_data <- function(dest = "data/europeanisation_cy.csv") {

  dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)

  # --- Step 1: already present? ---------------------------------------------
  if (file.exists(dest)) {
    message("[1/3] '", dest, "' already present – nothing to do.")
    return(invisible(dest))
  }

  # --- Step 2: osfr -----------------------------------------------------------
  # the node is public, so no OSF login is needed
  message("[2/3] Trying osfr (OSF node 6zqct) …")
  ok <- tryCatch({
    if (!requireNamespace("osfr", quietly = TRUE)) {
      stop("osfr not installed")
    }
    node  <- osfr::osf_retrieve_node("6zqct")
    files <- osfr::osf_ls_files(node)
    hit   <- files[files$name == "europeanisation_cy.csv", ]
    if (nrow(hit) == 0) stop("europeanisation_cy.csv not found in the main folder")
    osfr::osf_download(hit, path = dirname(dest), conflicts = "overwrite")
    file.exists(dest)
  }, error = function(e) {
    message("      osfr route failed: ", conditionMessage(e))
    FALSE
  })
  if (isTRUE(ok)) {
    message("      fetched with osfr.")
    return(invisible(dest))
  }

  # --- Step 3: the mirror on the workshop's website, outside the OSF --------
  message("[3/3] Trying the mirror on the workshop's website …")
  ok <- tryCatch({
    utils::download.file(
      "https://codemoreh.github.io/ar4ds-eu/data/europeanisation_cy.csv",
      dest, mode = "wb", quiet = TRUE)
    file.exists(dest) && file.size(dest) > 0
  }, error = function(e) {
    message("      mirror failed: ", conditionMessage(e))
    FALSE
  })
  if (isTRUE(ok)) {
    message("      fetched from the mirror.")
    return(invisible(dest))
  }

  # --- All remote routes exhausted ------------------------------------------
  stop("get_data(): europeanisation_cy.csv not fetched from any source and not ",
       "found in data/. Run from the root folder of the IDE workspace.")
}

# Run on source().
get_data()
