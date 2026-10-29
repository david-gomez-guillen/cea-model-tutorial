# What THALASSA reads the model through.

source('model.R')

# The units the results are labelled with.
get.model.settings <- function() {
  list(
    cost.unit = '€',
    effectiveness.unit = 'QALY'
  )
}

# The strategies, each with the name run.simulation() is asked for, the name the
# app shows and a description.
get.strategies <- function() {
  list(
    list(name = 'no_screening', display.name = 'No screening',
         description = 'The disease is only found when it causes symptoms.'),
    list(name = 'screening_5y', display.name = 'Screening every 5 years',
         description = 'Everyone is screened at ages 34, 39, 44 and so on.'),
    list(name = 'screening_2y', display.name = 'Screening every 2 years',
         description = 'Everyone is screened at ages 31, 33, 35 and so on.'),
    list(name = 'screening_1y', display.name = 'Yearly screening',
         description = 'Everyone is screened every year.')
  )
}

# The parameters of the model. Besides its name and value, each says what it is
# (display.name), which section it belongs to (class), the range it can take
# (min.value, max.value) and what the PSA draws it from (distribution).
get.parameters <- function() {
  list(
    # Natural history of the disease
    list(name = 'p.incidence', display.name = 'Annual probability of developing the disease',
         base.value = 0.01, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta'),
    list(name = 'p.recovery', display.name = 'Annual probability of recovering without screening',
         base.value = 0.05, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta'),
    list(name = 'p.death', display.name = 'Annual probability of death without the disease',
         base.value = 0.01, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta'),
    list(name = 'p.death.disease', display.name = 'Annual probability of death with the disease',
         base.value = 0.03, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta'),

    # Screening. The DSA varies the sensitivity over the range the literature
    # gives for it, rather than by the percentage set in the DSA tab.
    list(name = 'sensitivity', display.name = 'Sensitivity of the screening test',
         base.value = 0.75, class = 'Screening', min.value = 0, max.value = 1,
         distribution = 'beta', dsa.range = c(0.6, 0.9)),

    # Costs
    list(name = 'cost.screening', display.name = 'Cost of a screen',
         base.value = 150, class = 'Costs', min.value = 0, distribution = 'gamma'),
    list(name = 'cost.treatment', display.name = 'Cost of treating a case found by screening',
         base.value = 2000, class = 'Costs', min.value = 0, distribution = 'gamma'),
    list(name = 'cost.disease', display.name = 'Annual cost of living with the disease',
         base.value = 300, class = 'Costs', min.value = 0, distribution = 'gamma'),

    # Quality of life
    list(name = 'u.disease', display.name = 'Utility of a year with the disease',
         base.value = 0.85, class = 'Quality of life', min.value = 0, max.value = 1,
         distribution = 'beta'),

    # The discount rate is a convention rather than an uncertain value: hidden,
    # the user never sees or changes it.
    list(name = 'discount.rate', base.value = 0.03, hidden = TRUE)
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
