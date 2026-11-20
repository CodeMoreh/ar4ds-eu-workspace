##############################################################################
# Title:        Working script – the robustness exercise of the Europeanisation case study, plain R
# Purpose:      Tasks 2 to 5 of index.qmd, as a script you can step through in
#               the console: look at the panel, reproduce one of the three
#               results recorded in the robustness study that rest on aggregate data,
#               explore the specification menu, then
#               preregister one specification and fit and report it. Every fit
#               is live, and each is tested by CR2 errors clustered by country
#               with Satterthwaite df, as on the curve of 864 specifications.
# Reads:        data/europeanisation_cy.csv   (the country-year panel);
#               data/analyst_KQXUE.csv and data/analyst_018OL.csv (the data of
#               two of the reproductions of Task 3);
#               through R/spec_tools.R, data/teney_panel_measurement.csv and
#               data/predictor_measures.csv (the measurement variants behind
#               the menu), data/spec_curve.csv (the curve, for the placement
#               and the check of each fit) and data/menu_options.csv (the reason for every
#               option that is not on the curve)
# Writes:       – (prints results to the console; the submit helpers print a
#               pre-filled form link)
# Author:       Chris Moreh
# Last updated: 2026-11-19
##############################################################################

# The country-year panel, and the helpers of Tasks 4 and 5.
europeanisation <- readr::read_csv("data/europeanisation_cy.csv", show_col_types = FALSE)
source("R/spec_tools.R")

## ---- Task 2: meet the panel -----------------------------------------------

# One row per country-year: 27 EU member states x 10 years, 2004–2013.
europeanisation |>
  datawizard::data_summary(
    n_rows      = length(cntry),
    n_countries = insight::n_unique(cntry),
    n_years     = insight::n_unique(year),
    year_min    = min(year),
    year_max    = max(year)
  )

## ---- Task 3: reproduce a recorded result ----------------------------------

# Choose one of the three analysts whose results rest on aggregate data and
# step through its block; the codebooks in data/ say how each file was built.

# C6HJR – two-way (country + year) fixed effects on the country-year panel, with
# unemployment centred on its grand mean, which shifts only the intercept. On
# record: t = -3.804 on 233 df.
europeanisation <- europeanisation |>
  datawizard::data_modify(unemp_c = unemp - mean(unemp))
m1 <- fixest::feols(mcosmo ~ unemp_c | cntry + year, data = europeanisation, vcov = "iid")
print(parameters::model_parameters(m1), digits = 5)

# KQXUE – country fixed effects only, as xtreg cosmo unemployment, fe in Stata,
# on its own panel (EB 62.0 appended twice, unemployment as a share of the
# population aged 20-64). On record: t = -7.169 on 242 df.
kqxue <- readr::read_csv("data/analyst_KQXUE.csv", show_col_types = FALSE)
m_kqxue <- fixest::feols(cosmo ~ unemp | cntry, data = kqxue, vcov = "iid")
print(parameters::model_parameters(m_kqxue), digits = 5)

# 018OL – random intercepts for country, year and wave on 420 cells, with the
# Satterthwaite df of lmerTest; the analyst rescaled the outcome to 0-1, which
# leaves t unchanged. On record: t = -1.206 on 396.9 df.
o18ol <- readr::read_csv("data/analyst_018OL.csv", show_col_types = FALSE) |>
  datawizard::data_modify(pos01 = datawizard::rescale(pos, to = c(0, 1)))
m_018ol <- lmerTest::lmer(pos01 ~ unemp + (1 | cntry) + (1 | year) + (1 | wave), data = o18ol)
print(parameters::model_parameters(m_018ol, effects = "fixed", ci_method = "satterthwaite"), digits = 5)

## ---- Task 4: work the menu ------------------------------------------------

# try_spec() takes one argument for each decision of the menu, each defaulting
# to the reproduced specification, the model of C6HJR in Task 3.
try_spec()                              # the reproduced specification itself
try_spec(outcome     = "mpos")          # the composite of both positive framings
try_spec(estimator   = "fe_country")    # country effects only: changes common to all of Europe stay in
try_spec(predictor   = "growth")        # GDP growth instead of unemployment, in the World Bank series
try_spec(copredictor = "other")         # adjusted for the other economic measure, here GDP growth
try_spec(noop        = "drop")          # leave out the respondents who mentioned no frame
try_spec(measure     = "es_2064_pop")   # a Eurostat unemployment series instead of the World Bank one

# Options off the curve are refused with the reason and the page that teaches
# them; try() prints the refusal and lets the script run on.
try(try_spec(estimator = "pooled_cl"))  # pooled OLS
try(try_spec(sample = "no_bailout"))    # without the eight bailout countries

# The specifications tried, with the decisions that varied
my_experiments()

# The last one to the class chart, labelled exploratory, with the tag kept in
# .class-tag; submit_exploration(nickname = "...") sets another.
submit_exploration()

## ---- Task 5: preregister one specification --------------------------------

# One choice on each of the fourteen decisions; an option off the curve stops
# prereg() with the reason. With claim_align = TRUE the sign of a growth slope
# is flipped, since the claim expects framing to rise with GDP growth, so that a
# negative sign supports the claim.

# The question (each of these changes what is being estimated)
my_outcome      <- "mcosmo"       # mcosmo | mutil | mpos   (the positive framings)
my_predictor    <- "unemp"        # unemp | growth    (the measure that the claim is about)
my_copredictor  <- "none"         # none | other      (the other economic measure, adjusted for)
my_estimator    <- "fe_twoway"    # fe_twoway | fe_country
my_sample       <- "all"          # all    (the 27 member states, 2004–2013)
my_weights      <- "none"         # none   (every country-year counts once)
my_construction <- "share"        # share  (the share of a respondent's own mentions)

# Measurement (the same question, put to the data differently)
my_noop         <- "zero"         # zero | drop   (respondents who mentioned no frame at all)
my_item_set     <- "all"          # all | un   (with or without the "unemployment" item)
my_cell_weight  <- "unweighted"   # unweighted | design   (cells as interviewed, or weighted)
my_measure      <- "wb_nat"       # unemp:  wb_nat | es_1574_act | es_2064_pop | es_2564_lfs
                                  # growth: wb_growth

# The model (the same question and measures, another fit)
my_pred_form    <- "raw"          # raw | log   (growth: raw only; centring or z-scaling
                                  #              would leave t, r and p unchanged)
my_family       <- "gaussian"     # gaussian   (a linear model of the cell means)
my_se           <- "cr2"          # cr2   (fixed: CR2 errors clustered by country)

claim_align     <- TRUE           # the workshop's convention, applied automatically

prereg()   # checks every choice against the menu and prints your preregistration

## ---- Task 5, continued: build, run and report -----------------------------

# The preregistered specification as a formula and an estimator code;
# build_model() refuses anything that does not match the preregistration, and
# run_spec() fits it with its CR2 test.
my_model <- build_model(mcosmo ~ unemp, estimator = "fe_twoway")
run_spec(my_model)

# The preregistered specification to the class chart, with the tag of Task 4;
# open the printed address and press Send.
report_result()
