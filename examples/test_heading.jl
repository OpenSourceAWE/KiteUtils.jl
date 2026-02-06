# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils, LinearAlgebra

# write calc_elevation_azimuth(turn_angle) that returns a tuple (elevation, azimuth) for a given turn angle in degrees. The elevation should be calculated as 90 - turn_angle, and the azimuth should be equal to the turn_angle.   
# assumptions:
# - turn_angle is in degrees and ranges from 0 to 360
# - the kite is flying in a vertical plane on a circle around the center of the circle, 
#   which is at  (x, 0, 0) (distance x from the attachment point of the tether)
# - the radius of the circle is r 
# - the tether is straight and taut, so the kite is always at a distance r from the center of the circle

"""
    calc_elevation_azimuth(turn_angle; x=100.0, r=20.0)

Calculate the elevation and azimuth angles in degrees for a kite flying on a vertical
circle of radius `r`, centered at `(x, 0, 0)` in the ENU reference frame.

The turn angle is measured from the top of the circle (12 o'clock position), going
clockwise when viewed from the north (positive y direction).

# Arguments
- `turn_angle`: the position of the kite on the circle in degrees (0 to 360).
                0° means the top of the circle (highest point), 90° means the kite
                is further downwind (east), 180° means the bottom, 270° means the kite
                is closer to the ground station (west).
- `x`: distance of the circle center from the ground station along the east axis [m]. Default: 100.0.
- `r`: radius of the circle [m]. Default: 20.0.

# Returns
A tuple `(elevation, azimuth)` in degrees.
- `elevation`: the elevation angle of the kite as seen from the ground station.
- `azimuth`: the azimuth angle (east-based) of the kite as seen from the ground station.
"""
function calc_elevation_azimuth(turn_angle; x=100.0, r=20.0)
    θ = deg2rad(turn_angle)
    # Kite position on a vertical circle in the east-up plane (north = 0)
    # turn_angle = 0° → top of circle, 90° → east (further downwind), etc.
    kite_east  = x + r * sin(θ)
    kite_north = 0.0
    kite_up    = r * cos(θ)
    pos = [kite_east, kite_north, kite_up]
    elevation = rad2deg(calc_elevation(pos))
    azimuth   = rad2deg(azimuth_east(pos))
    return (elevation, azimuth)
end

# Test the function
println("turn_angle => (elevation, azimuth)")
for turn_angle in 0:30:360
    el, az = calc_elevation_azimuth(turn_angle)
    println("  $(turn_angle)deg => elevation: $(round(el, digits=2))deg, azimuth: $(round(az, digits=2))deg")
end
