# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils
using Pkg
if ("TestEnv" ∈ keys(Pkg.project().dependencies))
    if ! ("Documents" ∈ keys(Pkg.project().dependencies))
        using TestEnv; TestEnv.activate()
    end
end
using Documenter

DocMeta.setdocmeta!(KiteUtils, :DocTestSetup, :(using KiteUtils); recursive=true)

makedocs(;
    modules=[KiteUtils],
    authors="Uwe Fechner <uwe.fechner.msc@gmail.com> and contributors",
    repo="https://github.com/OpenSourceAWE/KiteUtils.jl/blob/{commit}{path}#{line}",
    sitename="KiteUtils.jl",
    # checkdocs=:none,
    format=Documenter.HTML(;
      repolink = "https://github.com/OpenSourceAWE/KiteUtils.jl",
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://OpenSourceAWE.github.io/KiteUtils.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference frames" => "reference_frames.md",
        "Exported Functions" => "functions.md",
        "Exported Types" => "types.md",
        "Examples" => "examples.md",
    ],
)

deploydocs(;
    repo="github.com/OpenSourceAWE/KiteUtils.jl",
    devbranch="main",
)
