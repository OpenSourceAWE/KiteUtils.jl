# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

"""
Functions to transform between coordinate systems.
"""

ENU2EG = @SMatrix [ 0  1  0;
                   -1  0  0;
                    0  0  1]

""" 
    fromENU2EG(pointENU)

Transform the position of the kite in the ENU (east, north, up) reference frame to the
Earth Groundstation (north, west, up) reference frame.
"""
function fromENU2EG(pointENU)
    ENU2EG * pointENU
end

"""
    fromW2SE(vector, elevation, azimuth)

Transform a vector from a horizontal, z-up frame to the Small Earth (SE) frame at the kite
position `(elevation, azimuth)` [rad]: ENU with [`azimuth_east`](@ref), or the Wind frame
with the wind-frame azimuth. SE has x up the sphere towards zenith, y to the right seen
from the ground station and z along the outward radial.
"""
function fromW2SE(vector, elevation, azimuth)
    up_sphere = SVector(-sin(elevation) * cos(azimuth), -sin(elevation) * sin(azimuth),
                        cos(elevation))
    right = SVector(sin(azimuth), -cos(azimuth), zero(azimuth))
    radial = SVector(cos(elevation) * cos(azimuth), cos(elevation) * sin(azimuth),
                     sin(elevation))
    SVector(up_sphere ⋅ vector, right ⋅ vector, radial ⋅ vector)
end

""" 
    fromKS2EX(vector, orientation)

Transform a vector (x,y,z) from KiteSensor to Earth Xsens reference frame.

Sensor ingest only: everything downstream of the sensor works in `KA` and ENU.
- orientation in Euler angles (roll, pitch, yaw)
"""
function fromKS2EX(vector, orientation)
    euler2rot(orientation[begin], orientation[begin+1], orientation[begin+2]) * vector
end

"""
    fromEX2EG(vector)

Transform a vector (x,y,z) from EarthXsens to Earth Groundstation reference frame.

Sensor ingest only: everything downstream of the sensor works in `KA` and ENU.
"""
function fromEX2EG(vector)
    rotateEX2EG = @SMatrix[1  0  0;
                           0 -1  0;
                           0  0 -1]
    rotateEX2EG * vector
end

"""
    fromEG2W(vector, down_wind_direction = pi/2.0)

Transform a vector (x,y,z) from Earth Groundstation to Wind reference frame.
"""
function fromEG2W(vector, down_wind_direction = pi/2.0)
    rotateEG2W =    @SMatrix[cos(down_wind_direction) -sin(down_wind_direction)  0;
                             sin(down_wind_direction)  cos(down_wind_direction)  0;
                             0                        0                      1]
    rotateEG2W * vector
end

"""
    calc_heading_w(attitude, down_wind_direction = pi/2.0)

Calculate the heading vector in wind reference frame from a `KA` attitude. See
[`orient_matrix`](@ref) for the accepted forms of `attitude`.
"""
function calc_heading_w(attitude, down_wind_direction = pi/2.0)
    nose = -orient_matrix(attitude)[:, 1]
    fromEG2W(fromENU2EG(nose), down_wind_direction)
end

"""
    calc_heading(attitude, elevation, azimuth; respos=true)

Heading angle of the kite [rad]: the direction its nose points in the Small Earth frame,
zero towards zenith and positive right-handed about the outward radial, so a quarter turn
points the nose to the right as seen from the ground station.

- `attitude`: a `KA` quaternion or rotation matrix, or Euler angles (roll, pitch, yaw)
  [rad] against NED, which are `KS`; see [`orient_matrix`](@ref)
- `elevation`, `azimuth`: kite position [rad], `azimuth` as [`azimuth_east`](@ref)
- `respos`: return the angle in 0 .. 2π if true, else in -π .. π
"""
function calc_heading(attitude, elevation, azimuth; respos=true)
    nose = -orient_matrix(attitude)[:, 1]
    se_angle(nose, elevation, azimuth, respos)
end

"""
    calc_course(velocityENU, elevation, azimuth; respos=true)

Course angle of the kite [rad]: the direction of its velocity in the Small Earth frame,
with the angle convention of [`calc_heading`](@ref).

- `velocityENU`: kite velocity in ENU [m/s]
- `elevation`, `azimuth`: kite position [rad], `azimuth` as [`azimuth_east`](@ref)
- `respos`: return the angle in 0 .. 2π if true, else in -π .. π
"""
function calc_course(velocityENU, elevation, azimuth; respos=true)
    se_angle(velocityENU, elevation, azimuth, respos)
end

function se_angle(vectorENU, elevation, azimuth, respos)
    vectorSE = fromW2SE(vectorENU, elevation, azimuth)
    angle = atan(vectorSE[begin+1], vectorSE[begin])
    angle < 0 && respos ? angle + 2π : angle
end
