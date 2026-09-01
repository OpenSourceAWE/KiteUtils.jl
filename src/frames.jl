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
    KS2KA(rot::AbstractMatrix)
    KS2KA(q::QuatRotation)
    KS2KA(q::AbstractVector)

Convert an orientation from the `KS` convention to the `KA` convention. The
orientation is the rotation from the body frame to the world frame: its columns are
the body axes expressed in the world frame.

Both the world frame and the body frame change, so unlike a vector an orientation is
rotated on both sides. The orientation may be given as a `QuatRotation`, as a
rotation matrix or as a 4-element vector `[w, i, j, k]`; the result has the same type
as the argument. A world vector takes [`ENU2NED`](@ref) instead.
"""
KS2KA(rot::AbstractMatrix) = WORLD_FLIP * rot * BODY_FLIP
KS2KA(q::QuatRotation) = QuatRotation(KS2KA(RotMatrix{3}(q)))
function KS2KA(q::AbstractVector)
    length(q) == 4 || throw(ArgumentError("KS2KA converts an orientation, but got a " *
        "$(length(q))-element vector; a world or body vector is not an orientation."))
    SVector{4}(Rotations.params(KS2KA(QuatRotation(q))))
end

"""
    KA2KS(orientation)

Convert an orientation from the `KA` convention to the `KS` convention. The
conversion is an involution, so this is [`KS2KA`](@ref).
"""
KA2KS(orientation) = KS2KA(orientation)

"""
    orient_matrix(attitude, frame::FrameConvention=KA)

Rotation matrix of the kite in the `KA` convention, whatever form and convention
`attitude` arrives in: a quaternion (`QuatRotation` or `[w, i, j, k]`), a
rotation matrix, or roll, pitch and yaw angles as a 3-element vector. Euler
angles are always `KS`, since that is the only convention they are reported in.
"""
orient_matrix(q::QuatRotation, frame::FrameConvention=KA) =
    RotMatrix{3}(frame === KS ? KS2KA(q) : q)
orient_matrix(rot::AbstractMatrix, frame::FrameConvention=KA) =
    RotMatrix{3}(frame === KS ? KS2KA(SMatrix{3, 3}(rot)) : SMatrix{3, 3}(rot))
function orient_matrix(attitude::AbstractVector, frame::FrameConvention=KA)
    if length(attitude) == 3
        return orient_matrix(euler2rot(attitude[begin], attitude[begin+1],
                                       attitude[begin+2]), KS)
    end
    orient_matrix(QuatRotation(attitude), frame)
end

"""
    euler_KS(attitude, frame::FrameConvention=KA)

Roll, pitch and yaw angles in radian of a kite whose attitude is given in the
`frame` convention. The angles themselves are always `KS`: they are measured
against NED, because that is what the sensors report and what flight test data
is compared against.
"""
function euler_KS(attitude, frame::FrameConvention=KA)
    quat2euler(QuatRotation(KA2KS(orient_matrix(attitude, frame))))
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
    KS2KA_columns!(Qw, Qx, Qy, Qz)

Convert every orientation in a log's quaternion columns from `KS` to `KA` in place,
one per timestep and oriented frame. The columns must be mutable; Arrow columns are
not.
"""
function KS2KA_columns!(Qw, Qx, Qy, Qz)
    for t in eachindex(Qw), k in eachindex(Qw[t])
        q = KS2KA(SVector(Qw[t][k], Qx[t][k], Qy[t][k], Qz[t][k]))
        Qw[t][k], Qx[t][k], Qy[t][k], Qz[t][k] = q
    end
    nothing
end
