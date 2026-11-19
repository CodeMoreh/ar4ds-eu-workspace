# AR4DS workspace – Europeanisation and the economy

## **What is this?**

A ready-to-run replication exercise for the course "Applied Replication for Data Skills". You reproduce one of the reanalyses from the SCORE robustness study, whose results were recently published in *Nature* (Aczel et al. 2026), and test the robustness of a published claim from the target article.

The report that you build is `index.qmd`. It renders as it stands, because the data ship inside `data/`.

------------------------------------------------------------------------

## Setting up the workspace

This workspace is a plain folder, with no version control and no account to sign in to.

1.  **Download the workspace.** On the GitHub page of the template, click the green **Code** button, then **Download ZIP** – or use the direct link `https://github.com/CodeMoreh/ar4ds-eu-workspace/archive/refs/heads/main.zip`. Save it somewhere you own (Desktop or Documents).

2.  **Unzip it.** Extract the ZIP to a real folder (on Windows, "Extract All" – do not work inside the compressed preview). You will get a folder called `ar4ds-eu-workspace-main` containing `index.qmd`, `data/`, `R/`, and this file.

3.  **Open the folder in your IDE.** In Positron or VS Code, **File → Open Folder…** and pick the unzipped folder; in RStudio, open `ar4ds-eu-workspace.Rproj`, which sits inside it.

4.  **Restore the packages.** `R/check_setup.R` checks what is installed and lists what is missing. In the R console:

    ``` r
    source("R/check_setup.R")
    ```

    It prints an `[OK]`, `[FAIL]` or `[SKIP]` line per check (R version, Quarto, the required packages, the data files), and a `[NOTE]` that names any package installed at another version than the course was tested with. If any packages are missing, it prints the one line that installs them. Run that line, then re-run the check.

5.  **Open the report and preview it.** Open `index.qmd`, then in a terminal inside your IDE:

    ``` sh
    quarto preview
    ```

    The skeleton report opens in a browser. Then work through the tasks inside `index.qmd`.

------------------------------------------------------------------------

## The Eurobarometer files, for the individual-level work

Everything above runs on the country-year panel in `data/`. The respondent-level data behind it are sixteen Eurobarometer surveys that GESIS distributes under terms that do not allow this workspace to include them, so they are downloaded under your own free GESIS account, into a folder outside the workspace. The course site lists the sixteen studies and walks through the download at https://codemoreh.github.io/ar4ds-eu/companion/data-sources.html#sec-gesis. Two scripts then do the rest:

- `prep/01_build_respondents.R` – set the folder path at the top, source it once. It checks every file against the version and checksum of the copy from which the course was built, reads the sixteen, harmonises the respondent characteristics, and writes `data_private/eb_respondents.rds`. That folder is ignored by git and must stay so: the file is licensed microdata, never to be shared or opened in a session that an AI assistant can read.
- `prep/02_scales_and_panel.R` – read and run section by section. It builds the framing scales under the three scoring rules, averages respondents into country-years, merges the macro series, reproduces `data/europeanisation_cy.csv` to machine precision, and builds the panel by education band.

The two scripts under `prep/` that begin "EXHIBIT ONLY" are the historical builds, kept for reading.

The GESIS terms of use prohibit processing these files, and anything built from them, with an AI system. This workspace therefore switches off the AI features of Positron and VS Code for its whole folder, in `.vscode/settings.json`, which both IDEs read whenever the folder is open; leave that file as it is. RStudio does not read it, so in RStudio switch the assistant off under Tools → Global Options → Assistant before you open the workspace. The module on AI assistants sets out the terms and the settings: https://codemoreh.github.io/ar4ds/tools/ai.html#sec-licensed

------------------------------------------------------------------------

## A note on version control

This folder is not a git repository, so there is nothing to commit or push and no account to set up. The workspace came from a GitHub repository (`CodeMoreh/ar4ds-eu-workspace`), and putting your own work under version control and publishing the rendered report is the natural next step. The module **Git and GitHub** on the course site goes through it: <https://codemoreh.github.io/ar4ds/git-github.html>. The `.github/` and `.devcontainer/` folders of this workspace set up that route once the folder is a repository again.

------------------------------------------------------------------------

## The tasks

The tasks in `index.qmd`:

- **Task 1.** The setup check, and the three Rs.
- **Task 2.** The country-year panel, the estimand statement and the causal graph.
- **Task 3.** The reproduction of a recorded result.
- **Task 4.** The specification menu, and an exploratory result on the class chart.
- **Task 5.** The preregistration, the fit and a declared result on the class chart.
- **Going further.** Optional tasks.

------------------------------------------------------------------------

## Links

- **Course site:** https://codemoreh.github.io/ar4ds-eu/
- **Submit your results:** `submit_exploration()` in Task 4 and `report_result()` in Task 5 each print a link to a pre-filled form, and the result appears on the live class chart at https://codemoreh.github.io/ar4ds-eu/class-results.html
- **Take-home git/GitHub path:** https://codemoreh.github.io/ar4ds/git-github.html
- **The OSF analyst fork:** https://osf.io/6zqct/ – the analyst's maintained fork, which holds the working materials and the panel that this workspace uses. The official archival record of the robustness study is at https://osf.io/8rtwe/.

------------------------------------------------------------------------

## Notes for the repository maintainer

This workspace is published as the "Use this template" repository `CodeMoreh/ar4ds-eu-workspace`. Two folders serve the take-home and publishing route:

- `.devcontainer/devcontainer.json` – a Codespaces / dev-container image (R + Quarto + the package list) so the repo can be opened and rendered in the cloud with no local install.
- `.github/workflows/publish.yml` – renders the report and publishes it to GitHub Pages on every push, once **Settings → Pages → Source** is set to **"GitHub Actions"**. It installs R and re-runs the chunks, so a participant's edits show up.

Neither is needed for the zip route used in class. Keep `data/` in sync with the `data/` folder of the course repository: `europeanisation_cy.csv` and its codebook are what the report reads directly, and `analyst_KQXUE.csv` and `analyst_018OL.csv`, with `analyst_panels_codebook.md`, are the data of the two other reproductions of Task 3. `teney_panel_measurement.csv` and `predictor_measures.csv` are the measurement variants of the panel and the published predictor series from which `R/spec_tools.R` fits every specification. `spec_curve.csv` (with `spec_curve_codebook.md`) is the curve of 864 specifications, from which the helpers read the placement of each fit and against which they check it, and `menu_options.csv` gives the reason for every option that is not on the curve. Each live fit computes its CR2 errors clustered by country, with Satterthwaite degrees of freedom, through the `clubSandwich` package, the rule that classes the curve, so it returns the stored p-value exactly. `teney_panel_weights.csv` is read by the two scripts in `prep/`.

------------------------------------------------------------------------

*Code is MIT-licensed; prose, figures, and data are CC BY 4.0 – see `LICENSE`.*
