# Presentation 3: Explaining the model

*Stage 9 of 12 of the model integration tutorial, in its block on the
presentation of the model. Each stage is a version of this model: pick
another one in the model bar to move to it. The **Code sample** section
of this tab shows the complete `thalassa_interface.R` of this stage.*

This stage explains the model to the people who use it, in the Overview
tab. Every function here is optional. This tutorial has used two of them
since Logic 1, to show its pages and its code in that
tab.

## The overview

`get.overview()` returns the text of the Overview tab, in Markdown.
Keeping the text in a file of its own makes it easier to edit. This
tutorial uses it to show the page of this stage, which is in
`tutorial.md`:

``` r
# The text of the Overview tab, in Markdown: here, the page of the tutorial for
# this stage. It is read from a file of the repository, by its path relative to
# the directory of the model.
get.overview <- function() {
  readLines('tutorial.md', encoding = 'UTF-8')
}
```

A model of your own returns a description of itself the same way: what
it models, its strategies, and where its values come from. With the
description in a file named `overview.md`, that is:

``` r
get.overview <- function() {
  readLines('overview.md', encoding = 'UTF-8')
}
```

Without it, the Overview tab lists the strategies and parameters, from
the rest of the interface.

## The state diagram

`get.model.states()` describes the states of the model and the
transitions between them, which the Overview tab draws as a diagram. The
model returns plain data, so it needs no plotting package:

``` r
# The states of the model and the transitions between them, which the Overview
# tab draws as a diagram. The descriptions are shown when a state or an arrow is
# hovered.
get.model.states <- function() {
  list(
    nodes = data.frame(
      id = c('healthy', 'disease', 'dead'),
      label = c('Healthy', 'Disease', 'Dead'),
      description = c('Without the disease.', 'With the disease, found or not.', 'Absorbing state.')
    ),
    edges = data.frame(
      from = c('healthy', 'disease', 'disease', 'healthy'),
      to = c('disease', 'healthy', 'dead', 'dead'),
      label = c('Onset', 'Recovery or screening', 'Death', 'Death'),
      description = c('p.incidence', 'p.recovery, and sensitivity in a screening year',
                      'p.death.disease', 'p.death')
    )
  )
}
```

- `nodes` are the states. Only `id` is required; `label` is what the box
  shows.
- `edges` are the transitions, `from` one state `to` another. Their
  `label` is drawn on the arrow.
- A `description`, on either, is shown when the state or the arrow is
  hovered.

The **Model state diagram** section at the top of this tab draws it.
Drag a state to move it, and hover a state or an arrow for its
description.

## A code sample

`get.code.sample()` returns code the Overview tab shows in a section of
its own, to explain how the model works. It is shown and never run, so
it can be a file as it stands, or a simplified version of the real code.
A list gives each sample a tab, headed by its name, and a single sample
needs no list:

``` r
# Code the Overview tab shows, to explain how the model works, a tab per sample.
# It is shown and never run, so it can be a file as it stands, or a simplified
# version of the real code.
get.code.sample <- function() {
  list(
    `thalassa_interface.R` = readLines('thalassa_interface.R', encoding = 'UTF-8'),
    `One year of the cohort` = "# The transitions of one year of the cohort
onset <- healthy * p.incidence
death.healthy <- healthy * p.death
recovery <- disease * p.recovery
death.disease <- disease * p.death.disease
healthy <- healthy - onset - death.healthy + recovery
disease <- disease + onset - recovery - death.disease
dead <- dead + death.healthy + death.disease"
  )
}
```

The **Code sample** section at the top of this tab shows both.

**Next:** pick the version **presentation-4-plots** in the model bar,
for *Presentation 4: Evaluation plots*.
