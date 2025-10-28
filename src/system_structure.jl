# Copyright (c) 2025 Bart van de Lint
# SPDX-License-Identifier: MIT

"""
    const SimFloat = Float64

This type is used for all real variables used in simulations.
"""
const SimFloat = Float64

"""
   const KVec3 = MVector{3, SimFloat}

Basic 3-dimensional vector, stack allocated, mutable.
"""
const KVec3 = MVector{3, SimFloat}

"""
   const KVec4 = MVector{4, SimFloat}

Basic 4-dimensional vector, stack allocated, mutable.
"""
const KVec4 = MVector{4, SimFloat}

"""
   const SVec3 = SVector{3, SimFloat}

Basic 3-dimensional vector, stack allocated, immutable.
"""
const SVec3 = SVector{3, SimFloat}

"""
    SegmentType `POWER_LINE` `STEERING_LINE` `BRIDLE`

Enumeration for the type of a tether segment.

# Elements
- `POWER_LINE`: A segment belonging to a main power line.
- `STEERING_LINE`: A segment belonging to a steering line.
- `BRIDLE`: A segment belonging to the bridle system.
"""
@enum SegmentType begin
    POWER_LINE
    STEERING_LINE
    BRIDLE
end

"""
    DynamicsType `DYNAMIC` `QUASI_STATIC` `WING` `STATIC`

Enumeration for the dynamic model governing a point's motion.

# Elements
- `DYNAMIC`: The point is a dynamic point mass, moving according to Newton's second law.
- `QUASI_STATIC`: The point's acceleration is constrained to zero, representing a force equilibrium.
- `WING`: The point is rigidly attached to a wing body and moves with it.
- `STATIC`: The point's position is fixed in the world frame.
"""
@enum DynamicsType begin
    DYNAMIC
    QUASI_STATIC
    WING
    STATIC
end

"""
    mutable struct Point

A point mass, representing a node in the mass-spring system.

$(TYPEDFIELDS)
"""
mutable struct Point
    const idx::Int16
    const transform_idx::Int16 # idx of wing used for initial orientation
    const wing_idx::Int16
    const pos_cad::KVec3
    const pos_b::KVec3 # pos relative to wing COM in body frame
    const pos_w::KVec3 # pos in world frame
    const vel_w::KVec3 # vel in world frame
    const disturb::KVec3 # disturbing force
    const force::KVec3
    const type::DynamicsType
    mass::SimFloat
    bridle_damping::SimFloat
    fix_sphere::Bool
end

"""
    Point(idx, pos_cad, type; wing_idx=1, vel_w=zeros(KVec3), transform_idx=1, mass=0.0)

Constructs a `Point` object, which can be of four different [`DynamicsType`](@ref)s:
- `STATIC`: The point does not move. ``\\ddot{\\mathbf{r}} = \\mathbf{0}``
- `DYNAMIC`: The point moves according to Newton's second law. ``\\ddot{\\mathbf{r}} = \\mathbf{F}/m``
- `QUASI_STATIC`: The acceleration is constrained to be zero by solving a nonlinear problem. ``\\mathbf{F}/m = \\mathbf{0}``
- `WING`: The point has a static position in the rigid body wing frame. ``\\mathbf{r}_w = \\mathbf{r}_{wing} + \\mathbf{R}_{b\\rightarrow w} \\mathbf{r}_b``

where:
- ``\\mathbf{r}`` is the point position vector
- ``\\mathbf{F}`` is the net force acting on the point
- ``m`` is the point mass
- ``\\mathbf{r}_w`` is the position in world frame
- ``\\mathbf{r}_{wing}`` is the wing center position
- ``\\mathbf{R}_{b\\rightarrow w}`` is the rotation matrix from body to world frame
- ``\\mathbf{r}_b`` is the position in body frame

# Arguments
- `idx::Int16`: Unique identifier for the point.
- `pos_cad::KVec3`: Position of the point in the CAD frame.
- `type::DynamicsType`: Dynamics type of the point (`STATIC`, `DYNAMIC`, etc.).

# Keyword Arguments
- `wing_idx::Int16=1`: Index of the wing this point is attached to.
- `vel_w::KVec3=zeros(KVec3)`: Initial velocity of the point in world frame.
- `transform_idx::Int16=1`: Index of the transform used for initial positioning.
- `mass::Float64=0.0`: Mass of the point [kg].
- `bridle_damping::Float64=0.0`: Damping coefficient for bridle points.
- `fix_sphere::Bool=false`: If true, constrains the point to a sphere.

# Returns
- `Point`: A new `Point` object.
"""
function Point(idx, pos_cad, type;
    wing_idx=1, vel_w=zeros(KVec3), transform_idx=1,
    mass=0.0, bridle_damping=0.0, fix_sphere=false
)
    Point(idx, transform_idx, wing_idx, pos_cad, zeros(KVec3), zeros(KVec3),
        vel_w, zeros(KVec3), zeros(KVec3), type, mass, bridle_damping, fix_sphere)
end

"""
    mutable struct Group

A set of bridle lines that share the same twist angle and trailing edge angle.

$(TYPEDFIELDS)
"""
mutable struct Group
    const idx::Int16
    const point_idxs::Vector{Int16}
    const le_pos::KVec3 # point which the group rotates around under wing deformation
    const chord::KVec3 # chord vector in body frame which the group rotates around under wing deformation
    const y_airf::KVec3 # spanwise vector in local panel frame which the group rotates around under wing deformation
    const type::DynamicsType
    moment_frac::SimFloat
    damping::SimFloat
    twist::SimFloat
    twist_ω::SimFloat
    tether_force::SimFloat
    tether_moment::SimFloat
    aero_moment::SimFloat
end

"""
    Group(idx, point_idxs, le_pos, chord, y_airf, type, moment_frac; damping=50.0)

Constructs a `Group` object representing a collection of points on a kite body that share
a common twist deformation.

A `Group` models the local deformation of a kite wing section through twist dynamics.
All points within a group undergo the same twist rotation about the chord vector.

The governing equation is:
```math
\\begin{aligned}
\\tau = \\underbrace{\\sum_{i=1}^{4} r_{b,i} \\times (\\mathbf{F}_{b,i} \\cdot \\hat{\\mathbf{z}})}_{\\text{bridles}} + \\underbrace{r_a \\times (\\mathbf{F}_a \\cdot \\hat{\\mathbf{z}})}_{\\text{aero}}
\\end{aligned}
```

![System Overview](assets/group_slice.svg)

where:
- ``\\tau`` is the total torque about the twist axis
- ``r_{b,i}`` is the position vector of bridle point ``i`` relative to the twist center
- ``\\mathbf{F}_{b,i}`` is the force at bridle point ``i``
- ``\\hat{\\mathbf{z}}`` is the unit vector along the twist axis (chord direction)
- ``r_a`` is the position vector of the aerodynamic center relative to the twist center
- ``\\mathbf{F}_a`` is the aerodynamic force at the group's aerodynamic center

The group can have two [`DynamicsType`](@ref)s:
- `DYNAMIC`: the group rotates according to Newton's second law: ``I\\ddot{\\theta} = \\tau``
- `QUASI_STATIC`: the rotational acceleration is zero: ``\\tau = 0``

# Arguments
- `idx::Int16`: Unique identifier for the group.
- `point_idxs::Vector{Int16}`: Indices of points that move together with this group's twist.
- `le_pos::KVec3`: Leading edge position in body frame.
- `chord::KVec3`: Chord vector in body frame.
- `y_airf::KVec3`: Spanwise vector in local panel frame.
- `type::DynamicsType`: Dynamics type (`DYNAMIC` for time-varying twist, `QUASI_STATIC` for equilibrium).
- `moment_frac::SimFloat`: Chordwise position (0=leading edge, 1=trailing edge) about which the group rotates.

# Keyword Arguments
- `damping::SimFloat=50.0`: Damping coefficient for twist dynamics.

# Returns
- `Group`: A new `Group` object with twist dynamics capability.
"""
function Group(idx, point_idxs, le_pos, chord, y_airf, type, moment_frac; damping=50.0)
    Group(idx, point_idxs, le_pos, chord, y_airf, type, moment_frac, damping, 0.0, 0.0, 0.0, 0.0, 0.0)
end

"""
    mutable struct Segment

A segment representing a spring-damper connection from one point to another.

$(TYPEDFIELDS)
"""
mutable struct Segment
    const idx::Int16
    const point_idxs::Tuple{Int16, Int16}
    axial_stiffness::SimFloat
    axial_damping::SimFloat
    l0::SimFloat
    compression_frac::SimFloat
    diameter::SimFloat
    len::SimFloat # current len of the segment
    force::SimFloat # current force in the segment
end

"""
    Segment(idx, point_idxs, axial_stiffness, axial_damping, diameter; l0, compression_frac)

Inner constructor for a `Segment` object. See [`Segment`](@ref) for details.
"""
function Segment(idx, point_idxs, axial_stiffness, axial_damping, diameter;
    l0=zero(SimFloat), compression_frac=0.1
)
    Segment(idx, point_idxs, axial_stiffness, axial_damping, l0, compression_frac,
        diameter, zero(SimFloat), zero(SimFloat))
end

"""
    Segment(idx, set, point_idxs, type; l0, compression_frac, axial_stiffness, axial_damping)

Constructs a `Segment` object representing an elastic spring-damper connection between two points.

The segment follows Hooke's law with damping and aerodynamic drag:

**Spring-Damper Force:**
```math
\\mathbf{F}_{spring} = \\left[k(l - l_0) - c\\dot{l}\\right]\\hat{\\mathbf{u}}
```

**Aerodynamic Drag:**
```math
\\mathbf{F}_{drag} = \\frac{1}{2}\\rho C_d A |\\mathbf{v}_a| \\mathbf{v}_{a,\\perp}
```

**Total Force:**
```math
\\mathbf{F}_{total} = \\mathbf{F}_{spring} + \\mathbf{F}_{drag}
```

where:
- ``k = \\frac{E \\pi d^2/4}{l}`` is the axial stiffness
- ``l`` is current length, ``l_0`` is unstretched length
- ``c = \\frac{\\xi}{c_{spring}} k`` is damping coefficient
- ``\\hat{\\mathbf{u}} = \\frac{\\mathbf{r}_2 - \\mathbf{r}_1}{l}`` is unit vector along segment
- ``\\dot{l} = (\\mathbf{v}_1 - \\mathbf{v}_2) \\cdot \\hat{\\mathbf{u}}`` is extension rate
- ``\\mathbf{v}_{a,\\perp}`` is apparent wind velocity perpendicular to segment

# Arguments
- `idx::Int16`: Unique identifier for the segment.
- `set::Settings`: The settings object containing material properties.
- `point_idxs::Tuple{Int16, Int16}`: Tuple containing the indices of the two points.
- `type::SegmentType`: Type of the segment (`POWER_LINE`, `STEERING_LINE`, `BRIDLE`).

# Keyword Arguments
- `l0::SimFloat=zero(SimFloat)`: Unstretched length [m]. Calculated from point positions if zero.
- `compression_frac::SimFloat=0.0`: Stiffness reduction factor in compression.
- `axial_stiffness::Float64=NaN`: Axial stiffness [N]. If `NaN`, it's calculated from settings.
- `axial_damping::Float64=NaN`: Axial damping [Ns]. If `NaN`, it's calculated from settings.

# Returns
- `Segment`: A new `Segment` object.
"""
function Segment(idx, set, point_idxs, type;
    l0=zero(SimFloat), compression_frac=0.0, axial_stiffness=NaN, axial_damping=NaN
)
    (type == BRIDLE) && (diameter = 0.001* set.bridle_tether_diameter)
    (type == POWER_LINE) && (diameter = 0.001* set.power_tether_diameter)
    (type == STEERING_LINE) && (diameter = 0.001* set.steering_tether_diameter)

    if isnan(axial_stiffness) || isnan(axial_damping)
        axial_stiffness = set.e_tether * (diameter/2)^2 * π
        if type == BRIDLE
            stiffness_frac = 0.01
        else
            stiffness_frac = 1.0
        end
        axial_stiffness = stiffness_frac * axial_stiffness

        axial_damping = (set.axial_damping / set.axial_stiffness) * axial_stiffness
    end

    Segment(idx, point_idxs, axial_stiffness, axial_damping, l0, compression_frac,
        diameter, zero(SimFloat), zero(SimFloat))
end

"""
    mutable struct Pulley

A pulley described by two segments with the common point of the segments being the pulley.

$(TYPEDFIELDS)
"""
mutable struct Pulley
    const idx::Int16
    const segment_idxs::Tuple{Int16, Int16}
    const type::DynamicsType
    sum_len::SimFloat
    len::SimFloat
    vel::SimFloat
end

"""
    Pulley(idx, segment_idxs, type)

Constructs a `Pulley` object that enforces length redistribution between two segments.

The pulley constraint maintains constant total length while allowing force transmission:

**Constraint Equations:**
```math
l_1 + l_2 = l_{total} = \\text{constant}
```

**Force Balance:**
```math
F_{pulley} = F_1 - F_2
```

**Dynamics:**
```math
m\\ddot{l}_1 = F_{pulley} = F_1 - F_2
```

where:
- ``l_1, l_2`` are the lengths of connected segments
- ``F_1, F_2`` are the spring forces in the segments
- ``m = \\rho_{tether} \\pi (d/2)^2 l_{total}`` is the total mass of both segments
- ``\\dot{l}_1 + \\dot{l}_2 = 0`` (velocity constraint)

The pulley can have two [`DynamicsType`](@ref)s:
- `DYNAMIC`: the length redistribution follows Newton's second law: ``m\\ddot{l}_1 = F_1 - F_2``
- `QUASI_STATIC`: the forces are balanced instantaneously: ``F_1 = F_2``

# Arguments
- `idx::Int16`: Unique identifier for the pulley.
- `segment_idxs::Tuple{Int16, Int16}`: Tuple containing the indices of the two segments.
- `type::DynamicsType`: Dynamics type of the pulley (`DYNAMIC` or `QUASI_STATIC`).

# Returns
- `Pulley`: A new `Pulley` object.
"""
function Pulley(idx, segment_idxs, type)
    return Pulley(idx, segment_idxs, type, 0.0, 0.0, 0.0)
end

"""
    mutable struct Tether

A collection of segments that are controlled together by a winch.

$(TYPEDFIELDS)
"""
mutable struct Tether
    const idx::Int16
    const segment_idxs::Vector{Int16}
    const winch_idx::Int16
    stretched_len::SimFloat
end

"""
    Tether(idx, segment_idxs, winch_idx)

Constructs a `Tether` object representing a flexible line composed of multiple segments.

A tether enforces a shared unstretched length constraint across all its constituent segments:

**Length Constraint:**
```math
\\sum_{i \\in \\text{segments}} l_{0,i} = L
```

**Winch Control:**
The unstretched tether length `L` is controlled by a winch.

# Arguments
- `idx::Int16`: Unique identifier for the tether.
- `segment_idxs::Vector{Int16}`: Indices of segments that form this tether.
- `winch_idx::Int16`: Index of the winch controlling this tether.

# Returns
- `Tether`: A new `Tether` object.
"""
function Tether(idx, segment_idxs, winch_idx)
    return Tether(idx, segment_idxs, winch_idx, 0.0)
end

"""
    mutable struct Winch

A set of tethers (or a single tether) connected to a winch mechanism.

$(TYPEDFIELDS)
"""
mutable struct Winch
    const idx::Int16
    const tether_idxs::Vector{Int16}
    tether_len::Union{SimFloat, Nothing}
    tether_vel::SimFloat
    tether_acc::SimFloat
    set_value::SimFloat
    brake::Bool
    const force::KVec3
    gear_ratio::SimFloat
    drum_radius::SimFloat
    f_coulomb::SimFloat
    c_vf::SimFloat
    inertia_total::SimFloat
    friction::SimFloat
end

"""
    Winch(idx, set, tether_idxs; tether_len=0.0, tether_vel=0.0, brake=false)

Constructs a `Winch` object that controls tether length through torque or speed regulation.

The winch acceleration function `α` depends on the winch model type:
- **Torque-controlled**: Direct torque input with motor dynamics.
- **Speed-controlled**: Velocity regulation with internal control loops.

For detailed mathematical models of winch dynamics, motor characteristics, and control algorithms,
see the [WinchModels.jl documentation](https://github.com/aenarete/WinchModels.jl/blob/main/docs/winch.md).

# Arguments
- `idx::Int16`: Unique identifier for the winch.
- `set::Settings`: The main settings object, used to retrieve winch parameters.
- `tether_idxs::Vector{Int16}`: Vector of indices of the tethers connected to this winch.

# Keyword Arguments
- `tether_len::SimFloat=0.0`: Initial tether length [m].
- `tether_vel::SimFloat=0.0`: Initial tether velocity (reel-out rate) [m/s].
- `brake::Bool=false`: If true, the winch brake is engaged.

# Returns
- `Winch`: A new `Winch` object.
"""
function Winch(idx, set::Settings, tether_idxs; tether_len=0.0, tether_vel=0.0, brake=false)
    return Winch(idx, tether_idxs, tether_len, tether_vel, 0.0, 0.0, brake, zeros(KVec3),
                 set.gear_ratio, set.drum_radius, set.f_coulomb, set.c_vf,
                 set.inertia_total, zero(SimFloat))
end

"""
    Winch(idx, tether_idxs, gear_ratio, drum_radius, f_coulomb, c_vf, inertia_total; tether_len=0.0, tether_vel=0.0, brake=false)

Constructs a `Winch` object by directly providing its physical parameters.

This constructor is an alternative to creating a winch from a `Settings` object,
allowing for more modular or programmatic creation of winch components.

# Arguments
- `idx::Int16`: Unique identifier for the winch.
- `tether_idxs::Vector{Int16}`: Vector of indices of the tethers connected to this winch.
- `gear_ratio::SimFloat`: The gear ratio of the winch.
- `drum_radius::SimFloat`: The radius of the winch drum [m].
- `f_coulomb::SimFloat`: Coulomb friction force [N].
- `c_vf::SimFloat`: Viscous friction coefficient [Ns/m].
- `inertia_total::SimFloat`: Total inertia of the motor, gearbox, and drum [kgm²].

# Keyword Arguments
- `tether_len::SimFloat=0.0`: Initial tether length [m].
- `tether_vel::SimFloat=0.0`: Initial tether velocity (reel-out rate) [m/s].
- `brake::Bool=false`: If true, the winch brake is engaged.

# Returns
- `Winch`: A new `Winch` object.
"""
function Winch(idx, tether_idxs, gear_ratio, drum_radius, f_coulomb, c_vf, inertia_total;
               tether_len=0.0, tether_vel=0.0, brake=false)
    return Winch(idx, tether_idxs, tether_len, tether_vel, 0.0, 0.0, brake, zeros(KVec3),
                 gear_ratio, drum_radius, f_coulomb, c_vf, inertia_total, zero(SimFloat))
end

"""
    abstract type AbstractWing

Abstract base type for all wing implementations.

Concrete subtypes must implement rigid body dynamics and provide a reference frame
for attached points and groups.
"""
abstract type AbstractWing end

"""
    mutable struct BaseWing <: AbstractWing

A rigid wing body that can have multiple groups of points attached to it.

The wing provides a rigid body reference frame for attached points and groups.
Points with `type == WING` move rigidly with the wing body according to the
wing's orientation matrix `R_b_w` and position `pos_w`.

# Special Properties
The wing's orientation can be accessed as a rotation matrix or a quaternion:
```julia
R_matrix = wing.R_b_w
wing.R_b_w = R_matrix

quat = wing.Q_b_w
wing.Q_b_w = quat
```

$(TYPEDFIELDS)
"""
mutable struct BaseWing <: AbstractWing
    const idx::Int16

    # Structural information
    const group_idxs::Vector{Int16}
    const transform_idx::Int16
    const R_b_c::Matrix{SimFloat}
    const pos_cad::KVec3

    # Differential variables in world frame, updated during simulation
    const Q_b_w::Vector{SimFloat}
    const ω_b::KVec3
    const pos_w::KVec3
    const vel_w::KVec3
    const acc_w::KVec3

    # Derived variables and parameters, updated during simulation
    const wind_disturb::KVec3
    drag_frac::SimFloat
    const va_b::KVec3 # apparent wind in body frame
    const v_wind::KVec3 # wind velocity in world frame at the wing
    const aero_force_b::KVec3 # aerodynamic force in body frame
    const aero_moment_b::KVec3 # aerodynamic moment in body frame
    const tether_moment::KVec3 # tether moment in world frame
    const tether_force::KVec3 # tether force in world frame
    elevation::SimFloat
    elevation_vel::SimFloat
    elevation_acc::SimFloat
    azimuth::SimFloat
    azimuth_vel::SimFloat
    azimuth_acc::SimFloat
    heading::SimFloat
    const turn_rate::KVec3
    const turn_acc::KVec3
    course::SimFloat
    aoa::SimFloat
    fix_sphere::Bool
    y_damping::SimFloat
    z_disturb::SimFloat
end

# Helper functions for quaternion/rotation matrix conversion
function quaternion_to_rotation_matrix(q::Vector{SimFloat})
    w, x, y, z = q[1], q[2], q[3], q[4]
    R = Matrix{SimFloat}(undef, 3, 3)
    R[1,1] = 1 - 2*(y^2 + z^2)
    R[1,2] = 2*(x*y - w*z)
    R[1,3] = 2*(x*z + w*y)
    R[2,1] = 2*(x*y + w*z)
    R[2,2] = 1 - 2*(x^2 + z^2)
    R[2,3] = 2*(y*z - w*x)
    R[3,1] = 2*(x*z - w*y)
    R[3,2] = 2*(y*z + w*x)
    R[3,3] = 1 - 2*(x^2 + y^2)
    return R
end

function rotation_matrix_to_quaternion(R::Matrix{SimFloat})
    trace_R = R[1,1] + R[2,2] + R[3,3]
    if trace_R > 0
        s = sqrt(trace_R + 1.0) * 2
        w = 0.25 * s
        x = (R[3,2] - R[2,3]) / s
        y = (R[1,3] - R[3,1]) / s
        z = (R[2,1] - R[1,2]) / s
    elseif (R[1,1] > R[2,2]) && (R[1,1] > R[3,3])
        s = sqrt(1.0 + R[1,1] - R[2,2] - R[3,3]) * 2
        w = (R[3,2] - R[2,3]) / s
        x = 0.25 * s
        y = (R[1,2] + R[2,1]) / s
        z = (R[1,3] + R[3,1]) / s
    elseif R[2,2] > R[3,3]
        s = sqrt(1.0 + R[2,2] - R[1,1] - R[3,3]) * 2
        w = (R[1,3] - R[3,1]) / s
        x = (R[1,2] + R[2,1]) / s
        y = 0.25 * s
        z = (R[2,3] + R[3,2]) / s
    else
        s = sqrt(1.0 + R[3,3] - R[1,1] - R[2,2]) * 2
        w = (R[2,1] - R[1,2]) / s
        x = (R[1,3] + R[3,1]) / s
        y = (R[2,3] + R[3,2]) / s
        z = 0.25 * s
    end
    return [w, x, y, z]
end

function Base.getproperty(wing::BaseWing, sym::Symbol)
    if sym == :R_b_w
        return quaternion_to_rotation_matrix(wing.Q_b_w)
    else
        return getfield(wing, sym)
    end
end

function Base.setproperty!(wing::BaseWing, sym::Symbol, value)
    if sym == :R_b_w
        wing.Q_b_w .= rotation_matrix_to_quaternion(value)
    else
        setfield!(wing, sym, value)
    end
end

"""
    BaseWing(idx::Int16, group_idxs::Vector{Int16}, R_b_c::Matrix{SimFloat},
             pos_cad::KVec3; transform_idx=1, y_damping=150.0)

Constructs a `BaseWing` object representing a rigid body reference frame.

# Arguments
- `idx::Int16`: Unique identifier for the wing.
- `group_idxs::Vector{Int16}`: Indices of groups attached to this wing.
- `R_b_c::Matrix{SimFloat}`: Rotation matrix from body frame to CAD frame.
- `pos_cad::KVec3`: Position of wing center of mass in CAD frame.

# Keyword Arguments
- `transform_idx::Int16=1`: Transform used for initial positioning and orientation.
- `y_damping::SimFloat=150.0`: Damping coefficient for lateral motion.

# Returns
- `BaseWing`: A new base wing object.
"""
function BaseWing(idx, group_idxs, R_b_c, pos_cad; transform_idx=1, y_damping=150.0)
    return BaseWing(idx,
        # Structural information
        group_idxs, transform_idx, R_b_c, pos_cad,
        # Differential variables in world frame, updated during simulation
        zeros(4), zeros(KVec3),
        zeros(KVec3), zeros(KVec3), zeros(KVec3),
        # Derived variables and parameters, updated during simulation
        zeros(KVec3), one(SimFloat),
        zeros(KVec3), zeros(KVec3), zeros(KVec3), zeros(KVec3),
        zeros(KVec3), zeros(KVec3),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        zeros(KVec3), zeros(KVec3), 0.0, 0.0, false,
        y_damping, 0.0)
end

"""
    mutable struct Transform

Describes the spatial transformation (position and orientation) of system components
relative to a base reference point.

$(TYPEDFIELDS)
"""
mutable struct Transform
    const idx::Int16
    const wing_idx::Union{Int16, Nothing}
    const rot_point_idx::Union{Int16, Nothing}
    const base_point_idx::Union{Int16, Nothing}
    const base_transform_idx::Union{Int16, Nothing}
    elevation::SimFloat # The elevation of the rotating point or kite as seen from the base point
    azimuth::SimFloat # The azimuth of the rotating point or kite as seen from the base point
    heading::SimFloat
    base_pos::Union{KVec3, Nothing}
end

"""
    Transform(idx, elevation, azimuth, heading; base_point_idx, base_pos, base_transform_idx, wing_idx, rot_point_idx)

Constructs a `Transform` object that orients system components using spherical coordinates.

All points and wings with a matching `transform_idx` are transformed together as a rigid body:
1. **Translation**: Translate such that `base_point_idx` is at the specified `base_pos`.
2. **Rotation 1**: Rotate so the target (`wing_idx` or `rot_point_idx`) is at (`elevation`, `azimuth`) relative to the base.
3. **Rotation 2**: Rotate all components by `heading` around the base-target vector.

```math
\\mathbf{r}_{transformed} = \\mathbf{r}_{base} + \\mathbf{R}_{heading} \\circ \\mathbf{R}_{elevation,azimuth}(\\mathbf{r} - \\mathbf{r}_{base})
```

# Arguments
- `idx::Int16`: Unique identifier for the transform.
- `elevation::SimFloat`: Target elevation angle from base [rad].
- `azimuth::SimFloat`: Target azimuth angle from base [rad].
- `heading::SimFloat`: Rotation around base-target vector [rad].

# Keyword Arguments
**Base Reference (choose one method):**
- `base_pos` & `base_point_idx`: Use a fixed position and a reference point.
- `base_transform_idx`: Chain to another transform's position.

**Target Object (choose one):**
- `wing_idx`: The wing to position at (`elevation`, `azimuth`).
- `rot_point_idx`: The point to position at (`elevation`, `azimuth`).

# Returns
- `Transform`: A transform affecting all components with a matching `transform_idx`.
"""
function Transform(idx, elevation, azimuth, heading;
        base_point_idx=nothing, base_pos=nothing, base_transform_idx=nothing,
        wing_idx=nothing, rot_point_idx=nothing)
    (isnothing(wing_idx) == isnothing(rot_point_idx)) && error("Either provide a wing_idx or a rot_point_idx, not both or none.")
    (isnothing(base_pos) == isnothing(base_transform_idx)) && error("Either provide the base_pos or the base_transform_idx, not both or none.")
    (isnothing(base_pos) !== isnothing(base_point_idx)) && error("When providing a base_pos, also provide a base_point_idx.")
    Transform(idx, wing_idx, rot_point_idx, base_point_idx, base_transform_idx, elevation, azimuth, heading, base_pos)
end

"""
    Transform(idx, set; wing_idx, rot_point_idx, base_point_idx, base_pos, base_transform_idx)

Constructor helper to create a `Transform` from a `Settings` object.

This constructor retrieves the `elevation`, `azimuth`, and `heading` values from the
`Settings` object at index `idx` and converts them from degrees to radians before
calling the main [`Transform`](@ref) constructor.

See the main `Transform` constructor for detailed documentation of the keyword arguments
and usage examples.
"""
function Transform(idx, set; kwargs...)
    Transform(idx, deg2rad(set.elevations[idx]), deg2rad(set.azimuths[idx]),
              deg2rad(set.headings[idx]); kwargs...)
end

"""
    struct SystemStructure

A discrete mass-spring-damper representation of a kite system.

This struct holds all components of the physical model, including points, segments,
winches, and wings, forming a complete description of the kite system's structure.

# Components
- [`Point`](@ref): Point masses.
- [`Group`](@ref): Collections of points for wing deformation.
- [`Segment`](@ref): Spring-damper elements.
- [`Pulley`](@ref): Elements that redistribute line lengths.
- [`Tether`](@ref): Groups of segments controlled by a winch.
- [`Winch`](@ref): Ground-based winches.
- [`AbstractWing`](@ref): Rigid wing bodies.
- [`Transform`](@ref): Spatial transformations for initial positioning.
"""
mutable struct SystemStructure
    const name::String
    const set::Settings
    const points::Vector{Point}
    const groups::Vector{Group}
    const segments::Vector{Segment}
    const pulleys::Vector{Pulley}
    const tethers::Vector{Tether}
    const winches::Vector{Winch}
    const wings::Vector{AbstractWing}
    const transforms::Vector{Transform}
    const y::Array{Float64, 2}
    const x::Array{Float64, 2}
    const jac::Array{Float64, 3}
    const wind_vec_gnd::KVec3
    wind_elevation::SimFloat
    stabilize::Bool
    fix_wing::Bool
end

"""
    SystemStructure(name, set; points, groups, segments, pulleys, tethers, winches, wings, transforms)

Constructs a `SystemStructure` object representing a complete kite system.

## Physical Models
- **"ram"**: A model with 4 deformable wing groups and a complex pulley bridle system.
- **"simple_ram"**: A model with 4 deformable wing groups and direct bridle connections.

# Arguments
- `name::String`: Model identifier ("ram", "simple_ram", or a custom name).
- `set::Settings`: Configuration parameters from `KiteUtils.jl`.

# Keyword Arguments
- `points`, `groups`, `segments`, etc.: Vectors of the system components.

# Returns
- `SystemStructure`: A complete system ready for building a symbolic model.
"""
function SystemStructure(name, set;
        points=Point[],
        groups=Group[],
        segments=Segment[],
        pulleys=Pulley[],
        tethers=Tether[],
        winches=Winch[],
        wings=AbstractWing[],
        transforms=Transform[],
    )
    for (i, point) in enumerate(points)
        @assert point.idx == i
        @assert point.transform_idx <= length(transforms)
    end
    for (i, group) in enumerate(groups)
        @assert group.idx == i
    end
    for (i, segment) in enumerate(segments)
        @assert segment.idx == i
        (segment.l0 ≈ 0) && (segment.l0 = norm(points[segment.point_idxs[1]].pos_cad - points[segment.point_idxs[2]].pos_cad))
    end
    for (i, pulley) in enumerate(pulleys)
        @assert pulley.idx == i
    end
    for (i, tether) in enumerate(tethers)
        @assert tether.idx == i
    end
    for (i, winch) in enumerate(winches)
        @assert winch.idx == i
        if iszero(winch.tether_len)
            for segment_idx in tethers[winch.tether_idxs[1]].segment_idxs
                winch.tether_len += segments[segment_idx].l0
            end
        end
    end
    for (i, wing) in enumerate(wings)
        @assert wing.idx == i
    end
    for (i, transform) in enumerate(transforms)
        @assert transform.idx == i
        set.elevations[i] = rad2deg(transform.elevation)
        set.azimuths[i]   = rad2deg(transform.azimuth)
        set.headings[i]   = rad2deg(transform.heading)
    end
    if length(wings) > 0
        ny = 3+length(wings[1].group_idxs)+3
        nx = 3+3+length(wings[1].group_idxs)
    else
        ny = 0
        nx = 0
    end
    y = zeros(length(wings), ny)
    x = zeros(length(wings), nx)
    jac = zeros(length(wings), nx, ny)
    set.physical_model = name
    sys_struct = SystemStructure(name, set, points, groups, segments, pulleys, tethers,
        winches, wings, transforms, y, x, jac, zeros(KVec3), 0.0, false, false)
    return sys_struct
end
