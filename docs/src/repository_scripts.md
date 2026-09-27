# Repository scripts

The Julia packages of the OpenSourceAWE ecosystem carry three scripts in `bin/`
that every user meets: `install`, `update_default_manifests` and `run_julia`.
This page says what each of them does, in any repository that ships it, so that
you know what a command will change before you type it. A repository may need
more than this, a repository used for teaching for instance; its script then
says what it does beyond this page when you pass `-h`.

`<version>` below is a Julia `major.minor`, as in `Manifest-v1.12.toml`.

| Script | Reads | Writes |
| ------ | ----- | ------ |
| `bin/install` | `Manifest-v<version>.toml.default` (tracked) | `Manifest-v<version>.toml` (gitignored), the depot `~/.julia`, what you need outside the repository, see below (not with `-y`) |
| `bin/install --update` | `Project.toml`, `Manifest-v<version>.toml`, the registry | `Manifest-v<version>.toml`, the depot `~/.julia` |
| `bin/update_default_manifests` | `Project.toml`, the registry | every `Manifest-v<version>.toml` and `Manifest-v<version>.toml.default`, the depot `~/.julia` |
| `bin/run_julia` | `Manifest-v<version>.toml` | the depot's precompile cache, where it is stale |

Beyond that, `bin/install` changes what you need outside the repository to work
with it, such as Revise in your global environment where `bin/run_julia` loads
it, the `juliaup` default, or an alias in `~/.bashrc`, and says what it changed.
With `-y` it changes none of these.

## `bin/install`

Makes the repository runnable exactly as it is pinned: it overwrites the live
`Manifest-v<version>.toml` with the tracked `Manifest-v<version>.toml.default`
for the Julia version on the machine, instantiates and precompiles. After it,
starting `bin/run_julia` and running the examples its menu offers precompiles
nothing further. It runs no test suite, builds no system image and no
documentation.

- `-y` runs it without a terminal: no question asked, the Julia already on the
  machine, and nothing prepared for `bin/run_julia`. This is what a CI job or
  another script calls.
- `--update` resolves instead of installing: `Pkg.update()` against the live
  manifest. The tracked `.default` is left alone.
- `-h` lists the flags.

## `bin/update_default_manifests`

Moves all the pins at once: it updates every package and writes the resolved
manifests to the tracked `Manifest-v<version>.toml.default` files, one per Julia
version the repository pins, each resolved under that Julia. It is the only
script that changes what everybody else installs, so running it is a pull
request of its own.

## `bin/run_julia`

Starts Julia on the repository for a person at a terminal: its project, its
threads, its system image where the repository builds one, with any arguments
passed through to `julia`. It never installs or resolves; if the environment is
missing, run `bin/install`. Loading a package whose cache is stale still makes
Julia precompile it, as any `using` does.
