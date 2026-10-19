# Repository scripts

The Julia packages of the OpenSourceAWE ecosystem share three scripts in `bin/`
that are useful for any package: `install`, `run_julia` and `update_default_manifests`.
This page explains their purpose. It is a guideline: a repository may deviate from it in
small ways where it has a reason to, and says so in the script's help text.

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
- copy each default configuration file, such as `.JETLSConfig.toml.default`, to its local name without the `.default` suffix (here `.JETLSConfig.toml`), but only if the local file does not exist yet, so that local changes are kept; the local files are not tracked by git
- resolve, which fixes small issues such as a pinned version that is not yet available on every package server
- instantiate the manifest and precompile the main package environment and the examples environment

The `install` script shall terminate with an error code if any of these steps fails.

Moving all package versions to the latest is not the job of `install` but of `update_default_manifests`.

The test and docs environments shall not be precompiled by default.

Unless invoked with `-i`, it shall not change anything outside the repository, except the Julia depot: there it adds the packages it installs and their precompiled files, and it may delete stale precompiled files of the package to force fresh precompilation.

### For end users
Invoked as `bin/install -i`, it shall first check if `juliaup` is installed and sufficient disk space is available, and terminate if not. If the preconditions are fulfilled, it shall provide a dialog with the following options:
- install a supported Julia version if none is installed yet
- select a different supported Julia version than the version currently active
- add an alias `jl` to the `.bashrc` file (or other files if a shell other than Bash is used)
- precompile the test environment or not
- precompile the docs environment or not
- run the tests or not
- install Revise in the global environment or not

## The run_julia script
Both developers and end users should use it, unless they have found a better way to start Julia.
Usually it is started with the alias `jl`, which makes it easy to launch and re-launch the Julia REPL.

**Purpose:**

- set environment variables if needed
- assemble the parameters for starting Julia:
  - first, the parameter `--project` to use the local project file
  - then, parameters for multi-threading and multi-processing as needed by the project
  - a custom system image, if one is available
  - loading Revise before the package, if Revise is available, e.g. in the global environment, so that changes to the source code take effect without restarting Julia
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

**Resolve, then fall back to update:** where the script only brings a manifest in line
with the `Project.toml` files instead of updating everything, it shall not rely on
`Pkg.resolve()` alone. `Pkg.resolve()` keeps every package at the version the manifest
already records, so it fails with an error like `empty intersection between
MakieControlPlots@0.1.16 and project compatibility 0.1.20 - 0.1` as soon as a manifest pins a
package below a raised compat floor. This is the normal state of the manifest of the
Julia version that is not used day to day, which falls behind while the other one is
kept current. On that error the script shall warn and run `Pkg.update()` for that
Julia version instead:

```bash
julia +"$julia_major" --project=examples -e 'using Pkg
    try Pkg.resolve() catch
        @warn "Resolve failed, the manifest is below a compat floor; updating instead"
        Pkg.update()
    end
    Pkg.instantiate(); Pkg.precompile()'
```

Without this fallback, the script stops on the first stale manifest and the default
manifests cannot be refreshed at all.

## Parameters
All scripts shall support the following parameters:
- `-h`
- `--help`
Both shall print a help text, explaining the purpose and usage of the script.

`bin/install` shall also accept `-y`, for automation without a terminal: it shall behave as without parameters and never prompt.
