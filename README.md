# KiteUtils

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://OpenSourceAWE.github.io/KiteUtils.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://OpenSourceAWE.github.io/KiteUtils.jl/dev)
[![Build Status](https://github.com/OpenSourceAWE/KiteUtils.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/OpenSourceAWE/KiteUtils.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/OpenSourceAWE/KiteUtils.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/OpenSourceAWE/KiteUtils.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Utilities for simulating kite power systems.

This package is the foundation of Julia Kite Power Tools, which consist of the following packages:
<p align="center"><img src="https://github.com/aenarete/WinchModels.jl/blob/main/docs/kite_power_tools.png" width="500" /></p> 

## What to install
If you want to run simulations and see the results in 3D, please install the meta package  [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl) . If you have already KiteSimulators installed, use `using KiteSimulators` instead of `using KiteUtils`.
If you just want to learn how this package works quickly just install only this package.

## Installation
If you have not yet installed Julia 1.10 or newer, follow these [installation instructions](https://ufechner7.github.io/2024/08/09/installing-julia-with-juliaup.html). You can add KiteUtils from  Julia's package manager, by typing 
```julia
using Pkg
pkg"add KiteUtils"
``` 
at the Julia prompt. You can run the unit tests by typing:
```julia
pkg"test KiteUtils"
```

### Creating a project and installing the examples
You can create a demo project by typing:
```bash
mkdir demo
cd demo
julia --project=.
```
and then, on the Julia prompt type:
```julia
using Pkg
pkg"add KiteUtils"
KiteUtils.install_examples()
```
This creates the folders `data` and `examples`. You can view and modify the examples with a text editor of your choice, e.g. [notepad++](https://notepad-plus-plus.org/) if you are using Windows or `gedit` on Linux. You can execute them by typing:
```julia
menu()
```
and select one of the examples with the cursor keys and press enter.

## Provides 
- functions for coordinate system transformations
- functions for reading configuration files
- the default configuration file [settings.yaml](data/settings.yaml)
- the default meta-configuration file [system.yaml](data/system.yaml)
- functions for logging, reading and writing log files
- types for the state of a kite power, logging and configuration parameters
- a function for calculation the inertia matrix of a kite

## Licence
This project is licensed under the MIT License. The documentation is licensed under the CC-BY-4.0 License. Please see the below `Copyright notice` in association with the licenses that can be found in the file [LICENSE](LICENSE) in this folder.

## Copyright notice
Technische Universiteit Delft hereby disclaims all copyright interest in the package “KiteModels.jl” (models for airborne wind energy systems) written by the Author(s).

Prof.dr. H.G.C. (Henri) Werij, Dean of Aerospace Engineering, Technische Universiteit Delft.

See the copyright notices in the source files, and the list of authors in [AUTHORS.md](AUTHORS.md).

## Related
- The meta package [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl) which contains all packages from Julia Kite Power Tools.
- the packages [KiteModels](https://github.com/OpenSourceAWE/KiteModels.jl) and [KitePodModels](https://github.com/aenarete/KitePodModels.jl) and [WinchModels](https://github.com/aenarete/WinchModels.jl) and [AtmosphericModels](https://github.com/aenarete/AtmosphericModels.jl)
- the packages [KiteControllers](https://github.com/aenarete/KiteControllers.jl) and [KiteViewers](https://github.com/aenarete/KiteViewers.jl)

**Documentation** [Stable Version](https://OpenSourceAWE.github.io/KiteUtils.jl/stable) [Development Version](https://OpenSourceAWE.github.io/KiteUtils.jl/dev)

Authors: Uwe Fechner (uwe.fechner.msc@gmail.com), Bart van de Lint (bart@vandelint.net),
