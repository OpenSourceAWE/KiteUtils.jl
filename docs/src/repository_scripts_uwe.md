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

### For end users
