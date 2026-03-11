```@meta
CurrentModule = KiteUtils
```

# KiteUtils

This package is the foundation of Julia Kite Power Tools, which consist of the following packages:

![Julia Kite Power Tools](kite_power_tools.png)

## What to install
If you want to run simulations and see the results in 3D, please install the meta package  [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl) . If you have already KiteSimulators installed, use `using KiteSimulators` instead of `using KiteUtils`.
If you just want to learn how this package works quickly just install only this package.

## Installation

Install [Julia 1.11](https://ufechner7.github.io/2024/08/09/installing-julia-with-juliaup.html) or later, if you haven't already.  You can add KiteUtils from  Julia's package manager, by typing 
```julia
using Pkg
pkg"add KiteUtils"
``` 
at the Julia prompt.

## Testing
You can run the unit tests of this package with the command:
```julia
using Pkg
pkg"test KiteUtils"
```

## Features
- read configuration files, written in .yaml format
- provides the default configuration file [settings.yaml](https://github.com/ufechner7/KiteUtils.jl/blob/main/data/settings.yaml)
- log the system state and read and write log files, memory efficient and fast due to the use of the Apache Arrow format
- present log files in two different formats, one optimized to look at the system state at one point in time, and one that presents per-variable arrays with the time as index
- functions for coordinate system transformations
- provides types for the state of a kite power system, for logfiles and for configuration parameters

## Related
- The meta package [KiteSimulators](https://github.com/aenarete/KiteSimulators.jl) which contains all packages from Julia Kite Power Tools.
- the packages [KiteModels](https://github.com/OpenSourceAWE/KiteModels.jl) and [KitePodModels](https://github.com/aenarete/KitePodModels.jl) and [WinchModels](https://github.com/aenarete/WinchModels.jl) and [AtmosphericModels](https://github.com/OpenSourceAWE/AtmosphericModels.jl)
- the package [KiteControllers](https://github.com/aenarete/KiteControllers.jl) and [KiteViewers](https://github.com/OpenSourceAWE/KiteViewers.jl)
