"""
Functions to transform between coordinate systems.
"""

ENU2EG = @SMatrix [ 0  1  0;
                   -1  0  0;
                    0  0  1]

""" 
    fromENU2EG(pointENU)

Transform the position of the kite in the East North Up reference frame to the Earth Groundstation
(North West Up) reference frame.
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

- orientation in Euler angles (roll, pitch, yaw)
"""
function fromKS2EX(vector, orientation)
    roll, pitch, yaw  = orientation[1], orientation[2], orientation[3]
    rotateYAW = @SMatrix[cos(yaw) -sin(yaw) 0;
                         sin(yaw)  cos(yaw) 0;
                             0         0    1]
    rotatePITCH = @SMatrix[cos(pitch)   0  sin(pitch);
                             0          1        0;
                       -sin(pitch)      0  cos(pitch)]
    rotateROLL = @SMatrix[ 1        0         0;
                           0   cos(roll) -sin(roll);
                           0   sin(roll)  cos(roll)]
    rotateYAW * rotatePITCH * rotateROLL * vector
end

"""
    fromEX2EG(vector)

Transform a vector (x,y,z) from EarthXsens to Earth Groundstation reference frame
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
    calc_heading_w(orientation, down_wind_direction = pi/2.0)

Calculate the heading vector in wind reference frame.
"""
function calc_heading_w(orientation, down_wind_direction = pi/2.0)
    # create a unit heading vector in the xsense reference frame
    heading_sensor =  SVector(1, 0, 0)
    # rotate headingSensor to the Earth Xsens reference frame
    headingEX = fromKS2EX(heading_sensor, orientation)
    # rotate headingEX to earth groundstation reference frame
    headingEG = fromEX2EG(headingEX)
    # rotate headingEG to headingW and convert to 2d HeadingW vector
    fromEG2W(headingEG, down_wind_direction)
end

"""
    calc_heading(orientation, elevation, azimuth; upwind_dir=-pi/2, respos=true)

Calculate the heading angle of the kite in radians. The heading is the direction
the nose of the kite is pointing to. The orientation is given in Euler angles,
calculated with respect to the North, East, Down reference frame.
If respos is true the heading angle is defined in the range of 0 .. 2π,
otherwise in the range -π .. π
"""
function calc_heading(orientation, elevation, azimuth; upwind_dir=-pi/2, respos=true)
    down_wind_direction = wrap2pi(upwind_dir + π)
    headingSE = fromW2SE(calc_heading_w(orientation, down_wind_direction), elevation, azimuth)
    angle = atan(headingSE.y, headingSE.x)
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
- respos:              If true, the result is in the range 0 .. 2π, otherwis -π .. π
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
