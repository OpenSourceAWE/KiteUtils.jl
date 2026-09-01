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
    fromKS2KA(rot::AbstractMatrix)
    fromKS2KA(q::QuatRotation)
    fromKS2KA(q::AbstractVector)

Convert an orientation from the `KS` convention to the `KA` convention. The
orientation is the rotation from the body frame to the world frame: its columns are
the body axes expressed in the world frame.

Both the world frame and the body frame change, so converting an orientation rotates
each of them, where a world vector needs only the world frame rotated and takes
[`fromENU2NED`](@ref) instead. The orientation may be given as a `QuatRotation`, as a
rotation matrix or as a 4-element vector `[w, i, j, k]`; the result has the same type
as the argument.
"""
fromKS2KA(rot::AbstractMatrix) = WORLD_FLIP * rot * BODY_FLIP
fromKS2KA(q::QuatRotation) = QuatRotation(fromKS2KA(RotMatrix{3}(q)))
function fromKS2KA(q::AbstractVector)
    length(q) == 4 || throw(ArgumentError("fromKS2KA converts an orientation, but got a " *
        "$(length(q))-element vector; a world or body vector is not an orientation."))
    SVector{4}(Rotations.params(fromKS2KA(QuatRotation(q))))
end

"""
    fromKA2KS(orientation)

Convert an orientation from the `KA` convention to the `KS` convention. The
conversion is an involution, so this is [`fromKS2KA`](@ref).
"""
fromKA2KS(orientation) = fromKS2KA(orientation)

"""
    orient_matrix(attitude)

Rotation matrix of the kite in the `KA` convention, whatever form `attitude` arrives
in: a quaternion (`QuatRotation` or `[w, i, j, k]`), a rotation matrix, or roll, pitch
and yaw angles as a 3-element vector. Everything but the Euler angles is already `KA`;
Euler angles are `KS`, that being the only convention they are reported in, and are
converted.
"""
orient_matrix(q::QuatRotation) = RotMatrix{3}(q)
orient_matrix(rot::AbstractMatrix) = RotMatrix{3}(SMatrix{3, 3}(rot))
function orient_matrix(attitude::AbstractVector)
    if length(attitude) == 3
        return RotMatrix{3}(fromKS2KA(euler2rot(attitude[begin], attitude[begin+1],
                                            attitude[begin+2])))
    end
    orient_matrix(QuatRotation(attitude))
end

"""
    euler_KS(attitude)

Roll, pitch and yaw angles in radian of a kite whose attitude is given in the `KA`
convention. The angles themselves are `KS`: they are measured against NED, because
that is what the sensors report and what flight test data is compared against.
"""
euler_KS(attitude) = quat2euler(QuatRotation(fromKA2KS(orient_matrix(attitude))))

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
    fromKS2KA_columns!(Qw, Qx, Qy, Qz)

Convert every orientation in a log's quaternion columns from `KS` to `KA` in place,
one per timestep and oriented frame. The columns must be mutable; Arrow columns are
not.
"""
function fromKS2KA_columns!(Qw, Qx, Qy, Qz)
    for t in eachindex(Qw), k in eachindex(Qw[t])
        q = fromKS2KA(SVector(Qw[t][k], Qx[t][k], Qy[t][k], Qz[t][k]))
        Qw[t][k], Qx[t][k], Qy[t][k], Qz[t][k] = q
    end
    nothing
end
