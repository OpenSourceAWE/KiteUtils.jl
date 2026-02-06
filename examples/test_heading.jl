# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils, LinearAlgebra, ControlPlots

"""
    calc_elevation_azimuth(turn_angle; x=100.0, r=20.0)

Calculate the elevation and azimuth angles in radian for a kite flying on a vertical
circle of radius `r`, centered at `(x, 0, 0)` in the ENU reference frame.

The turn angle is measured from the top of the circle (12 o'clock position), going
clockwise when viewed from the ground station (looking downwind).

# Arguments
- `turn_angle`: the position of the kite on the circle in radian (0 to 2π).
                0 means the top of the circle (highest point), π/2 means the kite
                is to the right (south), π means the bottom, 3π/2 means the kite
                is to the left (north).
- `x`: distance of the circle center from the ground station along the east axis [m]. Default: 100.0.
- `r`: radius of the circle [m]. Default: 20.0.

# Returns
A tuple `(elevation, azimuth)` in radian.
- `elevation`: the elevation angle of the kite as seen from the ground station.
- `azimuth`: the azimuth angle (east-based) of the kite as seen from the ground station.
"""
function calc_elevation_azimuth(turn_angle; x=100.0, r=20.0)
    # The circle is in the plane perpendicular to the downwind direction (east axis),
    # centered at (x, 0, 0). The kite sweeps through north/south and up/down.
    # turn_angle = 0 → top, π/2 → right (south), π → bottom, 3π/2 → left (north)
    kite_east  = x
    kite_north = -r * sin(turn_angle)   # negative because clockwise seen from ground station
    kite_up    =  r * cos(turn_angle)
    pos = [kite_east, kite_north, kite_up]
    elevation = calc_elevation(pos)
    azimuth   = azimuth_east(pos)
    return (elevation, azimuth)
end

"""
    calc_orientation(turn_angle)

Calculate the orientation of the kite as (roll, pitch, yaw) in radian for a given turn angle
in radian. The kite is assumed to be oriented tangentially to the circle (pointing in the
direction of motion).

The circle is in the plane perpendicular to the east axis, centered at `(x, 0, 0)`.
The tangent vector is the derivative of the position with respect to the turn angle.

# Arguments
- `turn_angle`: the position of the kite on the circle in radian (0 to 2π).

# Returns
A tuple `(roll, pitch, yaw)` in radian.
"""
function calc_orientation(turn_angle)
    # Tangent vector: derivative of position (x, -r*sin(θ), r*cos(θ)) with respect to θ
    # d/dθ: (0, -r*cos(θ), -r*sin(θ))  — the r factor cancels after normalization
    tangent = normalize([0.0, -cos(turn_angle), -sin(turn_angle)])

    # In NED convention (used by quat2euler / euler2rot in this codebase):
    #   x = North, y = East, z = Down
    # Convert the tangent from ENU (east, north, up) to NED (north, east, down):
    t_ned = [tangent[2], tangent[1], -tangent[3]]

    # Yaw: heading in the NED horizontal plane (angle from North toward East)
    yaw   = atan(t_ned[2], t_ned[1])
    # Pitch: nose-up angle (positive = nose up)
    pitch = -asin(t_ned[3])
    # Roll: zero (the kite is not banking in this simple model)
    roll  = 0.0

    return (roll, pitch, yaw)
end

"""
    calc_heading(turn_angle; x=100.0, r=20.0)

Calculate the heading of the kite in radian for a given turn angle in radian.
The heading is the direction the nose of the kite is pointing to, where 0 means
the kite is flying upwards (in the SE reference frame).

Uses `calc_orientation` to get the kite orientation and `calc_elevation_azimuth` to get
the elevation and azimuth, then calls `calc_heading` from KiteUtils.jl.

# Arguments
- `turn_angle`: the position of the kite on the circle in radian (0 to 2π).
- `x`: distance of the circle center from the ground station along the east axis [m]. Default: 100.0.
- `r`: radius of the circle [m]. Default: 20.0.

# Returns
The heading angle in radian.
"""
function calc_kite_heading(turn_angle; x=100.0, r=20.0)
    orientation = collect(calc_orientation(turn_angle))
    el, az = calc_elevation_azimuth(turn_angle; x=x, r=r)
    calc_heading(orientation, el, az)
end

# Test the function calc_elevation_azimuth
println("turn_angle => (elevation, azimuth)")
for turn_angle in 0:30:360
    el, az = calc_elevation_azimuth(deg2rad(turn_angle))
    println("  $(turn_angle)deg => elevation: $(round(rad2deg(el), digits=2))deg, azimuth: $(round(rad2deg(az), digits=2))deg")
end

# Test the function calc_orientation
println("\nturn_angle => (roll, pitch, yaw)")
for turn_angle in 0:30:360
    roll, pitch, yaw = calc_orientation(deg2rad(turn_angle))
    println("  $(turn_angle)deg => roll: $(round(rad2deg(roll), digits=2))deg, pitch: $(round(rad2deg(pitch), digits=2))deg, yaw: $(round(rad2deg(yaw), digits=2))deg")
end

# Test the function calc_kite_heading
println("\nturn_angle => heading")
for turn_angle in 0:30:360
    heading = calc_kite_heading(deg2rad(turn_angle))
    println("  $(turn_angle)deg => heading: $(round(rad2deg(heading), digits=2))deg")
end

# Plot heading as function of turn angle
turn_angles = 0:1:360
headings = [rad2deg(calc_kite_heading(deg2rad(ta))) for ta in turn_angles]
plot(collect(turn_angles), headings; xlabel="turn angle [°]", ylabel="heading [°]", fig="heading")
