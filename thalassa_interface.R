# What THALASSA reads the model through. These are the three functions every
# model has to define; everything else is optional.

source('model.R')

# The names of the strategies, which is what run.simulation() is asked for.
get.strategies <- function() {
  c('no_screening', 'screening_5y', 'screening_2y', 'screening_1y')
}

# The parameters of the model and the value each takes by default.
get.parameters <- function() {
  list(
    list(name = 'p.incidence', base.value = 0.01),
    list(name = 'p.recovery', base.value = 0.05),
    list(name = 'p.death', base.value = 0.01),
    list(name = 'p.death.disease', base.value = 0.03),
    list(name = 'sensitivity', base.value = 0.75),
    list(name = 'cost.screening', base.value = 150),
    list(name = 'cost.treatment', base.value = 2000),
    list(name = 'cost.disease', base.value = 300),
    list(name = 'u.disease', base.value = 0.85),
    list(name = 'discount.rate', base.value = 0.03)
  )
}

# Simulates each strategy with the parameter values the app gives, a named list,
# and returns their cost (C) and effectiveness (E) in a data frame named summary.
run.simulation <- function(strategies, parameters) {
  results <- lapply(strategies, simulate, pars = parameters)
  summary <- data.frame(
    strategy = strategies,
    C = sapply(results, function(r) r$cost),
    E = sapply(results, function(r) r$effectiveness)
  )
  list(summary = summary)
}

# ---- What the Overview tab shows ---------------------------------------------

# The page of the tutorial for this stage, in Markdown, as the text of the
# Overview tab. Presentation 3 explains this function and the next.
get.overview <- function() {
  readLines('tutorial.md', encoding = 'UTF-8')
}

# This file down to this section, shown in the Code sample section of the
# Overview tab. This section is left out until Presentation 3 explains it.
get.code.sample <- function() {
  code <- readLines('thalassa_interface.R', encoding = 'UTF-8')
  code[seq_len(grep('^# ---- What the Overview tab shows', code) - 2)]
}
