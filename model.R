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
    discount <- 1 / (1 + pars$discount.rate)^(year - 1)

    # A screen finds a share of the people with the disease, who are treated
    # and cured. Everyone alive is screened.
    if (!is.na(interval) && year %% interval == 0) {
      detected <- disease * pars$sensitivity
      cost <- cost + discount * ((healthy + disease) * pars$cost.screening +
                                 detected * pars$cost.treatment)
      disease <- disease - detected
      healthy <- healthy + detected
    }
    trace[year, c('healthy', 'disease', 'dead')] <- c(healthy, disease, dead)

    # What the year costs, and its quality of life: 1 for a year in full
    # health, u.disease for a year with the disease.
    cost <- cost + discount * disease * pars$cost.disease
    qalys <- qalys + discount * (healthy + disease * pars$u.disease)

    # The transitions of the year.
    onset <- healthy * pars$p.incidence
    death.healthy <- healthy * pars$p.death
    recovery <- disease * pars$p.recovery
    death.disease <- disease * pars$p.death.disease
    healthy <- healthy - onset - death.healthy + recovery
    disease <- disease + onset - recovery - death.disease
    dead <- dead + death.healthy + death.disease
  }

  list(cost = cost, effectiveness = qalys, trace = trace)
}
