# Repository scripts

The Julia packages of the OpenSourceAWE ecosystem carry three scripts in `bin/`
that every user meets: `install`, `update_default_manifests` and `run_julia`.
This page says what each of them does, in any repository that ships it, so that
you know what a command will change before you type it. A repository may ship
none of the three, and may offer more than this page; its `-h` says what.

`<version>` below is a Julia `major.minor`, as in `Manifest-v1.12.toml`.

| Script | Reads | Writes |
| ------ | ----- | ------ |
| `bin/install` | `Manifest-v<version>.toml.default` (tracked) | `Manifest-v<version>.toml` (gitignored), `.bak` of every other manifest, the depot `~/.julia` |
| `bin/install --student` | as above | as above, and Julia, an alias in `~/.bashrc`, Revise in your global environment |
| `bin/install --update` | `Project.toml`, `Manifest-v<version>.toml`, the registry | `Manifest-v<version>.toml`, the depot `~/.julia` |
| `bin/update_default_manifests` | `Project.toml`, the registry | every `Manifest-v<version>.toml` and `Manifest-v<version>.toml.default`, the depot `~/.julia` |
| `bin/run_julia` | `Manifest-v<version>.toml` | the depot's precompile cache, where it is stale |

`bin/install` and `bin/install -y` are the same command, and change nothing
outside the repository but the depot. Only `--student`, in a repository used
for teaching, does.

## `bin/install`

Makes the repository runnable exactly as it is pinned: it moves every manifest
that is not the one for the running Julia to `.bak` (a leftover
`Manifest-v1.10.toml`, an unversioned `Manifest.toml`, a sub-project's),
overwrites the live `Manifest-v<version>.toml` with the tracked
`Manifest-v<version>.toml.default` for the Julia version on the machine,
instantiates and precompiles. It reproduces the pinned setup rather than
computing one, so it does not resolve the main project. Where it resolves a
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
