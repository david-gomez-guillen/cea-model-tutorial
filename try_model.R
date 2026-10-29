# Runs the model from R, the way THALASSA does, without the app. Run it from the
# directory of the model, which is where THALASSA runs it from too:
#
#   Rscript try_model.R

source('thalassa_interface.R')

# The parameter list run.simulation() is given: every parameter at its base
# value, and a stratified one as a list with a value per stratum, whether its
# base.value is that list or it has an entry per stratum.
base.parameters <- function() {
  pars <- list()
  for (p in get.parameters()) {
    if (is.list(p$base.value)) {
      pars[[p$name]] <- p$base.value
    } else if (is.null(p$stratum)) {
      pars[[p$name]] <- p$base.value
    } else {
      if (is.null(pars[[p$name]])) pars[[p$name]] <- list()
      pars[[p$name]][[p$stratum]] <- p$base.value
    }
  }
  pars
}

# The names of the strategies, whether get.strategies() returns them as a
# vector or as a list of entries.
strategy.names <- function() {
  strategies <- get.strategies()
  if (is.character(strategies)) strategies else sapply(strategies, function(s) s$name)
}

results <- run.simulation(strategy.names(), base.parameters())
print(results$summary)

# The error of every calibration scheme at the base values, and the output it
# was computed from, for a model that has any.
if (exists('get.calibration.schemes')) {
  for (scheme.name in names(get.calibration.schemes())) {
    scheme <- get.calibration.schemes()[[scheme.name]]
    evaluation <- scheme$error_function(base.parameters(), scheme$target)
    cat('\nScheme', scheme.name, '- error at the base values:', evaluation$error, '\n')
    str(evaluation$output)
  }
}
