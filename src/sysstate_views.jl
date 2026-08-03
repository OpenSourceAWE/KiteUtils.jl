# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

# Ergonomic views over the component-major SysState storage. Positions live in
# X/Y/Z (one entry per point), orientations in Qw/Qx/Qy/Qz (one entry per
# oriented frame). These views present per-entity vectors and keep the legacy
# `orient` property (frame 1) working for backwards compatibility.

"""
    SysState{P}()
    SysState{P, O}()

Construct a `SysState` with `P` points, `O` oriented frames (default 1), and no aero
segments (`D = 0`). Fewer type parameters default the rest, so pre-`orients` and
pre-`flap_angle` call sites keep working.
"""
SysState{P}() where {P} = SysState{P, 1, 0}()
SysState{P}(args...; kwargs...) where {P} = SysState{P, 1, 0}(args...; kwargs...)
SysState{P, O}() where {P, O} = SysState{P, O, 0}()
SysState{P, O}(args...; kwargs...) where {P, O} = SysState{P, O, 0}(args...; kwargs...)

# ---- single-quaternion view (frame k), mutable, backed by Qw/Qx/Qy/Qz ----
struct FrameQuat{S} <: AbstractVector{Float32}
    ss::S
    k::Int
end
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
struct OrientFrames{S} <: AbstractVector{FrameQuat{S}}
    ss::S
end
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
struct PointPos{S} <: AbstractVector{MyFloat}
    ss::S
    i::Int
end
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
struct PointPositions{S} <: AbstractVector{PointPos{S}}
    ss::S
end
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
struct OrientColumn{SA} <: AbstractVector{SVector{4, Float32}}
    sa::SA
    k::Int
end
Base.size(c::OrientColumn) = (length(StructArrays.component(c.sa, :Qw)),)
Base.@propagate_inbounds function Base.getindex(c::OrientColumn, t::Int)
    @boundscheck checkbounds(c, t)
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
Base.@propagate_inbounds function Base.getindex(c::OrientColumns, k::Int)
    @boundscheck checkbounds(c, k)
    OrientColumn(c.sa, k)
end

# Time series of point `i`'s position: `column[t]` = position at timestep t.
struct PosColumn{SA} <: AbstractVector{SVector{3, MyFloat}}
    sa::SA
    i::Int
end
Base.size(c::PosColumn) = (length(StructArrays.component(c.sa, :X)),)
Base.@propagate_inbounds function Base.getindex(c::PosColumn, t::Int)
    @boundscheck checkbounds(c, t)
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
Base.@propagate_inbounds function Base.getindex(c::PosColumns, i::Int)
    @boundscheck checkbounds(c, i)
    PosColumn(c.sa, i)
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
