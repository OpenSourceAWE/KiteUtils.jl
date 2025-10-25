```@meta
CurrentModule = KiteUtils
```

## Introduction

The [`SystemStructure`](@ref) provides a flexible framework for defining the physical
structure of airborne wind energy (AWE) systems using discrete mass-spring-damper models.
This structure can represent many different AWE system configurations, from simple
single-line kites to complex multi-wing systems with intricate bridle networks.

## Workflow

1. Define system components ([`Point`](@ref), [`Segment`](@ref), [`Group`](@ref), [`BaseWing`](@ref), etc.)
2. Assemble into a [`SystemStructure`](@ref)
3. Initialize component positions using [`Transform`](@ref)s
4. Simulate using [`SymbolicAWEModels.jl`](https://github.com/OpenSourceAWE/SymbolicAWEModels.jl)

## Core Types and Constants

### Simulation Types

```@docs
SimFloat
KVec3
KVec4
SVec3
```

### Public Enumerations

```@docs
SegmentType
DynamicsType
```

## System Components

### Points and Point Dynamics

```@docs
Point
Point(idx, pos_cad, type; wing_idx, vel_w, transform_idx, mass, bridle_damping, fix_sphere)
```

### Wing Deformation Groups

```@docs
Group
Group(idx, point_idxs, le_pos, chord, y_airf, type, moment_frac)
```

### Segments and Connections

```@docs
Segment
Segment(idx, set, point_idxs, type; l0, compression_frac, axial_stiffness, axial_damping)
Segment(idx, point_idxs, axial_stiffness, axial_damping, diameter; l0, compression_frac)
```

### Pulleys and Length Redistribution

```@docs
Pulley
Pulley(idx, segment_idxs, type)
```

### Tethers and Winch Control

```@docs
Tether
Tether(idx, segment_idxs, winch_idx)
Winch
Winch(idx, set::Settings, tether_idxs; tether_len, tether_vel, brake)
Winch(idx, tether_idxs, gear_ratio, drum_radius, f_coulomb, c_vf, inertia_total; tether_len, tether_vel, brake)
```

## Wing Components

### Wing Abstractions and Implementations

```@docs
AbstractWing
BaseWing
```

### Spatial Transformations

```@docs
Transform
Transform(idx, elevation, azimuth, heading; base_point_idx, base_pos, base_transform_idx, wing_idx, rot_point_idx)
Transform(idx, set; wing_idx, rot_point_idx, base_point_idx, base_pos, base_transform_idx)
```

## Complete System Structure

```@docs
SystemStructure
SystemStructure(name, set; points, groups, segments, pulleys, tethers, winches, wings, transforms)
```
