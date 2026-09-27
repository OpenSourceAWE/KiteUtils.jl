# Repository scripts

The Julia packages of the OpenSourceAWE ecosystem carry up to three scripts in
`bin/`. This page says what each of them does, in any repository that ships it,
so that you know what a command will change before you type it. A repository
either ships a script that does what is written here or does not ship it at all.

| Script | Reads | Writes |
| ------ | ----- | ------ |
| `bin/install` | `Manifest-v<major>.toml.default` (tracked) | `Manifest-v<major>.toml` (gitignored), the depot `~/.julia` |
| `bin/install --update` | `Manifest-v<major>.toml` | `Manifest-v<major>.toml`, the depot `~/.julia` |
| `bin/update_default_manifests` | `Project.toml` | every `Manifest-v<major>.toml.default` |
| `bin/run_julia` | `Manifest-v<major>.toml` | nothing |

None of them changes anything else on your machine unless you ask for it with a
flag: no `juliaup default`, no package added to your global environment, no line
appended to `~/.bashrc`, nothing deleted under `~/.julia`. A script may print the
command that would make such a change, for you to run yourself. Where a
repository offers such a flag, `-h` names it.

## `bin/install`

Makes the repository runnable exactly as it is pinned: it overwrites the live
`Manifest-v<major>.toml` with the tracked `Manifest-v<major>.toml.default` for
the Julia version on the machine, instantiates and precompiles. It runs no test
suite, builds no system image and no documentation.

- `-y` runs it without a terminal: no menu, no question, the Julia already on the
  machine. This is what a CI job or another script calls.
- `--update` resolves instead of installing: `Pkg.update()` against the live
  manifest. The tracked `.default` is left alone.
- `-h` lists the flags.

## `bin/update_default_manifests`

Moves all the pins at once: it updates every package and writes the resolved
manifests to the tracked `Manifest-v<major>.toml.default` files, one per Julia
version the repository pins, each resolved under that Julia. It is the only
script that changes what everybody else installs, so running it is a pull
request of its own.

## `bin/run_julia`

Starts Julia on the repository for a person at a terminal: its project, its
threads, its system image where the repository builds one, with any arguments
passed through to `julia`. It never installs, resolves or precompiles; if the
environment is missing, run `bin/install`.
