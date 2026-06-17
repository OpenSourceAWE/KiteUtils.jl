# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

"""
    KiteUtils

Utility functions for the kite simulators.

This module provides data structures for the flight state and the flight log,
functions for creating a demo flight state, demo flight log, loading and saving flight logs,
functions for reading the settings, and helper functions for working with rotations.

See the [documentation](https://OpenSourceAWE.github.io/KiteUtils.jl/stable/)
for more information.
"""
module KiteUtils

#= MIT License

Copyright (c) 2020, 2021, 2024 Uwe Fechner, Bart van de Lint

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

# data structures for the flight state and the flight log
# functions for creating a demo flight state, demo flight log, loading and saving flight logs
# function se() for reading the settings
# the parameter P is the number of points of the tether, equal to segments+1
# in addition helper functions for working with rotations

using PrecompileTools: @compile_workload, @setup_workload
using Arrow, DocStringExtensions, LinearAlgebra, RecursiveArrayTools, Rotations, StaticArrays, StructArrays, YAML
using CSV, Parameters, Parsers, Pkg, StructTypes
export Logger, MyFloat, Settings, SysLog, SysState

import Base.length
import ReferenceFrameRotations as RFR

export demo_log, demo_state, demo_syslog, export_log, import_log, load_log, save_log # functions for logging
export euler2rot, length, log!, menu, syslog
export demo_state_4p, initial_kite_ref_frame                                         # functions for four point kite model
export asin2, azimuth_east, azimuth_north, calc_elevation, ground_dist, rot, rot3d
export acos2, quat2euler, quat2viewer, wrap2pi                           # geometric functions
export fromEG2W, fromENU2EG, fromEX2EG, fromKS2EX, fromW2SE              # reference frame transformations
export azn2azw,  calc_clock_angle, calc_course , calc_heading, calc_heading_w # geometric functions
export calc_orient_rot, enu2ned, is_right_handed_orthonormal, ned2enu
export angles_from_wind_vec, wind_vec_from_angles
export copy_settings, get_data_path, load_settings, set_data_path        # functions for reading and copying parameters
export aero_geometry_file, fpc_settings, fpp_settings, se, se_dict,
    structural_geometry_file, update_settings,
    vsm_settings_file, wc_settings
export calculate_rotational_inertia
export AbstractKiteModel
export init!, next_step!, update_sys_state!

"""
    const MyFloat = Float32

Type used for position components and scalar SysState members.
"""
const MyFloat   = Float32           # type to use for position components and scalar SysState members
const DATA_PATH = ["data"]          # path for log files and other data
const MVec3     = MVector{3, Float64}
const SVec3     = SVector{3, Float64}

P = nothing # suppress warning about undefined global variable

function init! end
function next_step! end
function update_sys_state! end

"""
    abstract type AbstractKiteModel

All kite models must inherit from this type. All methods that are defined on this type must work
with all kite models, or a specific method has to be defined for the specific kite model.
"""
abstract type AbstractKiteModel end

include("settings.jl")
include("yaml_utils.jl")
include("transformations.jl")
include("trafo.jl")

include("_sysstate.jl")
include("sysstate_views.jl")

@inline function Base.getproperty(st::SysState, sym::Symbol)
    if sym === :pos
        return PointPositions(st)
    elseif sym === :orient
        return FrameQuat(st, 1)        # frame 1 = kite (legacy single quaternion)
    elseif sym === :orients
        return OrientFrames(st)
    else
        return getfield(st, sym)
    end
end
@inline function Base.setproperty!(st::SysState, sym::Symbol, v)
    if sym === :orient
        FrameQuat(st, 1) .= v
        return v
    elseif sym === :pos || sym === :orients
        error("Set individual elements instead, e.g. `st.$sym[i] = ...`")
    else
        # Mirror Julia's default setproperty! conversion (e.g. Float64 → Float32).
        return setfield!(st, sym, convert(fieldtype(typeof(st), sym), v))
    end
end
Base.propertynames(::SysState) = (fieldnames(SysState)..., :orient, :orients, :pos)

include("_show.jl")

"""
    SysLog{P}

Flight log, containing the basic data as struct of vectors which can be accessed as if it would
be an array structs.
In addition an extended view on the data that includes derived/ calculated values for plotting.
Finally it contains meta data like the name of the log file.

$(TYPEDFIELDS)
"""
mutable struct SysLog{P, O, S <: StructArray{<:SysState{P, O}}}
    "name of the flight log"
    name::String
    colmeta::Dict{Symbol, Union{String, Vector{Pair{String, String}}}}
    "struct of vectors that can also be accessed like a vector of structs"
    syslog::S
end

# Outer constructors to infer the trailing type parameters
SysLog{P, O}(name::String, colmeta::Dict, syslog::S) where {P, O, S <: StructArray{<:SysState{P, O}}} =
    SysLog{P, O, S}(name, colmeta, syslog)
SysLog{P}(name::String, colmeta::Dict, syslog::StructArray{<:SysState{P, O}}) where {P, O} =
    SysLog{P, O}(name, colmeta, syslog)

function prepre_last(vec)
    vec[end-2]
end

"""
    Base.getproperty(log::SysLog, sym::Symbol)

Implement the properties x, y and z. They represent the kite position for the 4-point kite model.
In addition, implements the properties x1, y1 and z1. They represent the kite position for the 1-point model.
"""
function Base.getproperty(log::SysLog, sym::Symbol)
    if sym == :x
        prepre_last.(getproperty(log.syslog, :X))
    elseif sym == :x1
        last.(getproperty(log.syslog, :X))
    elseif sym == :y
        prepre_last.(getproperty(log.syslog, :Y))
    elseif sym == :y1
        last.(getproperty(log.syslog, :Y))
    elseif sym == :z
        prepre_last.(getproperty(log.syslog, :Z))
    elseif sym == :z1
        last.(getproperty(log.syslog, :Z))
    elseif sym == :orient
        getproperty(getfield(log, :syslog), :orient)
    elseif sym == :orients
        getproperty(getfield(log, :syslog), :orients)
    elseif sym == :pos
        getproperty(getfield(log, :syslog), :pos)
    else
        getfield(log, sym)
    end
end

include("logger.jl")

# functions
function __init__()
    SETTINGS.segments=0 # force loading of settings.yaml
    if isdir(joinpath(pwd(), "data")) && isfile(joinpath(pwd(), "data", "system.yaml"))
        set_data_path(joinpath(pwd(), "data"))
    end
end

"""
    demo_state(P, height=6.0, time=0.0; azimuth_north=-pi/2)

Create a demo state with a given height and time. P is the number of tether particles.
Kite is parking and aligned with the tether.

Returns a SysState instance.
"""
function demo_state(P, height=6.0, time=0.0; azimuth_north=-pi/2)
    ss = SysState{P}()
    ss.time = time
    a = 10
    turn_angle = azimuth_north+pi/2
    dist = collect(range(0, stop=10, length=P))
    ss.X .= dist .* cos(turn_angle)
    ss.Y .= dist .* sin(turn_angle)
    ss.Z .= (a .* cosh.(dist./a) .- a) * height/ 5.430806
    r_xyz = RotXYZ(pi/2, -pi/2, 0)
    q = QuatRotation(r_xyz)
    ss.orient .= MVector{4, Float32}(Rotations.params(q))
    ss.elevation = calc_elevation([ss.X[end], 0.0, ss.Z[end]])
    ss.v_wind_gnd .= [10.4855, 0, -3.08324]
    ss.v_wind_200m .= [10.4855, 0, -3.08324]
    ss.v_wind_kite .= [10.4855, 0, -3.08324]
    ss.t_sim = 0.012
    ss
end

"""
    initial_kite_ref_frame(vec_c, v_app)

Calculate the initial orientation of the kite based on the last tether segment and
the apparent wind speed.

Parameters:
- `vec_c`: (`pos_n`-2) - (`pos_n`-1) n: number of particles without the three kite particles
                                    that do not belong to the main tether (P1, P2 and P3).
- `v_app`: vector of the apparent wind speed

Returns:
x, y, z:  the unit vectors of the kite reference frame in the ENU reference frame
"""
function initial_kite_ref_frame(vec_c, v_app)
    z = normalize(vec_c)
    y = normalize(cross(v_app, vec_c))
    x = normalize(cross(y, vec_c))
    return (x, y, z)
end

"""
    get_particles(height_k, height_b, width, m_k, pos_pod= [ 75., 0., 129.90381057], vec_c=[-15., 0., -25.98076211],
                  v_app=[10.4855, 0, -3.08324])

Calculate the initial positions of the particles representing
a 4-point kite, connected to a kite control unit (KCU).

**Parameters:**
- height_k: height of the kite itself, not above ground [m]
- height_b: height of the bridle [m]
- width: width of the kite [m]
- mk: relative nose distance
- pos_pod: position of the control pod
- vec_c: vector of the last tether segment
"""
function get_particles(height_k, height_b, width, m_k, pos_pod= [ 75., 0., 129.90381057],
                       vec_c=[-15., 0., -25.98076211], v_app=[10.4855, 0, -3.08324])
    # inclination angle of the kite; beta = atan(-pos_kite[2], pos_kite[1]) ???
    beta = pi/2.0
    x, y, z = initial_kite_ref_frame(vec_c, v_app)

    h_kx = height_k * cos(beta); # print 'h_kx: ', h_kx
    h_kz = height_k * sin(beta); # print 'h_kz: ', h_kz
    h_bx = height_b * cos(beta)
    h_bz = height_b * sin(beta)
    pos_kite = pos_pod - (h_kz + h_bz) * z + (h_kx + h_bx) * x   # top,        point B in diagram
    pos_C = pos_kite + h_kz * z + 0.5 * width * y + h_kx * x     # side point, point C in diagram
    pos_A = pos_kite + h_kz * z + (h_kx + width * m_k) * x       # nose,       point A in diagram
    pos_D = pos_kite + h_kz * z - 0.5 * width * y + h_kx * x     # side point, point D in diagram
    pos0 = pos_kite + (h_kz + h_bz) * z + (h_kx + h_bx) * x      # equal to pos_pod, P_KCU in diagram
    [zeros(3), pos0, pos_A, pos_kite, pos_C, pos_D] # 0, p7, p8, p9, p10, p11
end

"""
    demo_state_4p(P, height=6.0, time=0.0; azimuth_north=-pi/2)

Create a demo state, using the 4 point kite model with a given height and time. P is the number of tether particles.

Returns a SysState instance.
"""
function demo_state_4p(P, height=6.0, time=0.014; azimuth_north=-pi/2)
    function get_particle(particle, X, Y, Z)
        x, y, z = particle[1], particle[2], particle[3]
        push!(X, x)
        push!(Y, y)
        push!(Z, z)
        return SVector(x,y,z)
    end
    ss = SysState{P+4}()
    a = 10
    turn_angle = azimuth_north+pi/2
    dist = collect(range(0, stop=10, length=P))
    X = dist .* cos(turn_angle)
    Y = dist .* sin(turn_angle)
    v_app = [10*cos(turn_angle), 10*sin(turn_angle), 0]
    Z = (a .* cosh.(dist./a) .- a) * height/ 5.430806
    # append the kite particles to X, Y and z
    pod_pos = [X[end], Y[end], Z[end]]
    vec_c = [X[end-2] - X[end-1], Y[end-2] - Y[end-1], Z[end-2] - Z[end-1]]
    particles = get_particles(se().height_k, se().h_bridle, se().width, se().m_k, pod_pos, vec_c, v_app)[3:end]
    get_particle(particles[1], X, Y, Z)
    pos_B = get_particle(particles[2], X, Y, Z)
    pos_C = get_particle(particles[3], X, Y, Z)
    pos_D = get_particle(particles[4], X, Y, Z)
    ss.X .= X
    ss.Y .= Y
    ss.Z .= Z
    pos_centre = 0.5 * (pos_C + pos_D)
    delta = pos_B - pos_centre
    let z = -normalize(delta),
        y = normalize(pos_C - pos_D)
        x = y × z
        pos_kite_ = pod_pos
        pos_before = pos_kite_ + z

        rotation = rot(pos_kite_, pos_before, -x)
        q = QuatRotation(rotation)
        ss.orient .= MVector{4, Float32}(Rotations.params(q))
    end
    ss.elevation = calc_elevation([X[end], 0.0, Z[end]])
    ss.v_wind_gnd = [10.4855, 0, -3.08324]
    ss.v_wind_200m = [10.4855, 0, -3.08324]
    ss.v_wind_kite = [10.4855, 0, -3.08324]
    ss.t_sim = time
    ss
end

include("_demo_syslog.jl")

"""
    demo_log(P, name="Test_flight"; duration=10)

Create an artificial SysLog struct for demonstration purposes. P is the number of tether
particles.
"""
function demo_log(P, name="Test_flight"; duration=10,
    colmeta = Dict(:var_01 => ["name" => "var_01"],
                   :var_02 => ["name" => "var_02"],
                   :var_03 => ["name" => "var_03"],
                   :var_04 => ["name" => "var_04"],
                   :var_05 => ["name" => "var_05"],
                   :var_06 => ["name" => "var_06"],
                   :var_07 => ["name" => "var_07"],
                   :var_08 => ["name" => "var_08"],
                   :var_09 => ["name" => "var_09"],
                   :var_10 => ["name" => "var_10"],
                   :var_11 => ["name" => "var_11"],
                   :var_12 => ["name" => "var_12"],
                   :var_13 => ["name" => "var_13"],
                   :var_14 => ["name" => "var_14"],
                   :var_15 => ["name" => "var_15"],
                   :var_16 => ["name" => "var_16"]
                   ))
    syslog = demo_syslog(P, duration=duration)
    return SysLog{P}(name, colmeta, syslog)
end

"""
    save_log(flight_log::SysLog, compress=true; path="")

Save a flight log of type SysLog as .arrow file. By default lz4 compression is used,
if you use **false** as second parameter no compression is used.
"""
function save_log(flight_log::SysLog, compress=true; path="")
    if path == ""
        path = DATA_PATH[1]
    end
    filename = joinpath(path, flight_log.name) * ".arrow"
    if compress
        Arrow.write(filename, flight_log.syslog, compress=:lz4, colmetadata = flight_log.colmeta)
    else
        Arrow.write(filename, flight_log.syslog, colmetadata = flight_log.colmeta)
    end
end

"""
    export_log(flight_log; path="")

Save a flight log of type SysLog as .csv file.
"""
function export_log(flight_log; path="")
    if path == ""
        path = DATA_PATH[1]
    end
    filename = joinpath(path, flight_log.name) * ".csv"
    CSV.write(filename, flight_log.syslog)
end

include("load_log.jl")


"""
    calculate_rotational_inertia(X::Vector, Y::Vector, Z::Vector, M::Vector,
          around_center_of_mass::Bool=true, rotation_point::Vector=[0, 0, 0])

Calculate the rotational inertia (Ixx, Ixy, Ixz, Iyy, Iyz, Izz) of a collection of point masses around a point.
By default this point is the center of mass which will be calculated, but any point can be given to rotation_point.

Parameters:
- X: x-coordinates of the point masses.
- Y: y-coordinates of the point masses.
- Z: z-coordinates of the point masses.
- M: masses of the point masses.
- `around_center_of_mass`: Calculate the rotational inertia around the center of mass?
- `rotation_point`: Rotation point used if not rotating around the center of mass.

Returns:
The tuple  Ixx, Ixy, Ixz, Iyy, Iyz, Izz where:
- Ixx: rotational inertia around the x-axis.
- Ixy: rotational inertia around the xy-plane.
- Ixz: rotational inertia around the xz-plane.
- Iyy: rotational inertia around the y-axis.
- Iyz: rotational inertia around the yz-plane.
- Izz: rotational inertia around the z-axis.

"""
function calculate_rotational_inertia(X::Vector, Y::Vector, Z::Vector, M::Vector, around_center_of_mass::Bool=true,
    rotation_point::Vector=[0, 0, 0])
    @assert size(X) == size(Y) == size(Z) == size(M)

    if around_center_of_mass
        # First loop to determine the center of mass
        x_com = y_com = z_com = m_total = 0.0
        for (x, y, z, m) in zip(X, Y, Z, M)
            x_com += x * m
            y_com += y * m
            z_com += z * m
            m_total += m
        end

        x_com = x_com / m_total
        y_com = y_com / m_total
        z_com = z_com / m_total
    else
        x_com = rotation_point[begin]
        y_com = rotation_point[begin+1]
        z_com = rotation_point[begin+2]
    end

    Ixx = Ixy = Ixz = Iyy = Iyz = Izz = 0

    # Second loop using the distance between the point and the center of mass
    for (x, y, z, m) in zip(X .- x_com, Y .- y_com, Z .- z_com, M)
        Ixx += m * (y^2 + z^2)
        Iyy += m * (x^2 + z^2)
        Izz += m * (x^2 + y^2)

        Ixy += m * x * y
        Ixz += m * x * z
        Iyz += m * y * z
    end

    Ixx, Ixy, Ixz, Iyy, Iyz, Izz
end


function test(save=false)
    if save
        log_to_save=demo_log(7)
        save_log(log_to_save)
    end
    return(load_log(7, "Test_flight.arrow"))
end

function menu()
    Main.include("examples/menu.jl")
end

"""
    copy_examples()

Copy all example scripts to the folder "examples"
(it will be created if it doesn't exist).
"""
function copy_examples()
    PATH = "examples"
    if ! isdir(PATH)
        mkdir(PATH)
    end
    src_path = joinpath(@__DIR__, "..", PATH)
    copy_files("examples", readdir(src_path))
end

function install_examples(add_packages=true)
    copy_examples()
    Base.invokelatest(() -> copy_settings(["transition.csv"]))
    if add_packages
        Pkg.add("ControlPlots")
        Pkg.add("LaTeXStrings")
        Pkg.add("StatsBase")
    end
end

@setup_workload begin
    # Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
    # precompile file and potentially make loading faster.
    # list = [OtherType("hello"), OtherType("world!")]
    set_data_path()
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        Base.invokelatest(se)
        try
            load_log(7, "Test_flight.arrow")
        catch
            test(true)
            load_log(7, "Test_flight.arrow")
        end
    end
end

end
