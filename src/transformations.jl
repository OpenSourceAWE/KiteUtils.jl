# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

"""
    rot3d(ax, ay, az, bx, by, bz)

Calculate the rotation matrix that needs to be applied on the reference frame (ax, ay, az) to match 
the reference frame (bx, by, bz).
All parameters must be 3-element vectors. Both reference frames must be orthogonal,
all vectors must already be normalized.

Source: [TRIAD_Algorithm](http://en.wikipedia.org/wiki/User:Snietfeld/TRIAD_Algorithm)
"""
function rot3d(ax, ay, az, bx, by, bz)
    R_ai = hcat(ax, az, ay)
    R_bi = hcat(bx, bz, by)
    return R_bi * R_ai'
end

"""
    is_right_handed_orthonormal(x, y, z)

Returns `true` if the vectors `x`, `y` and `z` form a right-handed orthonormal basis.
"""
function is_right_handed_orthonormal(x, y, z)
    R = [x y z]
    R*R' ≈ I && det(R) ≈ 1
end

"""
    quat2euler(q::QuatRotation)
    quat2euler(q::AbstractVector)

Convert a quaternion to roll, pitch, and yaw angles in radian.
The quaternion can be a 4-element vector (w, i, j, k) or a QuatRotation object.
"""
quat2euler(q::AbstractVector) = quat2euler(QuatRotation(q))
function quat2euler(q::QuatRotation)  
    D = RFR.DCM(q)
    pitch = asin2(-D[3,1])
    roll  = atan(D[3,2], D[3,3])
    yaw   = atan(D[2,1], D[1,1])
    return roll, pitch, yaw
end

"""
    rot(pos_kite, pos_before, v_app)

Calculate the rotation matrix of the kite based on the position of the
last two tether particles and the apparent wind speed vector. Assumption: 
The kite aligns with the apparent wind direction. If used for the model
`KPS4`, pass the vector `-x` of the kite reference frame instead of v_app. 
"""
function rot(pos_kite, pos_before, v_app)
    delta = pos_kite - pos_before
    @assert norm(delta) > zero(eltype(delta)) "Error in function rot() ! pos_kite must be not equal to pos_before. "
    c = -delta
    z = normalize(c)
    y = normalize(cross(-v_app, c))
    x = normalize(cross(y, c))
    one_ = one(eltype(delta))
    rot3d(SVector(0,-one_,0), SVector(one_,0,0), SVector(0,0,-one_), z, y, x)
end


"""
    ENU2NED(vec::AbstractVector)

Convert a vector from ENU (east, north, up) to NED (north, east, down) reference frame.
"""
function ENU2NED(vec::AbstractVector)
    WORLD_FLIP * vec
end

"""
    NED2ENU(vec::AbstractVector)

Convert a vector from NED (north, east, down) to ENU (east, north, up) reference frame.
"""
NED2ENU(vec::AbstractVector) = ENU2NED(vec)

"""
    calc_orient_rot(x, y, z; viewer=false, ENU=true)

Calculate the rotation matrix based on the kite reference frame, by default 
passed as ENU (east, north, up), or as NED (north, east, down) if ENU is false.
If viewer is true, the rotation matrix is calculated based with respect to
the viewer reference frame.

The axes and the result are `KS`; pass the result through
[`KS2KA`](@ref) to obtain the `KA` orientation stored in `SysState`.
For `KA` axes given in ENU the orientation is simply `[x y z]`, no function needed.
"""
function calc_orient_rot(x, y, z; viewer=false, ENU=true)
    if ENU
        x = ENU2NED(x)
        y = ENU2NED(y)
        z = ENU2NED(z)
    end
    if viewer
        pos_kite_ = @SVector ones(3)
        pos_before = pos_kite_ .+ z
        rotation = rot(pos_kite_, pos_before, -x)
    else
        # reference frame for the orientation: NED (north, east, down)
        ax = @SVector [1, 0, 0]
        ay = @SVector [0, 1, 0]
        az = @SVector [0, 0, 1]
        rotation = rot3d(ax, ay, az, x, y, z)
    end
    return rotation
end

"""
    euler2rot(roll, pitch, yaw)

Calculate the rotation matrix based on the roll, pitch, and yaw angles in radian.
"""
function euler2rot(roll, pitch, yaw)
    φ, θ, ψ = roll, pitch, yaw
    R_x = @SMatrix[1    0       0;
                   0  cos(φ) -sin(φ);
                   0  sin(φ)  cos(φ)]
    R_y = @SMatrix[ cos(θ)  0  sin(θ);
                      0     1     0;
                   -sin(θ)  0  cos(θ)]
    R_z = @SMatrix[cos(ψ) -sin(ψ) 0;
                   sin(ψ)  cos(ψ) 0;
                     0       0    1]
    R_z * R_y * R_x
end

"""
    quat2viewer(attitude, frame::FrameConvention=KA)

Convert an orientation to the viewer reference frame. See [`kite_nose`](@ref) for
the accepted forms of `attitude`; `frame` says which convention it is given in.
Returns a quaternion as a 4-element vector [w,i,j,k].
"""
function quat2viewer(attitude, frame::FrameConvention=KA)
    quat2viewer_KS(QuatRotation(KA2KS(orient_matrix(attitude, frame))))
end

# Viewer conversion of a KS (NED) orientation. The viewer frame is defined in terms
# of KS, so this stays the reference implementation and quat2viewer converts into it.
function quat2viewer_KS(q::QuatRotation)
    # 1. get reference frame
    rot = inv(RotMatrix{3}(q)) # from kite to inertial reference frame
    x = ENU2NED(rot[1,:])
    y = ENU2NED(rot[2,:])
    z = ENU2NED(rot[3,:])
    # 2. convert it using the old method
    ax = @SVector [0, 1, 0]  # in ENU reference frame this is pointing to the south
    ay = @SVector [1, 0, 0]  # in ENU reference frame this is pointing to the west
    az = @SVector [0, 0, -1] # in ENU reference frame this is pointing down
    rot = rot3d(ax, ay, az, x, y, z) 
    x, z = rot*ax, rot*az # obtain x, z in inertial reference frame
    pos_kite_ = @SVector ones(3)
    pos_before = pos_kite_ .+ z
    rotation = KiteUtils.rot(pos_kite_, pos_before, -x)
    q = QuatRotation(rotation)
    return Rotations.params(q)
end

"""
    ground_dist(vec)

Calculate the ground distance of the kite from the groundstation based on the kite position (x,y,z, z up).
"""
function ground_dist(vec)
    sqrt(vec[begin]^2 + vec[begin+1]^2)
end 

"""
    calc_elevation(vec)

Calculate the elevation angle in radian from the kite position. 
"""
function calc_elevation(vec)
    atan(vec[begin+2] / ground_dist(vec))
end

"""
    azimuth_east(vec)

Calculate the azimuth angle in radian from the kite position in ENU reference frame.
Zero east. Positive direction clockwise seen from above.
Valid range: -π .. π.
"""
function azimuth_east(vec)
    return -atan(vec[begin+1], vec[begin])
end

"""
    azimuth_north(vec)

Calculate the azimuth angle in radian from the kite position in ENU reference frame.
Zero north. Positive direction anti-clockwise seen from above.
Valid range: -π .. π.
"""
function azimuth_north(vec)
    res = -pi/2 - azimuth_east(vec)
    return wrap2pi(res)
end

"""
    azn2azw(azimuth_north; upwind_dir = -π/2)

Calculate the azimuth in the wind reference frame.
The `upwind_dir` is the direction the wind is coming from
Zero is at north; clockwise positive. Default: Wind from west.

Returns:
- Angle in radians. Zero straight downwind. Positive direction clockwise seen
  from above.
- Valid range: -pi .. pi. 
"""
function azn2azw(azimuth_north; upwind_dir = -π/2)
    result = azimuth_north + upwind_dir +pi
    wrap2pi(result)
end

"""
    asin2(arg)

Calculate the asin of arg, but allow values slightly above one and below
minus one to avoid exceptions in case of rounding errors. Returns an
angle in radian.
"""
@inline function asin2(arg)
   arg2 = min(max(arg, -one(arg)), one(arg))
   asin(arg2)
end

"""
    acos2(arg)

Calculate the acos of arg, but allow values slightly above one and below
minus one to avoid exceptions in case of rounding errors. Returns an
angle in radian.
"""
@inline function acos2(arg)
   arg2 = min(max(arg, -one(arg)), one(arg))
   acos(arg2)
end

"""
    wrap2pi(angle)

Limit the angle to the range -π .. π .
"""
wrap2pi(::typeof(pi)) = π
function wrap2pi(angle)
    y = rem(angle, 2π)
    abs(y) > π && (y -= 2π * sign(y))
    return y
end

"""
    wind_vec_from_angles(v_wind, upwind_dir, upwind_elevation)

Compute the wind vector in the ENU reference frame from wind speed,
upwind direction and upwind elevation. All angles in radians.

- `v_wind`: wind speed [m/s]
- `upwind_dir`: direction the wind is coming from, zero at north,
  clockwise positive [rad]
- `upwind_elevation`: angle of the upwind direction above the
  east-north plane [rad]

Returns an `SVec3` (east, north, up).
"""
function wind_vec_from_angles(v_wind, upwind_dir, upwind_elevation)
    downwind_azimuth = upwind_dir + π
    horizontal = v_wind * cos(upwind_elevation)
    east  = horizontal * sin(downwind_azimuth)
    north = horizontal * cos(downwind_azimuth)
    up    = -v_wind * sin(upwind_elevation)
    SVec3(east, north, up)
end

"""
    angles_from_wind_vec(wind_vec)

Compute wind speed, upwind direction and upwind elevation from a
wind vector in the ENU reference frame.

Returns `(v_wind, upwind_dir, upwind_elevation)`, all angles in
radians. `upwind_dir` is zero at north, clockwise positive, in
the range -π .. π. `upwind_elevation` is the angle of the upwind
direction above the east-north plane.
"""
function angles_from_wind_vec(wind_vec)
    east, north, up = wind_vec[1], wind_vec[2], wind_vec[3]
    v_wind = sqrt(east^2 + north^2 + up^2)
    if v_wind ≈ 0
        return (0.0, 0.0, 0.0)
    end
    downwind_azimuth = atan(east, north)
    upwind_dir = wrap2pi(downwind_azimuth - π)
    horizontal = sqrt(east^2 + north^2)
    upwind_elevation = atan(-up, horizontal)
    (v_wind, upwind_dir, upwind_elevation)
end
