# Developer notes

## JETLS integration in VS Code

For this project, using JETLS is recommended to catch type and inference issues early while editing Julia code.

Remark: according to this repository's changelog, `JETLS.jl` currently requires Julia 1.12.

### Install JETLS

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

### Required `.vscode/settings.json` content

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

### Project-specific JETLS files

This repository also contains:

- `.JETLSConfig.toml`
- `.JETLSConfig.toml.default`

These files configure diagnostics and formatting behavior for this code base. After checkout from git, run

```bash
cp .JETLSConfig.toml.default .JETLSConfig.toml
```

to get an initial configuration file, that you can then modify according to your needs.

### Run checks from the repository

You can run the helper scripts shipped with this project:

```bash
bin/jetls
bin/jetls_examples
```

They run `jetls check` for `src/` and `examples/` respectively.

## More effective development with AI tools using Kaimon

It is suggested to install Kaimon if you are using AI tools like Claude or Github Copilot. It allows faster
development and reduces the token usage (energy and costs).

See: https://github.com/kahliburke/Kaimon.jl

It is suggested to start **kaimon** before starting VSCode and keep it open in a terminal window.

The `bin/run_julia` script will use it automatically if started.

Sometimes you need to tell the agent manually: "Please, use kaimon!".

### Installation of Kaimon

Install the app:

```julia
]app add Kaimon
```

Run `kaimon --help` to see if it works.

Add `Qdrant` for semantic search:

```bash
#!/bin/bash

# This script starts the Qdrant vector database in a Docker container. It creates a Docker 
# volume named "qdrant_data" to persist the data and runs the container with the appropriate 
# port mapping and restart policy.

# It needs to be executed only once. After that, the Qdrant container will automatically 
# restart on system reboot or if it crashes.

# The data is stored in /var/lib/docker/volumes/qdrant_data/_data/collections

if docker volume inspect qdrant_data &>/dev/null; then
  echo "Volume 'qdrant_data' already exists, skipping setup."
  exit 0
fi

docker volume create qdrant_data

docker run -d \
  --name qdrant \
  --restart unless-stopped \
  -p 6333:6333 \
  -v qdrant_data:/qdrant/storage \
  qdrant/qdrant
```

Install Ollama from [ollama.com](https://ollama.com), then pull the default embedding model:

```bash
ollama pull qwen3-embedding:0.6b
```

The Search tab will show a health indicator for both services. If either is not running, the indicator turns red with an error message.

Before you can search, index the project. From the Search tab press m (manage), than a (add) and enter the path
for each project you want to index. Then press i (index). To index one project might take 10 minutes, but you have
to do that only once.
