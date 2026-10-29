# What THALASSA reads the model through.

source('model.R')

# The units the results are labelled with.
get.model.settings <- function() {
  list(
    cost.unit = '€',
    effectiveness.unit = 'QALY'
  )
}

# The strata of the model: the age groups of model.R.
get.strata <- function() {
  AGE.GROUPS
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

# A constraint on the parameters: the disease cannot make death less likely.
# It returns TRUE when the values are acceptable, and the message the app shows
# when they are not. unlist() reads a parameter the user has split into age
# groups as all its values.
death.more.likely.with.disease <- function(par.name, params) {
  if (any(unlist(params$p.death.disease) <= unlist(params$p.death)))
    'The probability of death with the disease must be above the one without it'
  else TRUE
}

# The parameters of the model. Besides its name and value, each says what it is
# (display.name), which section it belongs to (class), the range it can take
# (min.value, max.value) and what the PSA draws it from (distribution).
get.parameters <- function() {
  list(
    # Natural history of the disease. The incidence grows with age, so it is
    # stratified: its base.value is a list with a value per age group.
    list(name = 'p.incidence', display.name = 'Annual probability of developing the disease',
         base.value = list(`30-39` = 0.004, `40-49` = 0.008, `50-59` = 0.015, `60-69` = 0.025),
         class = 'Natural history', min.value = 0, max.value = 1, distribution = 'beta'),
    list(name = 'p.recovery', display.name = 'Annual probability of recovering without screening',
         base.value = 0.05, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta'),
    # The constraint is declared on both parameters it involves, so the app
    # points at both, whichever of them the user changes.
    list(name = 'p.death', display.name = 'Annual probability of death without the disease',
         base.value = 0.01, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta', constraints = death.more.likely.with.disease),
    list(name = 'p.death.disease', display.name = 'Annual probability of death with the disease',
         base.value = 0.03, class = 'Natural history', min.value = 0, max.value = 1,
         distribution = 'beta', constraints = death.more.likely.with.disease),

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

# ---- Calibration ------------------------------------------------------------

# The error of a simulated output: how far the prevalence of each age group is
# from the one observed, as a sum of squared relative differences. It needs the
# output and the target alone, without running the model.
prevalence.error <- function(output, target) {
  observed <- unlist(target$prevalence)
  simulated <- output$prevalence[names(observed)]
  sum(((simulated - observed) / observed)^2)
}

# The error of a parameter set: simulates it and scores the output. The survey
# was taken in a population that is not screened, so the reference strategy is
# what is simulated.
prevalence.calibration.error <- function(parameters, target) {
  trace <- simulate('no_screening', parameters)$trace
  output <- list(prevalence = prevalence.by.age(trace))
  list(error = prevalence.error(output, target), output = output)
}

# The calibrations the Calibration tab offers. This one finds the incidence of
# each age group that reproduces the prevalence a survey observed.
get.calibration.schemes <- function() {
  list(
    prevalence = list(
      description = 'Incidence by age, from the prevalence of a survey',
      parameters = c('p.incidence'),
      strata = AGE.GROUPS,
      target = list(
        prevalence = list(`30-39` = 0.012, `40-49` = 0.040, `50-59` = 0.085, `60-69` = 0.150)
      ),
      error_function = prevalence.calibration.error,
      output_error = prevalence.error,
      # The search is kept where the incidence does not fall with age. x holds
      # the incidence of each age group, in the order of AGE.GROUPS, and each
      # value returned is a constraint, met when it is 0 or less: here, minus
      # the increase from one age group to the next.
      constraints = function(x, partial = FALSE) {
        # A stepwise calibration goes one age group at a time and asks about
        # the ones it has so far. The first step has nothing to compare yet:
        # the -1, always met, still gives it a constraint.
        if (partial) return(c(-1, -diff(x)))
        -diff(x)
      },
      # The same, in words: shown in the tab and given to the agentic method.
      constraints_description = function() {
        'The incidence must not decrease from one age group to the next.'
      }
    )
  )
}
