# Repository scripts

The Julia packages of the OpenSourceAWE ecosystem share three scripts in `bin/`
that are useful for any package: `install`, `update_default_manifests` and `run_julia`.
This page explains there purpose.

## Background
We use packages that not only contain their source code folder, but also a number of 
sub-projects, typically at least
- test
- examples
- docs

Each of the sub-projects usually has his own `Project.toml` file to define additional
dependencies needed for the specific purpose, e.g. running the tests, running the examples
or creating the html documentation.

To achieve reproducible results a consistent set of dependencies is defined in one manifest
file per Julia version. The two manifest files for the latest two stable Julia versions
are checked into the git repository.

The scripts explained here are mainly intended to be used when a package is checked out
using git, and usually not used when a package is used as dependency of another project.
They are bash scripts, living in the bin directory.

## The install script

The `install` scripts makes the package and its examples usable with the tested package versions. It has two use cases: Firstly, for the package developers to get a consistent state after a checkout or a switched branch. And secondly for students/ researchers who
want to learn and study the examples.

### For package developers
Without any parameters or dialog the script shall make a new checkout/ branch quickly ready to use. For this purpose:
- check if a supported Julia version is installed and terminate otherwise
- it shall create a backup of any existing manifest files that are not longer needed
- it shall copy the default manifest for the active Julia version to the manifest in the root folder that will be used
- resolve, instantiate and precompile the main package environment and the examples environment

It shall terminate with an error code if any of the steps fails.

**Open questions:**
- shall the test environment be instantiated by default
- shall the docs environment be instantiated by default

### For end users
Invoked as `./install -i` it shall first check if `juliaup` is installed and sufficient disk space available and terminate if not. If the preconditions are fulfilled, it shall provide a dialog with the following options:
- install a supported Julia version if none is installed yet
- select a different supported Julia version than the version currently active
- add an alias for `jl` to the `.bashrc` file (or other files if another shell than BASH is used)
- instantiate the test environment or not
- instantiate the docs environment or not
- run the tests or not
