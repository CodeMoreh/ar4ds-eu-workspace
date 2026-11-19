##############################################################################
# Title:        dag_starter.R – the half-built DAG for the claim under test
# Purpose:      The graph of Task 2 for the claim "national unemployment lowers
#               cosmopolitan EU framing": the path of interest and the two
#               confounder pairs are drawn, and the arguable arrows are in the
#               same call, commented out. Uncomment the ones you hold, source
#               the file again and read the adjustment set with
#               dagitty::adjustmentSets().
# Author:       Chris Moreh
# Last updated: 2026-11-19
# Sourced by:   index.qmd (Task 2)
##############################################################################

#   confounder – a common cause of exposure and outcome: adjusting for it
#                removes its bias
#   mediator   – on the path from exposure to outcome: adjusting for it removes
#                part of the total effect
#   collider   – a common effect of two variables: adjusting for it opens a
#                spurious path

# --- Where the nodes sit ----------------------------------------------------
# The exposure on the left, the outcome on the right, the confounders above and
# the arguable nodes below; the coordinates of a node that no arrow names are
# ignored.
coords <- list(
  x = c(unemployment = 0, framing = 3,
        country = 1, year = 2,
        growth = 1.5, bailout = 1.5, politicisation = 3),
  y = c(unemployment = 0, framing = 0,
        country = 1.4, year = 1.4,
        growth = 0.8, bailout = -1.2, politicisation = -0.9)
)

# --- The graph --------------------------------------------------------------
# One arrow per line, as a formula written effect ~ cause: framing ~
# unemployment is the arrow unemployment -> framing. A leading # switches an
# arrow off, with its comma. A node exists only if some arrow names it.
dag <- ggdag::dagify(
  # The causal path of interest.
  framing ~ unemployment,

  # Country-constant traits (history, size, EU tenure): the first confounder
  # pair.
  unemployment ~ country,
  framing ~ country,

  # EU-wide shocks of a year, such as the crisis: the second confounder pair.
  # Country and year fixed effects absorb both pairs, so adjustmentSets()
  # returns { country, year }, the adjustment of the two-way fixed-effects model
  # of Task 3.
  unemployment ~ year,
  framing ~ year,

  # ----- The arguable arrows (Task 2) -----
  # Each is a claim about the world.

  # GROWTH as a time-varying confounder: a slump raises unemployment and may
  # sour EU sentiment in the same year, a back-door path that the fixed effects
  # do not close.
  # unemployment ~ growth,
  # framing ~ growth,

  # BAILOUT as a mediator: unemployment triggers a financial-assistance
  # programme, which then shapes framing.
  # bailout ~ unemployment,
  # framing ~ bailout,

  # POLITICISATION of the EU by parties and elites as a cause of framing alone,
  # with no route into unemployment; the robustness study instructed analysts
  # to disregard it.
  # framing ~ politicisation,

  # Year and country as causes of growth, which matter only with the two growth
  # arrows switched on.
  # growth ~ year,
  # growth ~ country,

  exposure = "unemployment",
  outcome  = "framing",
  coords   = coords
)

# --- Draw it ----------------------------------------------------------------
# Each node a labelled box: the exposure blue, the outcome red, the rest grey.
# The canvas is a tinyplot (McDermott, Arel-Bundock and Zeileis, tinyplot,
# CRAN, doi:10.32614/CRAN.package.tinyplot); the arrows and boxes are base
# graphics.
plot_dag <- function(d = dag) {
  xy <- dagitty::coordinates(d)
  # the nodes named by some arrow
  nodes <- tibble::tibble(name = names(d)) |>
    dplyr::mutate(
      x = xy$x[name], y = xy$y[name],
      fill = dplyr::case_when(name %in% dagitty::exposures(d) ~ "#1b6ca8",
                              name %in% dagitty::outcomes(d) ~ "#d1495b",
                              .default = "grey55"))
  e <- dagitty::edges(d)
  from <- match(e$v, nodes$name)
  to <- match(e$w, nodes$name)
  tinyplot::tinyplot(y ~ x, data = nodes, type = "n", axes = FALSE, frame.plot = FALSE, grid = FALSE,
                     xlab = "", ylab = "", xlim = range(nodes$x) + c(-0.5, 0.5),
                     ylim = range(nodes$y) + c(-0.6, 0.3))
  # each arrow runs from the edge of one box to the edge of the other
  w <- graphics::strwidth(nodes$name, font = 2) / 2 + graphics::strwidth("m")
  h <- graphics::strheight(nodes$name, font = 2) / 2 + graphics::strheight("m") / 2
  dx <- nodes$x[to] - nodes$x[from]
  dy <- nodes$y[to] - nodes$y[from]
  cut_to <- pmin(w[to] / abs(dx), h[to] / abs(dy)) + 0.02
  cut_from <- pmin(w[from] / abs(dx), h[from] / abs(dy))
  graphics::arrows(nodes$x[from] + cut_from * dx, nodes$y[from] + cut_from * dy,
                   nodes$x[to] - cut_to * dx, nodes$y[to] - cut_to * dy,
                   length = 0.1, angle = 20, col = "grey45", lwd = 1.6)
  graphics::rect(nodes$x - w, nodes$y - h, nodes$x + w, nodes$y + h, col = nodes$fill, border = NA)
  graphics::text(nodes$x, nodes$y, nodes$name, col = "white", font = 2)
  graphics::legend("bottom", legend = c("exposure", "outcome"), fill = c("#1b6ca8", "#d1495b"),
                   border = NA, bty = "n", horiz = TRUE)
}
