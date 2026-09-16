# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

# Ergonomic views over the component-major SysState storage. Positions live in
# X/Y/Z (one entry per position slot), orientations in Qw/Qx/Qy/Qz (one entry per
# oriented frame). These views present per-entity vectors and keep the legacy
# `orient` property (frame 1) working for backwards compatibility.

"""
    SysState(P; wings=1, bodies=0, deflections=0, pulleys=0, winches=1,
             tethers=winches, segments=0, panels=0, precision=MyFloat)

Construct a `SysState` of `P` position slots. The remaining counts are keywords so
that adding a dimension does not add another positional method: `wings` wings and
`bodies` bodies, which together are its `wings + bodies` oriented frames,
`deflections` twist surfaces, `pulleys` pulleys, `winches` winches, `tethers`
tethers, `segments` segments and `panels` aerodynamic panels. `tethers` defaults to
`winches`, which is right whenever each winch drives one tether. Pass
`precision=Float64` for a differential state that round-trips `integrator.u` exactly.
"""
function SysState(P::Integer; wings=1, bodies=0, deflections=0, pulleys=0, winches=1,
                  tethers=winches, segments=0, panels=0, precision=MyFloat)
    SysState{P, wings + bodies, wings, deflections, pulleys, winches, tethers,
             segments, panels, precision}()
end

# ---- single-quaternion view (frame k), mutable, backed by Qw/Qx/Qy/Qz ----
struct FrameQuat{S, T} <: AbstractVector{T}
    ss::S
    k::Int
end
FrameQuat(ss::S, k::Int) where {S} =
    FrameQuat{S, eltype(getfield(ss, :Qw))}(ss, k)
Base.size(::FrameQuat) = (4,)
Base.@propagate_inbounds function Base.getindex(q::FrameQuat, i::Int)
    @boundscheck checkbounds(q, i)
    @inbounds (getfield(q.ss, :Qw)[q.k], getfield(q.ss, :Qx)[q.k],
        getfield(q.ss, :Qy)[q.k], getfield(q.ss, :Qz)[q.k])[i]
end
Base.@propagate_inbounds function Base.setindex!(q::FrameQuat, v, i::Int)
    @boundscheck checkbounds(q, i)
    @inbounds if i == 1
        getfield(q.ss, :Qw)[q.k] = v
    elseif i == 2
        getfield(q.ss, :Qx)[q.k] = v
    elseif i == 3
        getfield(q.ss, :Qy)[q.k] = v
    else
        getfield(q.ss, :Qz)[q.k] = v
    end
end

# ---- indexable collection of all orientation frames ----
struct OrientFrames{S, T} <: AbstractVector{FrameQuat{S, T}}
    ss::S
end
OrientFrames(ss::S) where {S} = OrientFrames{S, eltype(getfield(ss, :Qw))}(ss)
Base.size(o::OrientFrames) = (length(getfield(o.ss, :Qw)),)
Base.@propagate_inbounds function Base.getindex(o::OrientFrames, k::Int)
    @boundscheck checkbounds(o, k)
    FrameQuat(o.ss, k)
end
Base.@propagate_inbounds function Base.setindex!(o::OrientFrames, v, k::Int)
    @boundscheck checkbounds(o, k)
    FrameQuat(o.ss, k) .= v
end

# ---- single-point position view, mutable, backed by X/Y/Z ----
struct PointPos{S, T} <: AbstractVector{T}
    ss::S
    i::Int
end
PointPos(ss::S, i::Int) where {S} = PointPos{S, eltype(getfield(ss, :X))}(ss, i)
Base.size(::PointPos) = (3,)
Base.@propagate_inbounds function Base.getindex(p::PointPos, j::Int)
    @boundscheck checkbounds(p, j)
    @inbounds (getfield(p.ss, :X)[p.i], getfield(p.ss, :Y)[p.i],
        getfield(p.ss, :Z)[p.i])[j]
end
Base.@propagate_inbounds function Base.setindex!(p::PointPos, v, j::Int)
    @boundscheck checkbounds(p, j)
    @inbounds if j == 1
        getfield(p.ss, :X)[p.i] = v
    elseif j == 2
        getfield(p.ss, :Y)[p.i] = v
    else
        getfield(p.ss, :Z)[p.i] = v
    end
end

# ---- indexable collection of all point positions ----
struct PointPositions{S, T} <: AbstractVector{PointPos{S, T}}
    ss::S
end
PointPositions(ss::S) where {S} = PointPositions{S, eltype(getfield(ss, :X))}(ss)
Base.size(p::PointPositions) = (length(getfield(p.ss, :X)),)
Base.@propagate_inbounds function Base.getindex(p::PointPositions, i::Int)
    @boundscheck checkbounds(p, i)
    PointPos(p.ss, i)
end
Base.@propagate_inbounds function Base.setindex!(p::PointPositions, v, i::Int)
    @boundscheck checkbounds(p, i)
    PointPos(p.ss, i) .= v
end

# (SysState getproperty/setproperty! live in KiteUtils.jl, where the original
#  `.pos` accessor was defined, to avoid a duplicate-method precompile error.)

# ---- StructArray{SysState} (a SysLog's row store): expose .orient/.orients/.pos
# as lazy per-timestep columns so e.g. `syslog.orient[k]` keeps working. ----

# Time series of frame `k`'s quaternion: `column[t]` = quaternion at timestep t.
struct OrientColumn{SA, T} <: AbstractVector{SVector{4, T}}
    sa::SA
    k::Int
end
OrientColumn(sa::SA, k::Int) where {SA} =
    OrientColumn{SA, eltype(eltype(StructArrays.component(sa, :Qw)))}(sa, k)
Base.size(c::OrientColumn) = (length(StructArrays.component(c.sa, :Qw)),)
Base.@propagate_inbounds function Base.getindex(c::OrientColumn{SA, T}, t::Int) where {SA, T}
    @boundscheck checkbounds(c, t)
    @inbounds SVector{4, T}(
        StructArrays.component(c.sa, :Qw)[t][c.k],
        StructArrays.component(c.sa, :Qx)[t][c.k],
        StructArrays.component(c.sa, :Qy)[t][c.k],
        StructArrays.component(c.sa, :Qz)[t][c.k])
end

# `syslog.orients[k]` -> the OrientColumn time series of frame k.
struct OrientColumns{SA, T} <: AbstractVector{OrientColumn{SA, T}}
    sa::SA
end
OrientColumns(sa::SA) where {SA} =
    OrientColumns{SA, eltype(eltype(StructArrays.component(sa, :Qw)))}(sa)
Base.size(c::OrientColumns) =
    (isempty(StructArrays.component(c.sa, :Qw)) ? 0 :
     length(StructArrays.component(c.sa, :Qw)[1]),)
Base.@propagate_inbounds function Base.getindex(c::OrientColumns, k::Int)
    @boundscheck checkbounds(c, k)
    OrientColumn(c.sa, k)
end

# Time series of point `i`'s position: `column[t]` = position at timestep t.
struct PosColumn{SA, T} <: AbstractVector{SVector{3, T}}
    sa::SA
    i::Int
end
PosColumn(sa::SA, i::Int) where {SA} =
    PosColumn{SA, eltype(eltype(StructArrays.component(sa, :X)))}(sa, i)
Base.size(c::PosColumn) = (length(StructArrays.component(c.sa, :X)),)
Base.@propagate_inbounds function Base.getindex(c::PosColumn{SA, T}, t::Int) where {SA, T}
    @boundscheck checkbounds(c, t)
    @inbounds SVector{3, T}(
        StructArrays.component(c.sa, :X)[t][c.i],
        StructArrays.component(c.sa, :Y)[t][c.i],
        StructArrays.component(c.sa, :Z)[t][c.i])
end

# `syslog.pos[i]` -> the PosColumn time series of point i.
struct PosColumns{SA, T} <: AbstractVector{PosColumn{SA, T}}
    sa::SA
end
PosColumns(sa::SA) where {SA} =
    PosColumns{SA, eltype(eltype(StructArrays.component(sa, :X)))}(sa)
Base.size(c::PosColumns) =
    (isempty(StructArrays.component(c.sa, :X)) ? 0 :
     length(StructArrays.component(c.sa, :X)[1]),)
Base.@propagate_inbounds function Base.getindex(c::PosColumns, i::Int)
    @boundscheck checkbounds(c, i)
    PosColumn(c.sa, i)
end

# ---- wings and bodies: the oriented frames and position slots by their offsets ----
frame_counts(::SysState{P, O, K}) where {P, O, K} = (P, O, K)
frame_counts(::StructArray{<:SysState{P, O, K}}) where {P, O, K} = (P, O, K)
frame_view(state::SysState, k) = FrameQuat(state, k)
frame_view(log::StructArray{<:SysState}, k) = OrientColumn(log, k)
point_view(state::SysState, i) = PointPos(state, i)
point_view(log::StructArray{<:SysState}, i) = PosColumn(log, i)

"""
    wing_Q(state, k)

The quaternion of wing `k`, `Q[k]`: a mutable view into a `SysState`, or the time
series of a `SysLog`'s `syslog`.
"""
function wing_Q(state, k::Int)
    _, _, K = frame_counts(state)
    checkbounds(Base.OneTo(K), k)
    frame_view(state, k)
end

"""
    body_Q(state, b)

The quaternion of body `b`, `Q[K + b]` behind the K wings, as [`wing_Q`](@ref) does.
"""
function body_Q(state, b::Int)
    _, O, K = frame_counts(state)
    checkbounds(Base.OneTo(O - K), b)
    frame_view(state, K + b)
end

"""
    wing_pos(state, k)

The position of wing `k`, the `k`-th of the last O position slots: a mutable view into
a `SysState`, or the time series of a `SysLog`'s `syslog`.
"""
function wing_pos(state, k::Int)
    P, O, K = frame_counts(state)
    checkbounds(Base.OneTo(K), k)
    point_view(state, P - O + k)
end

"""
    body_pos(state, b)

The position of body `b`, the slot behind the K wings' in the last O, as
[`wing_pos`](@ref) does.
"""
function body_pos(state, b::Int)
    P, O, K = frame_counts(state)
    checkbounds(Base.OneTo(O - K), b)
    point_view(state, P - O + K + b)
end

@inline function Base.getproperty(sa::StructArray{<:SysState}, key::Symbol)
    if key === :orient
        return OrientColumn(sa, 1)
    elseif key === :orients
        return OrientColumns(sa)
    elseif key === :pos
        return PosColumns(sa)
    else
        return StructArrays.component(sa, key)
    end
end
