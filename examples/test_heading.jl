# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using Pkg
if ! ("ControlPlots" ∈ keys(Pkg.project().dependencies))
    Pkg.activate("examples")
end

using ControlPlots, KiteUtils, LinearAlgebra, Rotations, StaticArrays

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
function calc_kite_heading(turn_angle; x=100.0, z=0.0, r=20.0)
    orientation = collect(calc_orientation(turn_angle; x=x, z=z, r=r))
    el, az = calc_elevation_azimuth(turn_angle; x=x, z=z, r=r)
    calc_heading(orientation, el, az; respos=false)
end

# # Test the function calc_elevation_azimuth
# println("turn_angle => (elevation, azimuth)")
# for turn_angle in 0:30:360
#     el, az = calc_elevation_azimuth(deg2rad(turn_angle))
#     println("  $(turn_angle)deg => elevation: $(round(rad2deg(el), digits=2))deg, azimuth: $(round(rad2deg(az), digits=2))deg")
# end

# # Test the function calc_orientation
# println("\nturn_angle => (roll, pitch, yaw)")
# for turn_angle in 0:30:360
#     roll, pitch, yaw = calc_orientation(deg2rad(turn_angle))
#     println("  $(turn_angle)deg => roll: $(round(rad2deg(roll), digits=2))deg, pitch: $(round(rad2deg(pitch), digits=2))deg, yaw: $(round(rad2deg(yaw), digits=2))deg")
# end

# # Test the function calc_kite_heading
# println("\nturn_angle => heading")
# for turn_angle in 0:30:360
#     heading = calc_kite_heading(deg2rad(turn_angle))
#     println("  $(turn_angle)deg => heading: $(round(rad2deg(heading), digits=2))deg")
# end

# Helper: kite position on circle
function calc_kite_pos(turn_angle; x=100.0, z=0.0, r=20.0)
    center = [x, 0.0, z]
    e1, e2 = calc_circle_basis(x, z)
    return center + r * cos(turn_angle) * e1 + r * sin(turn_angle) * e2
end

# Compute data for multiple θ values
const theta = [30, 45, 60, 75]
turn_angles = 0:1:360
tether_length = 50.0  
ys_all = Vector{Vector{Float64}}()
zs_all = Vector{Vector{Float64}}()
headings_all = Vector{Vector{Float64}}()
psi_dot_all = Vector{Vector{Float64}}()
y_labels = String[]
z_labels = String[]
h_labels = String[]
pd_labels = String[]

for θ in theta
    local r
    r = tether_length * sin(deg2rad(θ))  # r is the radius of the circle
    x = r / tan(deg2rad(θ))
    push!(ys_all, [calc_kite_pos(deg2rad(ta); x=x, z=0.0, r=r)[2] for ta in turn_angles])
    push!(zs_all, [calc_kite_pos(deg2rad(ta); x=x, z=0.0, r=r)[3] for ta in turn_angles])
    push!(headings_all, [rad2deg(calc_kite_heading(deg2rad(ta); x=x, z=0.0, r=r)) for ta in turn_angles])
    push!(y_labels, "y (θ=$(θ)°)")
    push!(z_labels, "z (θ=$(θ)°)")
    push!(h_labels, "Ψ (θ=$(θ)°)")
    # Compute Ψ̇ = dΨ/d(turn_angle) using finite differences
    # First unwrap the heading to remove ±180° discontinuities
    h = headings_all[end]
    h_unwrap = copy(h)
    for j in 2:length(h_unwrap)
        while h_unwrap[j] - h_unwrap[j-1] > 180
            h_unwrap[j] -= 360
        end
        while h_unwrap[j] - h_unwrap[j-1] < -180
            h_unwrap[j] += 360
        end
    end
    dt = 1.0  # turn_angle step in degrees
    dh = similar(h)
    for j in 2:length(h_unwrap)-1
        dh[j] = (h_unwrap[j+1] - h_unwrap[j-1]) / (2 * dt)
    end
    dh[1] = (h_unwrap[2] - h_unwrap[1]) / dt
    dh[end] = (h_unwrap[end] - h_unwrap[end-1]) / dt
    push!(psi_dot_all, dh)
    push!(pd_labels, "\$\\dot{\\Psi}\$ (θ=$(θ)°)")
end

function plot_heading_and_position(turn_angles, theta, ys_all, zs_all, headings_all, psi_dot_all, h_labels, pd_labels)
    # Combined plot: "y and z" on top, "heading (Ψ)" in middle, "heading rate" on bottom
    plt.figure("heading and position", figsize=(10, 11))

    plt.subplot(3, 1, 1)
    colors = ["C0", "C1", "C2", "C3"]
    for i in eachindex(theta)
        y_lbl = i == 1 ? "y" : nothing
        z_lbl = i == 1 ? "z" : nothing
        plt.plot(collect(turn_angles), ys_all[i], "-", color=colors[i], label=y_lbl)
        plt.plot(collect(turn_angles), zs_all[i], ":", color=colors[i], label=z_lbl)
    end
    plt.ylabel("y, z [m]")
    yz_handles = [plt.matplotlib.lines.Line2D([0], [0], color="black", linestyle="-", label="y"),
                  plt.matplotlib.lines.Line2D([0], [0], color="black", linestyle=":", label="z")]
    leg1 = plt.legend(handles=yz_handles, loc="lower left")
    plt.gca().add_artist(leg1)
    # Second legend for theta/color mapping
    theta_handles = [plt.matplotlib.lines.Line2D([0], [0], color=colors[i], label="θ=$(theta[i])°") for i in eachindex(theta)]
    plt.legend(handles=theta_handles, loc="lower right")
    plt.grid(true)

    plt.subplot(3, 1, 2)
    for i in eachindex(theta)
        plt.plot(collect(turn_angles), headings_all[i], label=h_labels[i])
    end
    plt.ylabel("Ψ [°]")
    plt.legend()
    plt.grid(true)

    plt.subplot(3, 1, 3)
    for i in eachindex(theta)
        plt.plot(collect(turn_angles), psi_dot_all[i], label=pd_labels[i])
    end
    plt.xlabel("turn angle [°]")
    plt.ylabel("\$\\dot{\\Psi}\$ [°/°]")
    plt.legend()
    plt.grid(true)

    plt.tight_layout()
    plt.show(block=false)
end

# plot_heading_and_position(turn_angles, theta, ys_all, zs_all, headings_all, psi_dot_all, h_labels, pd_labels)

# Print orientation and position for each turn angle, and create SysState structs
println("turn_angle => orientation (roll, pitch, yaw) and position (x, y, z)")
for ta in turn_angles
    roll, pitch, yaw = calc_orientation(deg2rad(ta))
    pos = calc_kite_pos(deg2rad(ta))
    el, az = calc_elevation_azimuth(deg2rad(ta))
    heading = calc_kite_heading(deg2rad(ta))
    q = QuatRotation(RotZYX(yaw, pitch, roll))
    state = SysState{2}(
        orient    = MVector{4, Float32}(Rotations.params(q)),
        elevation = el,
        azimuth   = az,
        heading   = heading,
        roll      = roll,
        pitch     = pitch,
        yaw       = yaw,
        X         = MVector(0.0, pos[1]),
        Y         = MVector(0.0, pos[2]),
        Z         = MVector(0.0, pos[3]),
    )
    println("  $(ta)° => orientation: ($(round(rad2deg(roll), digits=2))°, $(round(rad2deg(pitch), digits=2))°, $(round(rad2deg(yaw), digits=2))°)  position: ($(round(pos[1], digits=2)), $(round(pos[2], digits=2)), $(round(pos[3], digits=2)))")
end
