# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

include("_logger.jl")

"""
    Logger(P, steps; precision=MyFloat)
    Logger(P, O, steps; precision=MyFloat)
    Logger(P, O, D, steps; precision=MyFloat)
    Logger(P, O, D, L, steps; precision=MyFloat)

Pre-allocate a log for `steps` time steps. Omitted counts default to one
oriented frame and no aero segments or pulleys. Pass `precision=Float64` to log
a differential state that round-trips exactly.
"""
function Logger(P, steps; precision=MyFloat)
    Logger{P, 1, 0, 0, precision, steps}()
end
function Logger(P, O, steps; precision=MyFloat)
    Logger{P, O, 0, 0, precision, steps}()
end
function Logger(P, O, D, steps; precision=MyFloat)
    Logger{P, O, D, 0, precision, steps}()
end
function Logger(P, O, D, L, steps; precision=MyFloat)
    Logger{P, O, D, L, precision, steps}()
end

include("_log.jl")

function length(logger::Logger)
    logger.index - 1
end

include("_syslog.jl")

"""
    sys_log(logger::Logger, name="sim_log";
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

Converts the data of a Logger object into a SysLog object, containing a StructArray, a name
and the column meta data.
"""
function sys_log(logger::Logger, name="sim_log"; 
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
    SysLog{logger.points}(name, colmeta, syslog(logger))
end

include("_save_log.jl")

function parse_vector(str)
    m = match(r"\[(.*)\]", str)
    strs = split(m[1], ','; keepempty=false)
    Parsers.parse.(Float32, strs)
end

function import_log_(filename::String; path="")
    if path == ""
        path = DATA_PATH[1]
    end
    filename = joinpath(path, filename) * ".csv"
    return (CSV.File(filename))
end

"""
    import_log(filename)

Read a .csv file with a flight log and return a SysLog object.
The columns `var_01` to `var_05` must exists, the rest are optional.

Parameters:
- filename: name of the file without extension.
"""
function import_log(filename)
    lg = import_log_(filename)
    X = parse_vector(lg[1].X)
    P = length(X)
    logger = Logger(P, length(lg))

    for row in lg
        local X
        X = parse_vector(row.X)
        Y = parse_vector(row.Y)
        Z = parse_vector(row.Z)

        orient = parse_vector(row.orient)
        vel_kite = parse_vector(row.vel_kite)
        ss = SysState{P}()
        ss.time = row.time
        ss.t_sim = row.t_sim
        ss.sys_state = row.sys_state
        ss.e_mech = row.e_mech
        ss.orient = orient
        ss.elevation = row.elevation
        ss.azimuth = row.azimuth
        if haskey(row, :azimuth_rate)
            ss.azimuth_rate = row.azimuth_rate
        end
        ss.l_tether[1] = row.l_tether
        ss.v_reelout[1] = row.v_reelout
        if haskey(row, :winch_force)
            ss.winch_force[1] = row.winch_force
        else
            ss.winch_force[1] = row.force
        end
        ss.depower = row.depower
        ss.steering = row.steering
        ss.heading = row.heading
        ss.course = row.course
        ss.v_app = row.v_app
        ss.vel_kite = vel_kite
        ss.X = X
        ss.Y = Y
        ss.Z = Z
        ss.var_01 = row.var_01
        ss.var_02 = row.var_02
        ss.var_03 = row.var_03
        ss.var_04 = row.var_04
        ss.var_05 = row.var_05
        log!(logger, ss)
    end
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
    )
    SysLog{P}(filename, colmeta, syslog(logger))
end
