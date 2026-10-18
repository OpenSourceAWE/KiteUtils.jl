# Repository scripts

The Julia packages of the OpenSourceAWE ecosystem share three scripts in `bin/`
that are useful for any package: `install`, `run_julia` and `update_default_manifests`.
This page explains their purpose.

## Background
We use packages that not only contain their source code folder, but also a number of
sub-projects, typically at least
- test
- examples
- docs

Each of the sub-projects usually has its own `Project.toml` file to define additional
dependencies needed for the specific purpose, e.g. running the tests, running the examples
or creating the HTML documentation.

To achieve reproducible results, a consistent set of dependencies is defined in one manifest
file per Julia version. The two manifest files for the latest two stable Julia versions
are checked into the git repository.

The scripts explained here are mainly intended to be used when a package is checked out
using git, and usually not when a package is used as a dependency of another project.
They are Bash scripts, living in the `bin/` directory.

## The install script

The `install` script makes the package and its examples usable with the tested package versions. It has two use cases: first, for package developers to get a consistent state after a checkout or a branch switch; second, for students/researchers who
want to learn and study the examples.

### For package developers
Without any parameters or dialog, the script shall quickly make a new checkout/branch ready to use. For this purpose, it shall:
- check if a supported Julia version is installed and terminate otherwise
- create a backup of any existing manifest files that are no longer needed
- copy the default manifest for the active Julia version to the manifest in the root folder that will be used
- instantiate the manifest and precompile the main package environment and the examples environment

It shall not resolve: if the default manifest does not satisfy `Project.toml`, it shall say so, so that the default manifest gets fixed. Moving package versions is the job of `update_default_manifests`.

It shall terminate with an error code if any of the steps fails.

The test and docs environments shall not be precompiled by default. They share the manifest of the main package, so instantiating it already downloads their dependencies.

Unless invoked with `-i`, it shall not change anything outside the repository, except the Julia depot.

### For end users
Invoked as `bin/install -i`, it shall first check if `juliaup` is installed and sufficient disk space is available, and terminate if not. If the preconditions are fulfilled, it shall provide a dialog with the following options:
- install a supported Julia version if none is installed yet
- select a different supported Julia version than the version currently active
- add an alias `jl` to the `.bashrc` file (or other files if a shell other than Bash is used)
- precompile the test environment or not
- precompile the docs environment or not
- run the tests or not

## The run_julia script
Both developers and end users should use it, unless they have found a better way to start Julia.
Usually it is started with the alias `jl`, which makes it easy to launch and re-launch the Julia REPL.

**Purpose:**

- set environment variables if needed
- assemble the parameters for starting Julia:
  - first, the parameter `--project` to use the local project file
  - then, parameters for multi-threading and multi-processing as needed by the project
  - a custom system image, if one is available
  - convenience functions like `menu()` and `menu2()`, if needed

The script shall allow passing extra parameters or a script name to Julia.

## The update_default_manifests script

This script is intended for developers only. It should be executed before creating a new
release, but sometimes it is also useful after creating a new branch.

**Purpose:**

- update all packages to the latest version, separately for both supported Julia versions
- run the tests
- if the tests pass, create or overwrite the default manifests and commit them
- terminate if the tests fail

## Parameters
All scripts shall support the following parameters:
- `-h`
- `--help`
Both shall print a help text, explaining the purpose and usage of the script.

`bin/install` shall also accept `-y`, for automation without a terminal: it shall behave as without parameters and never prompt.
