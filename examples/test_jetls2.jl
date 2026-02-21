# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using LinearAlgebra: cross, dot, normalize
using KiteUtils
using Rotations

function calc_circle_basis(x, z)
    d = normalize([x, 0.0, z])           # center line direction (ENU)
    up = [0.0, 0.0, 1.0]                 # world up
    e1_raw = up - dot(up, d) * d         # up component ⊥ center line
    e1 = normalize(e1_raw)
    e2 = cross(d, e1)                    # right when viewed from ground station
    return (e1, e2)
end

function calc_theta(x, r)
    # Calculate the angle θ between the center line and the line from the ground station to the kite
    # when the kite is at the top of the circle (turn_angle = 0).
    # This is used to verify that the elevation angle at turn_angle=0 matches θ.
    return atan(r, x)
end

function calc_r(x, theta)
    # Calculate the circle radius r from the distance x and the angle θ.
    # Inverse of calc_theta: given θ = atan(r, x), we get r = x * tan(θ).
    return x * tan(theta)
end

function calc_elevation_azimuth(turn_angle; x=100.0, z=0.0, r=20.0)
    center = [x, 0.0, z]
    e1, e2 = calc_circle_basis(x, z)
    # Kite position on circle in the plane ⊥ tether
    # turn_angle = 0 → top (e1), π/2 → right (e2), π → bottom, 3π/2 → left
    pos = center + r * cos(turn_angle) * e1 + r * sin(turn_angle) * e2
    elevation = calc_elevation(pos)
    azimuth   = azimuth_east(pos)
    return (elevation, azimuth)
end

function calc_orientation(turn_angle; x=100.0, z=0.0, r=20.0)
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

function calc_orient_quat(turn_angle; x=100.0, z=0.0, r=20.0)
    center = [x, 0.0, z]
    e1, e2 = calc_circle_basis(x, z)
    pos = center + r * cos(turn_angle) * e1 + r * sin(turn_angle) * e2
    z_kite = -normalize(pos)
    tangent = normalize(-sin(turn_angle) * e1 + cos(turn_angle) * e2)
    x_kite = normalize(tangent - dot(tangent, z_kite) * z_kite)
    y_kite = cross(z_kite, x_kite)
    rotation = calc_orient_rot(x_kite, y_kite, z_kite)
    return QuatRotation(rotation)
end

function calc_kite_heading(turn_angle; x=100.0, z=0.0, r=20.0)
    orientation = collect(calc_orientation(turn_angle; x=x, z=z, r=r))
    el, az = calc_elevation_azimuth(turn_angle; x=x, z=z, r=r)
    calc_heading(orientation, el, az; respos=false)
end

# Helper: kite position on circle
function calc_kite_pos(turn_angle; x=100.0, z=0.0, r=20.0)
    center = [x, 0.0, z]
    e1, e2 = calc_circle_basis(x, z)
    return center + r * cos(turn_angle) * e1 + r * sin(turn_angle) * e2
end

const THETA = [30, 45, 60, 75]
turn_angles = 0:1:360
tether_length = 50.0  
ys_all = Vector{Vector{Float64}}()

for θ in THETA
    r = tether_length * sin(deg2rad(θ))  # r is the radius of the circle
    x = r / tan(deg2rad(θ))
    push!(ys_all, [calc_kite_pos(deg2rad(ta); x=x, z=0.0, r=r)[2] for ta in turn_angles])
end

