# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

"""
    @enum FrameConvention KS KA

Body-frame convention, together with the world frame its orientation is reported
against. Only two combinations occur in the OpenSourceAWE packages:

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
`KS`, ENU for `KA`) to the world frame of the `to` convention.

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
frame of the `to` convention. `KS` is forward-right-down and `KA` aft-right-up, so
x and z flip and the spanwise y axis is left alone.

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
orientation is the body-to-world rotation: its columns are the body axes
expressed in the world frame.

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
against NED, because that is what the sensors report and what the flight
controllers expect.
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
    check_log_frame(table, name)

Warn if an Arrow log does not declare `KA` quaternions. A log written before
KiteUtils 0.13 carries no declaration at all and holds `KS` quaternions, which
`convert_orientation` turns into `KA`.
"""
function check_log_frame(table, name)
    meta = Arrow.getmetadata(table)
    convention = isnothing(meta) ? nothing : get(meta, "frame_convention", nothing)
    if convention != string(KA)
        @warn "Log $name declares no KA quaternions; it predates KiteUtils 0.13 and " *
              "its orientations are most likely KS. Convert them with " *
              "convert_orientation(q; from=KS, to=KA)." convention
    end
    nothing
end
