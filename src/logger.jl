# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

include("_logger.jl")

"""
    Logger(P, steps; orients=1, deflections=0, pulleys=0, winches=1,
           tethers=winches, segments=0, precision=MyFloat)

Pre-allocate a log of `P` points for `steps` time steps. The remaining counts
are keywords so that adding a dimension does not add another positional method:
`orients` oriented frames, `deflections` twist surfaces, `pulleys` pulleys,
`winches` winches, `tethers` tethers and `segments` segments. `tethers` defaults
to `winches`, which is right whenever each winch drives one tether. Pass
`precision=Float64` to log a differential state that round-trips `integrator.u`
exactly.
"""
function Logger(P, steps; orients=1, deflections=0, pulleys=0, winches=1,
                tethers=winches, segments=0, precision=MyFloat)
    Logger{P, orients, deflections, pulleys, winches, tethers, segments,
           precision, steps}()
end

include("_log.jl")

function length(logger::Logger)
    logger.index - 1
end

include("_syslog.jl")

"""
    sys_log(logger::Logger, name="sim_log"; colmeta=default_colmeta())

Convert the data of a `Logger` into a `SysLog`, holding the rows that were
logged, the name of the log and the column meta data.
"""
function sys_log(logger::Logger, name="sim_log"; colmeta=default_colmeta())
    SysLog{logger.points}(name, colmeta, syslog(logger))
end

"""
    save_log(logger::Logger, name="sim_log", compress=true; path="",
             colmeta=default_colmeta())

Save the rows that were logged as .arrow file. By default lz4 compression is
used, if you use **false** as second parameter no compression is used.
"""
function save_log(logger::Logger, name="sim_log", compress=true; path="",
                  colmeta=default_colmeta())
    save_log(sys_log(logger, name; colmeta), compress; path)
end

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
        ss = SysState(P)
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
    colmeta = default_colmeta()
    SysLog{P}(filename, colmeta, syslog(logger))
end
