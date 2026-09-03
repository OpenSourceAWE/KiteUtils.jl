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

 Transform a (velocity-) vector (x,y,z) from Wind to Small Earth reference frame .
 """
function fromW2SE(vector, elevation, azimuth)
    rotate_first_step = @SMatrix[0  0  1;
                                 0  1  0;
                                -1  0  0]
    rotate_elevation = @SMatrix[cos(elevation) 0 sin(elevation);
                                0              1         0;
                             -sin(elevation)   0   cos(elevation)]
    rotate_azimuth = @SMatrix[1         0       0;
                              0  cos(-azimuth)   -sin(-azimuth);
                              0  sin(-azimuth)    cos(-azimuth)]
    rotate_elevation * rotate_azimuth * rotate_first_step * vector
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
    calc_heading(attitude, elevation, azimuth; upwind_dir=-pi/2, respos=true)

Calculate the heading angle of the kite in radians. The heading is the direction the nose 
of the kite is pointing to, expressed in the Small Earth (SE) reference frame.

# Arguments
- `attitude`:    Orientation of the kite as a `KA` quaternion or rotation matrix, or as
                 Euler angles (roll, pitch, yaw) in radian, which are `KS` (measured
                 against NED)
- `elevation`:   Elevation angle of the kite in radians
- `azimuth`:     Azimuth angle of the kite in radians
- `upwind_dir`:  Direction the wind is coming from in radians; zero at north; clockwise 
                 positive from above (default: -π/2, wind from west)
- `respos`:      If true, return angle in range [0, 2π]; if false, return in range [-π, π] 
                 (default: true)

# Returns
The heading angle in radians, measured from the positive x-axis of the SE reference frame.
"""
function calc_heading(attitude, elevation, azimuth; upwind_dir=-pi/2, respos=true)
    down_wind_direction = wrap2pi(upwind_dir + π)
    headingSE = fromW2SE(calc_heading_w(attitude, down_wind_direction),
                         elevation, azimuth)
    angle = atan(headingSE[begin+1], headingSE[begin])
    if angle < 0 && respos
        angle += 2π
    end
    angle
end

"""
    calc_course(velocityENU, elevation, azimuth, down_wind_direction = π/2, respos=true)

Calculate the course angle in radian.

- velocityENU:         Kite velocity in EastNorthUp reference frame
- down_wind_direction: The direction the wind is going to; zero at north;
                       clockwise positive from above; default: going to east.
- respos:              If true, the result is in the range 0 .. 2π, otherwise -π .. π
"""
function calc_course(velocityENU, elevation, azimuth, upwind_dir=-pi/2, respos=true)
    down_wind_direction = wrap2pi(upwind_dir + π)
    velocityEG = fromENU2EG(velocityENU)
    velocityW = fromEG2W(velocityEG, down_wind_direction)
    velocitySE = fromW2SE(velocityW, elevation, azimuth)
    angle = atan(velocitySE.y, velocitySE.x)
    if angle < 0  && respos
        angle += 2π
    end
    return(angle)
end
