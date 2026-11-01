# Setup 2: A conda environment of your own

*Stage 12 of 12 of the model integration tutorial, in its block on what
the model needs to run. Each stage is a version of this model: pick
another one in the model bar to move to it. The **Code sample** section
of this tab shows the complete `thalassa_interface.R` of this stage.*

Setup 1 let the app work out the environment
of the model, with you adding to it where needed. This stage does the
opposite: you write down the whole environment yourself. **Most models
never need this.** If your model only uses R packages, you can skip this
page.

`model.R` and the results do not change. This version replaces the
`thalassa_model.yml` of the last stage with an `environment.yml`.

## When you need it

Use an `environment.yml` when the model needs something that is not an R
package:

- **another language**, whichever it is, when part of the model is
  written in it;
- **a system library**, which some R packages need to be installed
  first, or another program the model runs;
- **a package from a channel other than conda-forge**.

Whatever else the model is written in, `thalassa_interface.R` is always
R: it is what the app reads, and it calls the rest.

If you only want to choose the versions of some R packages, `versions`
in `thalassa_model.yml` does that with less to
maintain.

## The file

`environment.yml` is the standard file conda describes an environment
with, and goes at the root of the repository. This is the one this
version of the model adds:

``` yaml
# Everything this model runs with. The app installs this and nothing else.
channels:
  - conda-forge
dependencies:
  - r-base=4.5
  - r-ggplot2>=4.0,<5
```

Line by line:

- `channels` are where conda looks for packages. conda-forge has most of
  what a model needs.
- `dependencies` lists what to install, one per line.
- `r-base` is R itself. An R package goes by its name in lower case
  after `r-`, so ggplot2 is `r-ggplot2`, and `data.table` is
  `r-data.table`.
- After the name comes the version, written as in `thalassa_model.yml`
  but without quotes: `r-ggplot2>=4.0,<5`.

## What changes when you use one

With this file, the app stops working out what to install. That is the
big difference, and the usual source of trouble:

|  | Saying nothing | With `environment.yml` |
|----|----|----|
| Which packages are installed | Those found in your code | Only those you list |
| You add a `library()` to the code | Installed by itself | **The build fails** until you list it too |
| A package not on conda-forge | Installed from CRAN | **Not found**: CRAN is not used |
| You have to keep up to date | Nothing | The file, by hand |

The app still reads your code, to check the result. If your code uses a
package the environment did not end up with, the build stops. The
message on screen only says `could not be built`, and that a command
`failed with status 1`. The reason is in the **Output** tab, just above
that line:

    Checking that the packages load: ggplot2, callr
    Cannot load ggplot2: there is no package called 'ggplot2'

To fix it, add the package to the file, here as `r-ggplot2`, then commit
and push.

A few more details:

- The file can also be named `environment.yaml`.
- A `name` or a `prefix` in the file is ignored, since the app chooses
  where the environment goes. You can leave them out.
- You don’t have to list what the app itself needs to talk to the model.
  It adds `r-base` and `r-callr` if they are missing.
- A `thalassa_model.yml` still works beside it: packages from git are
  installed on top, and pins apply to anything the file does not list.
  It is simpler to keep every version in one place.

## Using other languages

A model can be written in any language, as long as
`thalassa_interface.R` can call it. There are two usual ways to do that:

- **An R package that connects to the language**, which lets R call that
  code directly. There are such packages for many languages, such as
  reticulate for Python, Rcpp for C++ and JuliaCall for Julia.
- **Running a program**, with `system2()` in R. This works for any
  language: the model runs a command, and reads back what it prints or
  the file it writes. Whatever the environment installs can be run this
  way.

Either way, the file lists what that takes: the language or the program,
what your code in that language uses, and the R package that connects to
it, if there is one. This is what it could look like for a model that
also runs Python code, as one example. It is not part of this version of
the model, which only uses R:

``` yaml
channels:
  - conda-forge
dependencies:
  - r-base=4.5
  - r-reticulate
  - python=3.12
  - numpy
```

`python` and `numpy` have no `r-` in front, since they are not R
packages. Other languages work the same way, with their own entries,
such as `r-rcpp` and `compilers` for C++, `r-juliacall` and `julia` for
Julia, or `openjdk` for a program in Java. Look up the name of anything
else on [conda-forge](https://conda-forge.org/packages/).

## What works now

As in the last stage, the tabs show nothing new and the results are the
same. Load the version and check the **Output** tab if anything goes
wrong: everything in *Checking that it works*, in Setup
1, applies here too.

## Going further

This is the end of the tutorial. The model now uses every part of the
interface most models need. Some features were left out to keep it
short:

- **Groups of strategies**, shown under headings in the tabs, and the
  `style` of a single strategy’s marker.
- **Several state diagrams**, each in a tab of its own.
- An **`initial_guess`** for a calibration scheme, and a
  **`latent_space_training_set`**, for the methods that search a latent
  space.
- Calibration targets in a model **without strata**.

The <a href="https://david-gomez-guillen.github.io/thalassa/docs/reference/thalassa_interface_requirements.html" target="_blank">interface
reference</a> covers every
function and field, and
<a href="https://david-gomez-guillen.github.io/thalassa/docs/reference/thalassa_interface_example.R" target="_blank"><code>thalassa_interface_example.R</code></a>
is a compact example of the whole interface.
