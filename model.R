# A Markov cohort model of a hypothetical chronic disease, followed from age 30
# to age 70, and of screening for it.
#
# A cohort model does not follow people one by one. It keeps the share of a
# group of people, the cohort, that is in each health state, and once a year
# moves part of each share to another state. Along the way it adds up what the
# cohort costs and the health it enjoys, which is what a cost-effectiveness
# analysis compares between strategies.
#
#   States:      healthy, disease, dead
#   Cycle:       one year
#   Strategies:  no screening, or a screen every 5, 2 or 1 years
#
# This file knows nothing about THALASSA: thalassa_interface.R is what connects
# the two.

START.AGE <- 30
HORIZON <- 40

# The age groups, which are the strata of the model: a parameter can take a
# different value in each.
AGE.GROUPS <- c('30-39', '40-49', '50-59', '60-69')

age.group <- function(age) AGE.GROUPS[(age - START.AGE) %/% 10 + 1]

# The value of a parameter in an age group. A stratified parameter is a list
# with a value per age group, and any other is a single number, so every
# parameter is read through at(): the Parameters tab lets the user split any of
# them into age groups.
at <- function(value, group) if (is.list(value)) value[[group]] else value

# Years between two screens of each strategy, NA for no screening.
SCREENING.INTERVAL <- c(no_screening = NA, screening_5y = 5, screening_2y = 2, screening_1y = 1)

# Simulates one strategy with the parameter values in `pars`, a named list.
# Returns the discounted cost and QALYs of the cohort, and its trace: the share
# of the cohort in each state at the start of every year.
simulate <- function(strategy, pars) {
  interval <- SCREENING.INTERVAL[[strategy]]
  healthy <- 1
  disease <- 0
  dead <- 0
  cost <- 0
  qalys <- 0
  trace <- data.frame(year = 1:HORIZON, age = START.AGE + 0:(HORIZON - 1),
                      healthy = NA, disease = NA, dead = NA)

  for (year in 1:HORIZON) {
    group <- age.group(START.AGE + year - 1)
    discount <- 1 / (1 + pars$discount.rate)^(year - 1)

    # A screen finds a share of the people with the disease, who are treated
    # and cured. Everyone alive is screened.
    if (!is.na(interval) && year %% interval == 0) {
      detected <- disease * at(pars$sensitivity, group)
      cost <- cost + discount * ((healthy + disease) * at(pars$cost.screening, group) +
                                 detected * at(pars$cost.treatment, group))
      disease <- disease - detected
      healthy <- healthy + detected
    }
    trace[year, c('healthy', 'disease', 'dead')] <- c(healthy, disease, dead)

    # What the year costs, and its quality of life: 1 for a year in full
    # health, u.disease for a year with the disease.
    cost <- cost + discount * disease * at(pars$cost.disease, group)
    qalys <- qalys + discount * (healthy + disease * at(pars$u.disease, group))

    # The transitions of the year.
    onset <- healthy * at(pars$p.incidence, group)
    death.healthy <- healthy * at(pars$p.death, group)
    recovery <- disease * at(pars$p.recovery, group)
    death.disease <- disease * at(pars$p.death.disease, group)
    healthy <- healthy - onset - death.healthy + recovery
    disease <- disease + onset - recovery - death.disease
    dead <- dead + death.healthy + death.disease
  }

  list(cost = cost, effectiveness = qalys, trace = trace)
}

# The share of the people alive who have the disease, averaged over the years
# of each age group, from the trace of a simulation. This is what the
# calibration compares with the prevalence observed in a survey.
prevalence.by.age <- function(trace) {
  prevalence <- trace$disease / (trace$healthy + trace$disease)
  groups <- age.group(trace$age)
  sapply(AGE.GROUPS, function(group) mean(prevalence[groups == group]))
}
