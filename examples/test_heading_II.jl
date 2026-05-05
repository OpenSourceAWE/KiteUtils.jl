# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# TODO: add the option to fly at any elevation angle of the center point

using Pkg
if ! ("ControlPlots" ∈ keys(Pkg.project().dependencies))
    Pkg.activate("examples")
end

using ControlPlots
using KiteUtils
using LinearAlgebra: cross, dot, norm, normalize
using Rotations
using StaticArrays

"""
    calc_circle_basis(x, z)

Compute the orthonormal basis vectors `(e1, e2)` for the circle plane perpendicular
to the center line. The center line goes from the origin to `(x, 0, z)` in ENU.

- `e1`: the "up" direction in the circle plane (component of world-up perpendicular to center line).
- `e2`: the "right" direction when viewed from the ground station (`cross(d, e1)`).
"""
function calc_circle_basis(x, z)
    d = normalize([x, 0.0, z])           # center line direction (ENU)
    up = [0.0, 0.0, 1.0]                 # world up
    e1_raw = up - dot(up, d) * d         # up component ⊥ center line
    e1 = normalize(e1_raw)
    e2 = cross(d, e1)                    # right when viewed from ground station
    return (e1, e2)
end

"""
    calc_elevation_azimuth(turn_angle; x=100.0, z=0.0, r=20.0)

Calculate the elevation and azimuth angles in radian for a kite flying on a
circle of radius `r`, centered at `(x, 0, z)` in the ENU reference frame.
The circle plane is perpendicular to the center line (the line from the origin to
the center).

The turn angle is measured from the top of the circle (12 o'clock position), going
clockwise when viewed from the ground station (looking along the tether).

# Arguments
- `turn_angle`: the position of the kite on the circle in radian (0 to 2π).
                0 means the top of the circle (highest point), π/2 means the kite
                is to the right (south), π means the bottom, 3π/2 means the kite
                is to the left (north).
- `x`: distance of the circle center from the ground station along the east axis [m]. Default: 100.0.
- `z`: height of the circle center above the ground [m]. Default: 0.0.
- `r`: radius of the circle [m]. Default: 20.0.

# Returns
A tuple `(elevation, azimuth)` in radian.
- `elevation`: the elevation angle of the kite as seen from the ground station.
- `azimuth`: the azimuth angle (east-based) of the kite as seen from the ground station.
"""
function calc_elevation_azimuth(turn_angle; x = 100.0, z = 0.0, r = 20.0)
    center = [x, 0.0, z]
    e1, e2 = calc_circle_basis(x, z)
    # Kite position on circle in the plane ⊥ tether
    # turn_angle = 0 → top (e1), π/2 → right (e2), π → bottom, 3π/2 → left
    pos = center + r * cos(turn_angle) * e1 + r * sin(turn_angle) * e2
    elevation = calc_elevation(pos)
    azimuth = azimuth_east(pos)
    return (elevation, azimuth)
end

"""
    calc_orientation(turn_angle; x=100.0, z=0.0, r=20.0)

Calculate the orientation of the kite as (roll, pitch, yaw) in radian for a given turn angle
in radian. The kite is assumed to be oriented tangentially to the circle (pointing in the
direction of motion).

The circle plane is perpendicular to the center line (from origin to `(x, 0, z)`).

The kite reference frame (KS) is defined as:
- x: from trailing edge to leading edge (flight direction)
- y: to the right looking in flight direction
- z: down (along the tether toward the ground station)

The orientation is expressed with respect to the NED reference frame using
`calc_orient_rot` and `quat2euler` from KiteUtils.jl.

# Arguments
- `turn_angle`: the position of the kite on the circle in radian (0 to 2π).
- `x`: distance of the circle center from the ground station along the east axis [m]. Default: 100.0.
- `z`: height of the circle center above the ground [m]. Default: 0.0.
- `r`: radius of the circle [m]. Default: 20.0.

# Returns
A tuple `(roll, pitch, yaw)` in radian.
"""
function calc_orientation(turn_angle; x = 100.0, z = 0.0, r = 20.0)
    center = [x, 0.0, z]
    e1, e2 = calc_circle_basis(x, z)

    # Kite position on the circle (ENU)
    pos = center + r * cos(turn_angle) * e1 + r * sin(turn_angle) * e2

    # z_kite (ENU): points down along the tether, from kite toward ground station
    z_kite = -normalize(pos)

    # Tangent vector = flight direction (ENU)
    tangent = normalize(-sin(turn_angle) * e1 + cos(turn_angle) * e2)

    # x_kite (ENU): leading edge direction, must be ⊥ z_kite
    # Orthogonalize tangent against z_kite
    x_kite = normalize(tangent - dot(tangent, z_kite) * z_kite)

    # y_kite (ENU): to the right looking in flight direction
    y_kite = cross(z_kite, x_kite)

    # Compute rotation matrix and extract Euler angles (roll, pitch, yaw) w.r.t. NED
    rotation = calc_orient_rot(x_kite, y_kite, z_kite)
    q = QuatRotation(rotation)
    roll, pitch, yaw = quat2euler(q)

    return (roll, pitch, yaw)
end

"""
    calc_kite_heading(turn_angle; x=100.0, z=0.0, r=20.0)

Calculate the heading of the kite in radian for a given turn angle in radian.
The heading is the direction the nose of the kite is pointing to, where 0 means
the kite is flying upwards (in the SE reference frame).

Uses `calc_orientation` to get the kite orientation and `calc_elevation_azimuth` to get
the elevation and azimuth, then calls `calc_heading` from KiteUtils.jl.

# Arguments
- `turn_angle`: the position of the kite on the circle in radian (0 to 2π).
- `x`: distance of the circle center from the ground station along the east axis [m]. Default: 100.0.
- `z`: height of the circle center above the ground [m]. Default: 0.0.
- `r`: radius of the circle [m]. Default: 20.0.

# Returns
The heading angle in radian.
"""
function calc_kite_heading(turn_angle; x = 100.0, z = 0.0, r = 20.0)
    orientation = collect(calc_orientation(turn_angle; x = x, z = z, r = r))
    el, az = calc_elevation_azimuth(turn_angle; x = x, z = z, r = r)
    calc_heading(orientation, el, az; respos = false)
end

"""
    calc_clock_angle(turn_angle; x=100.0, z=0.0, r=20.0)

Compute the clock angle of the kite: the rotation of the kite's x-axis (flight direction)
around the tether axis (z_kite), measured from the world-up direction projected onto
the plane perpendicular to the tether. Returns the angle in radian.
"""
function calc_clock_angle(turn_angle; x = 100.0, z = 0.0, r = 20.0)
    orientation = collect(calc_orientation(turn_angle; x = x, z = z, r = r))
    el, az = calc_elevation_azimuth(turn_angle; x = x, z = z, r = r)
    KiteUtils.calc_clock_angle(orientation, el, az; respos = false)
end

# Compute data for multiple θ values
const THETA = [30, 45, 60, 75]
turn_angles = 0:1:360
tether_length = 50.0
headings_all = Vector{Vector{Float64}}()
clock_angle_all = Vector{Vector{Float64}}()

for θ in THETA
    r = tether_length * sin(deg2rad(θ))  # r is the radius of the circle
    x = r / tan(deg2rad(θ))
    push!(headings_all, [rad2deg(calc_kite_heading(deg2rad(ta); x = x, z = 0.1, r = r)) for ta in turn_angles])
    push!(clock_angle_all, [rad2deg(calc_clock_angle(deg2rad(ta); x = x, z = 0.1, r = r)) for ta in turn_angles])
end

# Avoid accumulating curves and duplicate legend entries when re-running include().
plt.figure("heading and clock angle", clear = true)

plotx(
    collect(turn_angles),
    headings_all,
    clock_angle_all;
    xlabel = "turn angle [deg]",
    ylabels = ["heading [deg]", "clock angle [deg]"],
    labels = [
        ["Ψ (θ=$(θ)°)" for θ in THETA],
        ["clock angle (θ=$(θ)°)" for θ in THETA],
    ],
    fig = "heading and clock angle",
    disp = true,
)
