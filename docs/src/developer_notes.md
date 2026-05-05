# Developer notes

## JETLS integration in VS Code

For this project, using JETLS is recommended to catch type and inference issues early while editing Julia code.

Remark: according to this repository's changelog, `JETLS.jl` currently requires Julia 1.12.

## Install JETLS

1. Install Julia 1.12 (or newer) and make sure `julia` is on your PATH.
1. Install the VS Code extension `jetls-client`.
1. Install `JETLS.jl` from the command line:

```bash
julia -e 'using Pkg; Pkg.Apps.add(; url="https://github.com/aviatesk/JETLS.jl", rev="release")'
```

1. Verify the CLI is available:

```bash
jetls --help
```

If this command is not found, ensure your Julia binaries/scripts are on the PATH used by VS Code.

## Required `.vscode/settings.json` content

Use the following configuration in your workspace settings:

```json
{
  "jetls-client.executable": {
    "path": "jetls",
    "threads": "1,0"
  },
  "jetls-client.initializationOptions": {
    "n_analysis_workers": 1
  }
}
```

This configuration tells the extension to run the `jetls` executable and keeps analysis parallelism conservative.

## Project-specific JETLS files

This repository also contains:

- `.JETLSConfig.toml`
- `.JETLSConfig.toml.default`

These files configure diagnostics and formatting behavior for this code base.

## Run checks from the repository

You can run the helper scripts shipped with this project:

```bash
bin/jetls
bin/jetls_examples
```

They run `jetls check` for `src/` and `examples/` respectively.
