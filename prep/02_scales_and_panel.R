##############################################################################
# Title:        02_scales_and_panel.R – from items to scales to the panel
# Purpose:      Rebuild the country-year panel that ships with the workshop from
#               the respondent file written by 01_build_respondents.R, one
#               decision at a time: which items form which scale, how a
#               respondent's answers are scored, what happens to a respondent
#               who named nothing, how respondents are averaged into a
#               country-year, and how the macro series are merged in. The
#               rebuilt panel is compared with data/europeanisation_cy.csv, which it
#               reproduces to machine precision when the respondent file has
#               passed its checks. The last section builds the panel by
#               education band.
# Reads:        data_private/eb_respondents.rds
#               data/europeanisation_cy.csv, data/predictor_measures.csv,
#               data/teney_panel_weights.csv
# Writes:       data_private/europeanisation_cy_rebuilt.csv
#               data_private/europeanisation_cy_edu.csv
# Author:       Chris Moreh
# Last updated: 2026-11-19
##############################################################################

respondents <- readRDS("data_private/eb_respondents.rds")
panel       <- readr::read_csv("data/europeanisation_cy.csv", show_col_types = FALSE)
measures    <- readr::read_csv("data/predictor_measures.csv", show_col_types = FALSE)
weights     <- readr::read_csv("data/teney_panel_weights.csv", show_col_types = FALSE)

# --- 1. which items form which scale --------------------------------------------
# The published assignment of the thirteen scored items to four scales, by item
# position. The euro item (8) is left out throughout, as in the paper. The two
# composites are the positive and the negative pair of scales.
items <- list(
  cosmo = paste0("it", c(1, 3, 5, 6, 7)),  # peace, democracy, travel, diversity, say
  util  = paste0("it", c(2, 4)),           # prosperity, social protection
  comm  = paste0("it", c(9, 12, 13, 14)),  # unemployment, identity, crime, frontiers
  lib   = paste0("it", c(10, 11))          # bureaucracy, waste of money
)
items <- c(items, list(pos = c(items$cosmo, items$util), neg = c(items$comm, items$lib)))
items13 <- c(items$pos, items$neg)

# --- 2. three scoring rules ------------------------------------------------------
# The share (the published rule) is the mentions from the set over the
# respondent's own total, the count the number of items of the set mentioned,
# and the per-item rate the count over the number of items of the set; the
# choice is a decision of the specification menu.
#
# A respondent who mentioned none of the thirteen items is scored zero on every
# scale, as analyst C6HJR scored them; the code of the original study left
# them out, dividing by a total of zero. The other rules of the menu (drop,
# split, impute) are applied later in the pipeline.
#
# Each scale gets three columns: c_ the count, s_ the share and r_ the
# per-item rate.
scored <- names(items) |>
  purrr::reduce(\(d, s) {
    d |>
      dplyr::mutate("c_{s}" := datawizard::row_sums(dplyr::pick(dplyr::all_of(items[[s]]))),
                    "s_{s}" := dplyr::if_else(n_all == 0, 0, .data[[paste0("c_", s)]] / n_all),
                    "r_{s}" := .data[[paste0("c_", s)]] / length(items[[s]]))
  }, .init = dplyr::mutate(respondents,
                           n_all = datawizard::row_sums(dplyr::pick(dplyr::all_of(items13)))))

# --- 3. from respondents to country-years -----------------------------------------
# Each cell mean twice: unweighted ('as interviewed'), as in the country-year panel,
# and with the design weight w1, which GESIS supplies to correct each national
# sample to its population; the decision Cell weighting of the specification
# menu compares the two.
cells <- scored |>
  dplyr::summarise(
    dplyr::across(dplyr::starts_with("s_"), mean, .names = "m{.col}"),
    dplyr::across(dplyr::starts_with("s_"), \(x) stats::weighted.mean(x, w1), .names = "w{.col}"),
    dplyr::across(dplyr::starts_with("c_"), mean, .names = "m{.col}"),
    n_cy = dplyr::n(),
    .by = c(cntry, year)
  ) |>
  dplyr::rename_with(\(x) sub("^ms_", "m", x), dplyr::starts_with("ms_")) |>
  dplyr::rename_with(\(x) sub("^ws_", "w_m", x), dplyr::starts_with("ws_")) |>
  dplyr::rename_with(\(x) sub("^mc_", "c_m", x), dplyr::starts_with("mc_"))

# --- 4. the macro series ----------------------------------------------------------
# The national unemployment estimate of the World Bank (SL.UEM.TOTL.NE.ZS) and
# annual GDP growth from the same source (NY.GDP.MKTP.KD.ZG), open data, read
# from data/predictor_measures.csv, which holds every series of the menu. The
# same two series can be fetched with the WDI package:
#
#   WDI::WDI(country = unique(cells$cntry),
#            indicator = c(unemp = "SL.UEM.TOTL.NE.ZS", growth = "NY.GDP.MKTP.KD.ZG"),
#            start = 2004, end = 2013)
#
# and the Eurostat series with eurostat::get_eurostat(); a live fetch may
# differ from the committed values in the last decimals, because the Bank
# revises past years.
macro <- measures |>
  datawizard::data_filter(measure %in% c("wb_nat", "wb_growth")) |>
  datawizard::data_select(select = c("cntry", "year", "predictor", "value")) |>
  tidyr::pivot_wider(names_from = predictor, values_from = value)

# The bailout indicator is coded by rule from the record of EU and IMF
# assistance programmes; the codebook lists the programmes and years.
bailout <- datawizard::data_select(panel, select = c("cntry", "year", "bailout"))

rebuilt <- cells |>
  dplyr::left_join(macro,   by = c("cntry", "year")) |>
  dplyr::left_join(bailout, by = c("cntry", "year")) |>
  # dplyr::arrange() sorts in the C locale on every machine
  dplyr::arrange(cntry, year)

# --- 5. comparison with the country-year panel -------------------------------------
compare <- panel |>
  dplyr::inner_join(rebuilt, by = c("cntry", "year"), suffix = c("_course", "_rebuilt"))

scale_cols <- c("mcosmo", "mutil", "mcomm", "mlib", "mpos", "mneg")
differences <- tibble::tibble(
  column = c(scale_cols, "n_cy", "unemp", "growth"),
  max_abs_difference = purrr::map_dbl(column, \(v)
    max(abs(compare[[paste0(v, "_course")]] - compare[[paste0(v, "_rebuilt")]]),
        na.rm = TRUE))
)

weighted_check <- weights |>
  datawizard::data_select(select = c("cntry", "year", "w_mcosmo", "w_mutil", "w_mcomm", "w_mlib",
                                     "w_mpos", "w_mneg", "c_mcosmo", "c_mutil", "c_mcomm",
                                     "c_mlib", "c_mpos", "c_mneg")) |>
  dplyr::inner_join(rebuilt, by = c("cntry", "year"), suffix = c("_course", "_rebuilt"))
weighted_differences <- tibble::tibble(
  column = c(paste0("w_m", c("cosmo", "util", "comm", "lib", "pos", "neg")),
             paste0("c_m", c("cosmo", "util", "comm", "lib", "pos", "neg"))),
  max_abs_difference = purrr::map_dbl(column, \(v)
    max(abs(weighted_check[[paste0(v, "_course")]] -
            weighted_check[[paste0(v, "_rebuilt")]]), na.rm = TRUE))
)

# the country-years compared, then the largest differences: as-interviewed
# cell means, counts and macro series against data/europeanisation_cy.csv, and
# design-weighted and count-built cell means against data/teney_panel_weights.csv
c(compared = nrow(compare), in_panel = nrow(panel))
print(as.data.frame(differences), row.names = FALSE, right = FALSE)
print(as.data.frame(weighted_differences), row.names = FALSE, right = FALSE)

# --- 6. the panel by education band ---------------------------------------------------
# One row per country, year and education band, with the six scales and the
# number of respondents behind each mean, the base of a precision weight.
by_edu <- scored |>
  datawizard::data_filter(!is.na(edu3)) |>
  dplyr::summarise(dplyr::across(dplyr::starts_with("s_"), mean, .names = "m{.col}"),
                   n = dplyr::n(), .by = c(cntry, year, edu3)) |>
  dplyr::rename_with(\(x) sub("^ms_", "m", x), dplyr::starts_with("ms_")) |>
  dplyr::left_join(macro,   by = c("cntry", "year")) |>
  dplyr::left_join(bailout, by = c("cntry", "year")) |>
  # dplyr::arrange() sorts in the C locale on every machine
  dplyr::arrange(cntry, year, edu3)

dir.create("data_private", showWarnings = FALSE)
rebuilt |>
  datawizard::data_select(select = c("cntry", "year", scale_cols, "n_cy", "growth", "unemp",
                                     "bailout")) |>
  readr::write_csv("data_private/europeanisation_cy_rebuilt.csv")
readr::write_csv(by_edu, "data_private/europeanisation_cy_edu.csv")
