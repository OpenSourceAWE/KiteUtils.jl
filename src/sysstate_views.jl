# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

# Ergonomic views over the component-major SysState storage. Positions live in
# X/Y/Z (one entry per point), orientations in Qw/Qx/Qy/Qz (one entry per
# oriented frame). These views present per-entity vectors and keep the legacy
# `orient` property (frame 1) working for backwards compatibility.

"""
    SysState{P}()

Construct a `SysState` with `P` points and a single oriented frame (`O = 1`),
matching the pre-`orients` layout.
"""
SysState{P}() where {P} = SysState{P, 1}()
SysState{P}(args...; kwargs...) where {P} = SysState{P, 1}(args...; kwargs...)

# ---- single-quaternion view (frame k), mutable, backed by Qw/Qx/Qy/Qz ----
struct FrameQuat{S} <: AbstractVector{Float32}
    ss::S
    k::Int
end
Base.size(::FrameQuat) = (4,)
@inline Base.getindex(q::FrameQuat, i::Int) = @inbounds (getfield(q.ss, :Qw)[q.k],
    getfield(q.ss, :Qx)[q.k], getfield(q.ss, :Qy)[q.k], getfield(q.ss, :Qz)[q.k])[i]
@inline function Base.setindex!(q::FrameQuat, v, i::Int)
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
struct OrientFrames{S} <: AbstractVector{FrameQuat{S}}
    ss::S
end
Base.size(o::OrientFrames) = (length(getfield(o.ss, :Qw)),)
Base.getindex(o::OrientFrames, k::Int) = FrameQuat(o.ss, k)
Base.setindex!(o::OrientFrames, v, k::Int) = (FrameQuat(o.ss, k) .= v)

# ---- single-point position view, mutable, backed by X/Y/Z ----
struct PointPos{S} <: AbstractVector{MyFloat}
    ss::S
    i::Int
end
Base.size(::PointPos) = (3,)
@inline Base.getindex(p::PointPos, j::Int) = @inbounds (getfield(p.ss, :X)[p.i],
    getfield(p.ss, :Y)[p.i], getfield(p.ss, :Z)[p.i])[j]
@inline function Base.setindex!(p::PointPos, v, j::Int)
    @inbounds if j == 1
        getfield(p.ss, :X)[p.i] = v
    elseif j == 2
        getfield(p.ss, :Y)[p.i] = v
    else
        getfield(p.ss, :Z)[p.i] = v
    end
end

# ---- indexable collection of all point positions ----
struct PointPositions{S} <: AbstractVector{PointPos{S}}
    ss::S
end
Base.size(p::PointPositions) = (length(getfield(p.ss, :X)),)
Base.getindex(p::PointPositions, i::Int) = PointPos(p.ss, i)
Base.setindex!(p::PointPositions, v, i::Int) = (PointPos(p.ss, i) .= v)

# (SysState getproperty/setproperty! live in KiteUtils.jl, where the original
#  `.pos` accessor was defined, to avoid a duplicate-method precompile error.)

# ---- StructArray{SysState} (a SysLog's row store): expose .orient/.orients/.pos
# as lazy per-timestep columns so e.g. `syslog.orient[k]` keeps working. ----

# Time series of frame `k`'s quaternion: `column[t]` = quaternion at timestep t.
struct OrientColumn{SA} <: AbstractVector{SVector{4, Float32}}
    sa::SA
    k::Int
end
Base.size(c::OrientColumn) = (length(StructArrays.component(c.sa, :Qw)),)
@inline function Base.getindex(c::OrientColumn, t::Int)
    @inbounds SVector{4, Float32}(
        StructArrays.component(c.sa, :Qw)[t][c.k],
        StructArrays.component(c.sa, :Qx)[t][c.k],
        StructArrays.component(c.sa, :Qy)[t][c.k],
        StructArrays.component(c.sa, :Qz)[t][c.k])
end

# `syslog.orients[k]` -> the OrientColumn time series of frame k.
struct OrientColumns{SA} <: AbstractVector{OrientColumn{SA}}
    sa::SA
end
Base.size(c::OrientColumns) =
    (isempty(StructArrays.component(c.sa, :Qw)) ? 0 :
     length(StructArrays.component(c.sa, :Qw)[1]),)
Base.getindex(c::OrientColumns, k::Int) = OrientColumn(c.sa, k)

# Time series of point `i`'s position: `column[t]` = position at timestep t.
struct PosColumn{SA} <: AbstractVector{SVector{3, MyFloat}}
    sa::SA
    i::Int
end
Base.size(c::PosColumn) = (length(StructArrays.component(c.sa, :X)),)
@inline function Base.getindex(c::PosColumn, t::Int)
    @inbounds SVector{3, MyFloat}(
        StructArrays.component(c.sa, :X)[t][c.i],
        StructArrays.component(c.sa, :Y)[t][c.i],
        StructArrays.component(c.sa, :Z)[t][c.i])
end

# `syslog.pos[i]` -> the PosColumn time series of point i.
struct PosColumns{SA} <: AbstractVector{PosColumn{SA}}
    sa::SA
end
Base.size(c::PosColumns) =
    (isempty(StructArrays.component(c.sa, :X)) ? 0 :
     length(StructArrays.component(c.sa, :X)[1]),)
Base.getindex(c::PosColumns, i::Int) = PosColumn(c.sa, i)

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
