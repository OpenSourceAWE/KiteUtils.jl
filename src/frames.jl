# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

"""
    @enum FrameConvention KS KA

Body-frame convention, together with the world frame its orientation is reported
against. A body frame is attached to the kite and turns with it; a world frame is
earth-fixed and does not. Only two combinations occur in the OpenSourceAWE packages:

- `KS`: kite-sensor body frame, forward-right-down, reported against NED. The
  convention of the Xsens IMU and of `KiteModels`.
- `KA`: kite-aero body frame, aft-right-up, reported against ENU. x runs from
  leading to trailing edge, y spanwise from the left to the right tip, z up, so
  drag is +x, side force +y and lift +z.

`KA` is the convention of `SysState` and of every calculation in this package.
See [Reference frames](@ref).
"""
@enum FrameConvention KS KA

# ENU <-> NED. Involution, so one matrix serves both directions.
const WORLD_FLIP = @SMatrix [0 1 0; 1 0 0; 0 0 -1]

# KS <-> KA: 180 degrees about the shared spanwise axis. Also an involution.
const BODY_FLIP = @SMatrix [-1 0 0; 0 1 0; 0 0 -1]

"""
    convert_world(vec; from=KS, to=KA)

Convert a vector expressed in the world frame of the `from` convention (NED for
`KS`, ENU for `KA`) to the world frame of the `to` convention. World frames are
earth-fixed, so this rotation does not depend on where the kite is pointing.

Only for world quantities such as position, velocity or force in ENU. A body
vector needs [`convert_body`](@ref) and an orientation needs
[`convert_orientation`](@ref); using this function on either is wrong.
"""
function convert_world(vec::AbstractVector; from::FrameConvention=KS,
                       to::FrameConvention=KA)
    from === to ? SVector{3}(vec) : WORLD_FLIP * vec
end

"""
    convert_body(vec; from=KS, to=KA)

Convert a vector expressed in the body frame of the `from` convention to the body
frame of the `to` convention. Both frames turn with the kite, so this is a
relabelling of the same physical vector: `KS` is forward-right-down and `KA`
aft-right-up, so x and z flip and the spanwise y axis is left alone.

Only for body quantities such as an aerodynamic force, a moment or a turn rate.
"""
function convert_body(vec::AbstractVector; from::FrameConvention=KS,
                      to::FrameConvention=KA)
    from === to ? SVector{3}(vec) : BODY_FLIP * vec
end

"""
    convert_orientation(rot::AbstractMatrix; from=KS, to=KA)
    convert_orientation(q::QuatRotation; from=KS, to=KA)
    convert_orientation(q::AbstractVector; from=KS, to=KA)

Convert an orientation from the `from` convention to the `to` convention. The
orientation is the rotation from the body frame to the world frame: its columns
are the body axes expressed in the world frame.

Both the world frame and the body frame change, so unlike a vector an
orientation is rotated on both sides. The quaternion may be given as a
`QuatRotation`, as a rotation matrix or as a 4-element vector `[w, i, j, k]`; the
result has the same type as the argument.
"""
function convert_orientation(rot::AbstractMatrix; from::FrameConvention=KS,
                             to::FrameConvention=KA)
    from === to ? SMatrix{3, 3}(rot) : WORLD_FLIP * rot * BODY_FLIP
end
function convert_orientation(q::QuatRotation; from::FrameConvention=KS,
                             to::FrameConvention=KA)
    from === to ? q : QuatRotation(convert_orientation(RotMatrix{3}(q); from, to))
end
function convert_orientation(q::AbstractVector; from::FrameConvention=KS,
                             to::FrameConvention=KA)
    from === to ? SVector{4}(q) :
        SVector{4}(Rotations.params(convert_orientation(QuatRotation(q); from, to)))
end

"""
    orient_matrix(attitude, frame::FrameConvention=KA)

Rotation matrix of the kite in the `KA` convention, whatever form and convention
`attitude` arrives in: a quaternion (`QuatRotation` or `[w, i, j, k]`), a
rotation matrix, or roll, pitch and yaw angles as a 3-element vector. Euler
angles are always `KS`, since that is the only convention they are reported in.
"""
orient_matrix(q::QuatRotation, frame::FrameConvention=KA) =
    RotMatrix{3}(convert_orientation(q; from=frame, to=KA))
orient_matrix(rot::AbstractMatrix, frame::FrameConvention=KA) =
    RotMatrix{3}(convert_orientation(SMatrix{3, 3}(rot); from=frame, to=KA))
function orient_matrix(attitude::AbstractVector, frame::FrameConvention=KA)
    if length(attitude) == 3
        return orient_matrix(euler2rot(attitude[begin], attitude[begin+1],
                                       attitude[begin+2]), KS)
    end
    orient_matrix(QuatRotation(attitude), frame)
end

"""
    euler_ks(attitude, frame::FrameConvention=KA)

Roll, pitch and yaw angles in radian of a kite whose attitude is given in the
`frame` convention. The angles themselves are always `KS`: they are measured
against NED, because that is what the sensors report and what flight test data
is compared against.
"""
function euler_ks(attitude, frame::FrameConvention=KA)
    quat2euler(QuatRotation(convert_orientation(orient_matrix(attitude, frame);
                                                from=KA, to=KS)))
end

"""
    kite_nose(attitude, frame::FrameConvention=KA)

Unit vector in ENU pointing from the trailing edge towards the leading edge of
the kite, i.e. the direction the nose is pointing in. This is `-x` of the `KA`
body frame, whose x axis runs aft.
"""
function kite_nose(attitude, frame::FrameConvention=KA)
    rot = orient_matrix(attitude, frame)
    SVector(-rot[1, 1], -rot[2, 1], -rot[3, 1])
end

"""
    log_metadata()

Table-level metadata written into every `.arrow` log, recording the frame convention
its quaternions are in. Without it a log cannot be told apart from one written before
KiteUtils 0.13, whose quaternions are `KS`.
"""
log_metadata() = Dict("frame_convention" => string(KA),
                      "kiteutils_version" => string(pkgversion(@__MODULE__)))

"""
    log_convention(table)

Frame convention an Arrow log declares, or `nothing` when it declares none. Only
logs written by KiteUtils 0.13 and later carry a declaration, so `nothing` means
the log is older and its convention has to be assumed.
"""
function log_convention(table)
    meta = Arrow.getmetadata(table)
    isnothing(meta) && return nothing
    name = get(meta, "frame_convention", nothing)
    name == string(KA) && return KA
    name == string(KS) && return KS
    nothing
end

"""
    convert_orient_columns!(Qw, Qx, Qy, Qz; from, to=KA)

Convert every orientation in a log's quaternion columns in place, one per
timestep and oriented frame. The columns must be mutable; Arrow columns are not.
"""
function convert_orient_columns!(Qw, Qx, Qy, Qz; from::FrameConvention,
                                 to::FrameConvention=KA)
    from === to && return nothing
    for t in eachindex(Qw), k in eachindex(Qw[t])
        q = convert_orientation(SVector(Qw[t][k], Qx[t][k], Qy[t][k], Qz[t][k]);
                                from, to)
        Qw[t][k], Qx[t][k], Qy[t][k], Qz[t][k] = q
    end
    nothing
end
