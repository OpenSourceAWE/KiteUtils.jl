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



it moves every manifest that is not the one for the running Julia to `.bak` (a leftover
`Manifest-v1.10.toml`, an unversioned `Manifest.toml`, a sub-project's),
overwrites the live `Manifest-v<version>.toml` with the tracked
`Manifest-v<version>.toml.default` for the Julia version on the machine,
instantiates, resolves and precompiles. 

Where it resolves a
sub-project and that fails, it names it, carries on, and exits non-zero at the
end. It runs no test suite, builds no system image and no documentation, and
asks nothing. Where Revise is missing from your global environment it warns and
goes on, since `bin/run_julia` runs without it. Where Revise is there, starting
`bin/run_julia` and running the examples its menu offers precompiles nothing
further.

- `--student`, in the repositories used for teaching, also installs Julia where
  it is missing, sets it as the `juliaup` default, adds the alias
  `jl='bin/run_julia'` to `~/.bashrc` where it is not there yet, and adds Revise
  to your global environment where it is missing.
- `-y` changes nothing on its own; with `--student` it answers yes to whatever
  that would ask.
- `--update` resolves instead of installing: `Pkg.update()` against the live
  manifest. The tracked `.default` is left alone.
- `-h` lists the flags.

Only the main project is pinned: the manifests of `examples/`, `test/` and
`docs/` are resolved on the machine that installs them, so two installs of the
same commit may differ there.

LiveServer, which serves the documentation locally, is not `bin/install`'s: a
repository's `bin/build_docu` checks your global environment and asks before
adding it.

## `bin/update_default_manifests`

Moves all the pins at once: it updates every package and writes the resolved
manifests to the tracked `Manifest-v<version>.toml.default` files, one per Julia
version the repository pins, each resolved under that Julia. It is the only
script that changes what everybody else installs, so running it is a pull
request of its own.

## `bin/run_julia`

Starts Julia on the repository for a person at a terminal: its project, its
threads, its system image where the repository builds one, with any arguments
passed through to `julia`. It loads Revise where it is installed and starts
without it, with a warning, where it is not. It never installs or resolves; if
the environment is missing, run `bin/install`. Loading a package whose cache is
stale still makes Julia precompile it, as any `using` does.
