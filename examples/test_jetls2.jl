# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

function calc_kite_pos(dummy; x=100.0, z=0.0, r=20.0)
    center = [x, 0.0, z]
    return center .+ r
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

