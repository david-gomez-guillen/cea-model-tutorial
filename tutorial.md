# Setup 1: The dependencies of a model

*Stage 11 of 12 of the model integration tutorial, in its block on what
the model needs to run. Each stage is a version of this model: pick
another one in the model bar to move to it. The **Code sample** section
of this tab shows the complete `thalassa_interface.R` of this stage.*

The model is complete, and it reads well. This stage is about something
around it: the packages it needs, and how they get to where the model
runs. It is what most often confuses someone connecting their first
model, so it starts from the beginning. You can read it without changing
anything: for most models, the answer turns out to be that there is
nothing to do.

`model.R` and the results do not change. This version adds one small
file, `thalassa_model.yml`, explained below.

## What a dependency is

A *dependency* is anything your code needs and does not contain. The
model of this tutorial uses ggplot2 for its evaluation plot:

``` r
library(ggplot2)
```

That line works on your computer because ggplot2 is installed on your
computer. It says nothing about where the package comes from, or which
version it is. Run the same line on a computer without ggplot2 and it
fails.

## Where a model runs

THALASSA does not run your model with the R on your computer, and not
with the packages of the app either. Each model runs in an *environment*
of its own: a folder holding a copy of R and exactly the packages that
model needs. The app builds it with conda, a tool that installs software
into such folders. You don’t need to know conda to use this.

Three things follow from this, and they explain most of the surprises:

- **The packages you have installed do not count.** Having a package in
  your own R does not put it in the environment of the model.
- **`try_model.R` does not test the environment.** `Rscript try_model.R`
  runs in your own R, so it can work while the app fails, or the other
  way round. It tells you the model is right. Only loading it in the app
  tells you its dependencies are.
- **Models don’t get in each other’s way.** Two models can use different
  versions of a package, because each has its own.

## What happens when you load a version

1.  The app works out what this version of the model depends on.
2.  If an environment with exactly those dependencies exists, the app
    uses it, and the model loads straight away.
3.  If not, the app builds one. The tabs stay empty meanwhile, with a
    message saying `Preparing the environment of` the model and what it
    is doing, and the rest of the app keeps working. The message says
    this takes seconds, but it can take from under a minute to several
    minutes, depending on how many packages it has to fetch.
4.  When it finishes, the model loads by itself.

This happens once for each set of dependencies. Changing your model’s
code does not build anything, and neither does loading another version
that depends on the same things. Only a change of dependencies builds a
new environment.

## The default: say nothing

If your code loads its packages in the usual way, you don’t have to
declare them. The app reads your code without running it, finds the
packages, and installs them. That is what happened in Presentation
4: it added `library(ggplot2)` and nothing
else.

It recognises these, in `thalassa_interface.R` and in every file it
reaches with `source('some_file.R')`:

| In your code                              | Example                       |
|-------------------------------------------|-------------------------------|
| `library()` or `require()`                | `library(ggplot2)`            |
| `requireNamespace()` or `loadNamespace()` | `requireNamespace('ggplot2')` |
| A function called through its package     | `ggplot2::ggplot(df)`         |

Each package is installed from conda-forge, the collection of software
conda reads from, or from CRAN if conda-forge does not have it. The
latest version available is used, as of the day the environment is
built. The packages that come with R itself, such as `stats` or `utils`,
are never installed separately.

**For most models this is all you need, and you can skip to the section
*Checking that it works*, below.**

### What the app cannot see

It reads your code rather than running it, so it misses a package whose
name is only known when the code runs:

``` r
pkg <- 'ggplot2'
library(pkg, character.only = TRUE)   # not found: the name is in a variable
```

Write `library(ggplot2)` instead. If that is not possible, name the
package under `versions` in `thalassa_model.yml`, as the next section
explains, which installs it whether the code seems to use it or not. A
low minimum, such as `zoo: ">=1.8"`, is enough when you don’t mind which
version it is.

Files are only followed through `source()`. A path it has to compute,
such as `source(file.path('R', 'model.R'))`, cannot be followed, so the
app reads every R file of the repository instead. That finds the
packages, and may install some you no longer use.

## Choosing the versions

Saying nothing means taking the latest version of each package, the day
the environment is built. That is usually fine, until a new release
changes how a package behaves, and the same model built later stops
working or gives other results. Pinning a version prevents that.

Versions are pinned in a file named `thalassa_model.yml`, at the root of
the repository. This is the one this version of the model adds:

``` yaml
# The versions of the packages of this model. Everything else it needs is still
# found in its code.
versions:
  ggplot2: ">=4.0,<5"
```

The evaluation plot was written for ggplot2 4, so this asks for any
version of it, and not for the next major release, whose changes could
break it. Under `versions` goes the name of each package you want to
pin, as many as you need. A version can be written in these ways:

| You write | It means | Use it when |
|----|----|----|
| `dplyr: "1.1.4"` | Exactly this version | The results have to be reproducible exactly |
| `ggplot2: ">=4.0,<5"` | Any version in this range | You want fixes, but not a new major release |
| `R: "4.4.*"` | Any 4.4 version | Choosing the version of R itself, under the name `R` |

A few things to watch for:

- **Always use quotes.** The file format reads `1.10` without quotes as
  the number 1.1, which is another version. The app refuses a version
  with no quotes.
- **Keep the dash of an R version**, as in `zoo: "1.8-12"`.
- **A pinned package is always installed**, even if your code does not
  seem to use it. So this is also the way to add a package the app
  cannot see.
- **An old version may need an old R.** If the environment cannot be
  built after pinning an old package, pin `R` as well, to a version from
  around the same time.
- **Changing a pin builds a new environment**, the next time that
  version is loaded.

## Packages that are only on git

A package you keep in a git repository of your own is on neither
conda-forge nor CRAN, so the app has to be told where it is. This goes
in the same file:

``` yaml
r_packages:
  mypackage:
    git: https://github.com/your-account/mypackage
    ref: v1.2.0     # a tag, a branch or a commit; the default branch if left out
    subdir: .       # where the package is in the repository, if not at its root
```

The name, `mypackage` here, is the name your code loads it by. What the
package imports in its `DESCRIPTION` is installed along with it. Prefer
a tag for `ref`: a branch changes with every commit, and each change
builds a new environment. Its version is chosen by `ref`, and pinning it
under `versions` as well is refused.

## Checking that it works

1.  Run `Rscript try_model.R`. If it fails, the problem is in the model,
    not in its dependencies, and it is easier to read there.
2.  Commit and push your changes: the app reads the repository, not the
    folder on your computer.
3.  In the model bar, use **Refresh repository**, then pick the version.
    Wait for the environment if it has to be built.
4.  If something went wrong, open the **Output** tab, at the right end
    of the tab row. It shows what the model printed, and the error.

These are the problems you are most likely to meet, with what the app
says about them:

| What the app says | What it means | What to do |
|----|----|----|
| `there is no package called 'zoo'`, in a message saying the version `doesn't have a valid thalassa_interface.R` | The code loads a package the environment doesn’t have, because the app could not see it in the code | Load it with a plain `library(zoo)`, or name it under `versions` |
| `Not found on conda-forge nor on CRAN: zoo2` | The name is misspelled, or the package is only on git | Fix the name, or declare it under `r_packages` |
| `The version of 'ggplot2' in thalassa_model.yml has to be a quoted version or range` | A version with no quotes | Add the quotes |
| `could not be built`, with nothing that explains why | The build failed. The message only has its last line | Read the **Output** tab, where the reason is above that line. It is often a pinned version that does not exist, or that needs another version of R |

A package you installed in your own R and forgot about shows up as the
first of these: `try_model.R` works on your computer, and the app does
not.

## Which to use

| What you need | What to do |
|----|----|
| Your code loads its packages in the usual way | Nothing |
| A package the app cannot see in your code | Name it under `versions` in `thalassa_model.yml`, with a low minimum |
| Results that don’t change when packages are updated | Pin versions under `versions` |
| A package that is only on git | Declare it under `r_packages` in `thalassa_model.yml` |
| Another language, a system library, or anything that is not an R package | An `environment.yml`: Setup 2 |

## What works now

The tabs show nothing new: pinning a version changes what the model runs
with, not what it does. The results are the same as in Presentation
4.

The first load of this version may take a moment longer than the last
one, since a pin is a change of dependencies, and builds an environment
of its own.

**Next:** pick the version **setup-2-environment** in the model bar, for
*Setup 2: A conda environment of your own*.
