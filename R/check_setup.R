##############################################################################
# Title:        check_setup.R – does this machine have what the course needs?
# Purpose:      Report R version, Quarto, the required packages, and whether the
#               workspace data files are present and readable. Prints an
#               [OK] / [FAIL] / [SKIP] line per check and a verdict, and a
#               [NOTE] where a package is at another version than the course
#               was tested with. It only checks, and changes nothing on your
#               system. Base R throughout,
#               because it has to run before any package is installed.
# Author:       Chris Moreh
# Last updated: 2026-11-17
# Sourced by:   the participant, before the session (source("R/check_setup.R"))
##############################################################################

# A FAIL is not the end of the world: the browser lab on the course site runs
# the same exercise inside a web browser. The message at the bottom says what
# to do.

# --- tiny reporting helpers -------------------------------------------------
.results <- list2env(list(pass = 0L, fail = 0L, skip = 0L))
.tally <- function(kind, label, msg) {
  assign(kind, get(kind, envir = .results) + 1L, envir = .results)
  writeLines(paste0(label, msg))
}
ok   <- function(msg) .tally("pass", "[OK]   ", msg)
fail <- function(msg) .tally("fail", "[FAIL] ", msg)
skip <- function(msg) .tally("skip", "[SKIP] ", msg)

# Run a system command quietly and return its trimmed stdout, or "" on failure.
sys_out <- function(cmd, args) {
  out <- tryCatch(
    suppressWarnings(system2(cmd, args, stdout = TRUE, stderr = TRUE)),
    error = function(e) character(0)
  )
  if (length(out) == 0) "" else trimws(paste(out, collapse = " "))
}

writeLines("\n=== AR4DS workspace, the Europeanisation and the economy case study – setup check ===\n")

# --- 1. R version -----------------------------------------------------------
if (getRversion() >= "4.4.0") {
  ok(paste0("R ", getRversion(), " (>= 4.4 required)"))
} else {
  fail(paste0("R ", getRversion(), " is below 4.4 – please update R"))
}

# --- 2. Quarto on PATH ------------------------------------------------------
qv <- sys_out("quarto", "--version")
if (nzchar(qv) && !grepl("not found|error", qv, ignore.case = TRUE)) {
  ok(paste0("Quarto on PATH (version ", qv, ")"))
} else {
  fail("Quarto not found on PATH – install from https://quarto.org and reopen the terminal")
}

# --- 3. packages ------------------------------------------------------------
# Every specification on the curve is fitted with fixest and tested with the
# CR2 errors of clubSandwich; effectsize converts its t to a partial r, and
# parameters prints the reproduced models. The reproduction of analyst 018OL
# in Task 3 is a mixed model, fitted with lme4 and read with the Satterthwaite
# degrees of freedom of lmerTest. The data work uses datawizard,
# insight, dplyr, purrr, tibble and readr, the figures tinyplot, and the causal
# graph dagitty and ggdag. Quarto runs the R chunks of the report through
# rmarkdown, so a fresh R installation without it renders nothing. The build of
# the respondent file, prep/01_build_respondents.R, reads the Eurobarometer
# files with haven, which none of the other packages installs.
needed <- c("readr", "datawizard", "insight", "dplyr", "purrr", "tibble", "fixest", "clubSandwich",
            "effectsize", "parameters", "lme4", "lmerTest", "tinyplot", "dagitty", "ggdag",
            "modelsummary", "osfr", "haven", "rmarkdown")
# The course was tested with the versions that CRAN held on its package date.
# The address is the copy of CRAN of that day kept by the public package
# manager of Posit, and the install lines below take the packages from it.
course_repo <- "https://packagemanager.posit.co/cran/2026-11-17"
install_line <- '          install.packages(c("%s"), repos = "%s")'
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) == 0) {
  ok(paste0("all ", length(needed), " required packages installed"))
} else {
  fail(paste0("missing package(s): ", paste(missing, collapse = ", ")))
  writeLines(c("        install the missing ones with:",
               sprintf(install_line, paste(missing, collapse = '", "'), course_repo)))
}

# The installed versions against those of the package date. A difference is
# not a failure: the note is there for the day on which an exercise stops.
present <- setdiff(needed, missing)
tested <- tryCatch(
  stats::setNames(utils::available.packages(repos = course_repo, type = "source")[present, "Version"], present),
  error = function(e) NULL, warning = function(w) NULL
)
if (length(present) == 0 || is.null(tested)) {
  skip("the package versions were not compared with those of the course (no connection)")
} else {
  differ <- present[vapply(present, function(p) utils::packageVersion(p) != tested[[p]], logical(1))]
  if (length(differ) == 0) {
    ok(paste0("the ", length(present), " packages are at the versions of the course"))
  } else {
    writeLines(c(
      paste0("[NOTE] ", length(differ), " package(s) at another version than the course was tested with:"),
      paste0("        ", differ, " ", vapply(differ, function(p) as.character(utils::packageVersion(p)), character(1)),
             " (the course: ", tested[differ], ")"),
      "        if an exercise fails, install the versions of the course with:",
      sprintf(install_line, paste(differ, collapse = '", "'), course_repo)
    ))
  }
}

# --- 4. data files present and readable -------------------------------------
# The report renders offline because these ship inside the workspace. The loop
# confirms that they are here and that each can be read. europeanisation_cy.csv is the
# panel on which every task is fitted. The next four are what R/spec_tools.R
# reads: the measurement variants of the panel, the published predictor series,
# the curve of 864 specifications and the reasons for the options that are not
# on it. The two analyst files hold the data on which the results of KQXUE and
# 018OL reproduce in Task 3. rep_data.csv is the file as submitted to the
# robustness study, kept as provenance and used by no task.
data_files <- c("data/europeanisation_cy.csv", "data/teney_panel_measurement.csv",
                "data/predictor_measures.csv", "data/spec_curve.csv",
                "data/menu_options.csv", "data/analyst_KQXUE.csv",
                "data/analyst_018OL.csv", "data/rep_data.csv")
for (f in data_files) {
  if (!file.exists(f)) {
    fail(paste0("data file missing: ", f, " – run from the workspace root folder"))
    next
  }
  n_rows <- tryCatch(nrow(utils::read.csv(f)), error = function(e) NA_integer_)
  if (is.na(n_rows)) {
    fail(paste0("could not read ", f))
  } else {
    ok(paste0(f, " present and readable (", n_rows, " rows)"))
  }
}

# The codebook that the tasks refer to.
if (file.exists("data/europeanisation_cy_codebook.md")) {
  ok("data/europeanisation_cy_codebook.md present")
} else {
  skip("data/europeanisation_cy_codebook.md not found (optional reference)")
}

# --- 5. the report file -----------------------------------------------------
# index.qmd is what you open and work in. Its presence is the last check.
if (file.exists("index.qmd")) {
  ok("index.qmd present – open it to start")
} else {
  fail("index.qmd not found – run this from the workspace root folder")
}

# --- verdict ----------------------------------------------------------------
writeLines(c("\n=== Verdict ===",
             sprintf("  %d OK   %d FAIL   %d SKIP", .results$pass, .results$fail, .results$skip)))

if (.results$fail == 0) {
  writeLines("\nYou are ready. Open index.qmd and run `quarto preview` in the terminal.\n")
} else {
  writeLines(c("\nSome checks failed. Two options:",
               " 1. Fix the FAILs above (each line says how), then re-run this script.",
               "    The help page on the course site lists the common failures and fixes.",
               " 2. Come anyway – the slides of the day and the browser lab run the same",
               "    exercise inside a web browser, and you can work through the rest on",
               "    a partner's laptop.",
               ""))
}
