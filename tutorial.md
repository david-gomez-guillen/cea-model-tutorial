# Presentation 4: Plots

*Stage 10 of 12 of the model integration tutorial, in its block on the
presentation of the model. Each stage is a version of this model: pick
another one in the model bar to move to it. The **Code sample** section
of this tab shows the complete `thalassa_interface.R` of this stage.*

This stage draws plots of its own: curves of the cohort in the Base case
tab, and a plot of each evaluation in the Calibration tab. So far the
model has used base R alone, and the second needs a package, ggplot2.

## Plots of the base case

The Base case tab compares the strategies by their cost and
effectiveness. How the cohort got there is in the trace of each
simulation, which the model can draw too. `run.simulation()` takes a
third argument, `make.plots`, and when it is `TRUE` it returns the plots
of each strategy under `plots`, keyed by the name of the strategy:

``` r
# Simulates each strategy with the parameter values the app gives, a named list,
# and returns their cost (C) and effectiveness (E) in a data frame named summary.
# With make.plots, which only the Base case tab sets, it also returns the plots
# of each strategy, keyed by its name.
run.simulation <- function(strategies, parameters, make.plots = FALSE) {
  results <- lapply(strategies, simulate, pars = parameters)
  summary <- data.frame(
    strategy = strategies,
    C = sapply(results, function(r) r$cost),
    E = sapply(results, function(r) r$effectiveness)
  )
  output <- list(summary = summary)
  if (make.plots) output$plots <- setNames(lapply(results, function(r) strategy.plots(r$trace)), strategies)
  output
}
```

- Only the Base case tab sets `make.plots`. A calibration, a DSA or a
  PSA runs the model many times, and leaves it `FALSE` so that it spends
  no time on plots.
- `make.plots` has to default to `FALSE`, since every other caller
  leaves it out. A model whose `run.simulation()` does not have the
  argument is never given it.

The plots of a strategy are a list, each under the title of its tab:

``` r
# The plots the Base case tab shows of one strategy, from the trace of its
# simulation, each under the title of its tab. A numeric vector is one line, its
# names being the x axis. A data frame has the x axis in its first column and a
# line in each of the others.
strategy.plots <- function(trace) {
  list(
    Prevalence = setNames(trace$disease / (trace$healthy + trace$disease), trace$age),
    `Cohort by state` = data.frame(Age = trace$age, Healthy = trace$healthy,
                                   Disease = trace$disease, Dead = trace$dead)
  )
}
```

- A numeric vector is one line, and its names are the x axis: here the
  prevalence at each age.
- A data frame has the x axis in its first column, whose name titles the
  axis, and a line in each of the others: here the share of the cohort
  in each state.

Each is a tab of the *Model plots* box, under the outcomes table, with a
button for each strategy under the tabs. Every strategy is drawn on the
same vertical axis, so going from one to the next shows what screening
changes. The prevalence of a screening strategy drops at every screen:

<figure style="margin: 15px 0;">
<img src="https://raw.githubusercontent.com/david-gomez-guillen/cea-model-tutorial/presentation-4-plots/images/presentation4_basecase.png" alt="The model plots of the base case" style="max-width: 100%;" />
<figcaption style="font-style: italic;">The model plots of the base case</figcaption>
</figure>

## An evaluation plot

The Calibration tab plots the outputs of each evaluation against the
target. A scheme can add plots of its own, of whatever else helps judge
an evaluation. The base values of the incidence were a guess, so this
one draws the incidence an evaluation tried in each age group next to
them:

``` r
# A plot of one evaluation of a calibration: the incidence it tried in each age
# group, next to the base value of that group. The Calibration tab draws it under
# the calibration curve, for the evaluation hovered on the error plot. `values` holds
# the calibrated parameters and the simulated outputs of that evaluation, the
# incidence of an age group named as p.incidence.<age group>.
incidence.plot <- function(values) {
  incidence <- Filter(function(p) p$name == 'p.incidence', get.parameters())[[1]]
  base <- unname(unlist(incidence$base.value)[AGE.GROUPS])
  tried <- unname(values[paste0('p.incidence.', AGE.GROUPS)])
  df <- data.frame(group = rep(AGE.GROUPS, 2),
                   series = rep(c('This evaluation', 'Base value'), each = length(AGE.GROUPS)),
                   incidence = c(tried, base))
  # The app shows the text aesthetic when a point is hovered.
  df$text <- sprintf('Age %s, %s: %.4f', df$group, tolower(df$series), df$incidence)
  ggplot(df, aes(x = group, y = incidence, colour = series, group = series, text = text)) +
    geom_line() +
    geom_point() +
    scale_colour_manual(values = c(`This evaluation` = 'black', `Base value` = 'grey60')) +
    labs(x = 'Age group', y = 'Annual incidence', colour = NULL) +
    theme_minimal()
}
```

- The function receives the values of one evaluation, as a named vector:
  the calibrated parameters, named `<parameter>.<stratum>`, and the
  simulated outputs.
- It returns a ggplot. The app turns it into an interactive plot, which
  shows the `text` aesthetic when a point is hovered.
- It has to draw the same elements for every evaluation, since hovering
  moves the values of the plot on screen rather than drawing it again.

The scheme lists its plots under `evaluation.plots`, each under the
title the tab shows it by:

``` r
      # Plots of one evaluation, each under the title it is listed by.
      evaluation.plots = list(`Incidence against its base value` = incidence.plot)
```

The plot follows the evaluation hovered, or clicked, on the error plot.
Here the best evaluation puts the incidence of every age group about a
fifth below its base value:

<figure style="margin: 15px 0;">
<img src="https://raw.githubusercontent.com/david-gomez-guillen/cea-model-tutorial/presentation-4-plots/images/presentation4_calibration.png" alt="The evaluation plot under the calibration plots" style="max-width: 100%;" />
<figcaption style="font-style: italic;">The evaluation plot under the calibration plots</figcaption>
</figure>

## The package it needs

The interface now loads ggplot2, in the usual way:

``` r
library(ggplot2)
```

Nothing else was needed: the app sees that line and installs the
package. Setup 1 explains how, and what to do
when that is not enough.

**Next:** pick the version **setup-1-dependencies** in the model bar,
for *Setup 1: The dependencies of a model*.
