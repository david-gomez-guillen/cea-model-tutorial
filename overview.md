# Screening for a chronic disease

A tutorial model: a Markov cohort of people followed yearly from age 30 to age
70, with a hypothetical chronic disease and screening for it.

## The disease

Every year a share of the healthy develop the disease, a share that grows with
age. Some recover from it without any screening, found through their symptoms,
and people with the disease are more likely to die than people without it. A
year with the disease costs money, and is lived at a lower quality of life.

## Screening

A screen finds a share of the people who have the disease, its sensitivity, and
they are treated and cured. Everyone alive is screened, at a cost per screen,
and each case found costs its treatment.

| Strategy | Screens |
|---|---|
| No screening | None |
| Screening every 5 years | At ages 34, 39, 44 ... 69 |
| Screening every 2 years | At ages 31, 33, 35 ... 69 |
| Yearly screening | Every year |

## Calibration

The incidence of each age group is calibrated to the prevalence of the disease
a survey observed in a population that was not screened.
