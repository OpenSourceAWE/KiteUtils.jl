# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# build and display the html documentation locally
# you must have installed the package LiveServer in your global environment

using Pkg

# Check if LiveServer is installed globally
current_project = Pkg.project().path
Pkg.activate()
has_liveserver = "LiveServer" in keys(Pkg.project().dependencies)
Pkg.activate(current_project)

if !has_liveserver
    println("Installing LiveServer globally!")
    run(`julia -e 'using Pkg; Pkg.add("LiveServer")'`)
end

# Activate the docs environment
basepath = dirname(current_project)
docs_path = joinpath(basepath, "docs")
Pkg.activate(docs_path)

# Instantiate to ensure all dependencies are installed
if !isfile(joinpath(docs_path, "Manifest.toml"))
    Pkg.instantiate()
end

using LiveServer; servedocs(launch_browser=true)
