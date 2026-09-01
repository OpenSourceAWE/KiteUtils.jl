# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# The first argument was P and is ignored.
load_log(_, filename::String; kwargs...) = load_log(filename; kwargs...)

"""
    load_log(filename::String; path="", frame=KS)

Read a log file that was saved as .arrow file. Orientations are returned in `KA`.

Logs written by KiteUtils 0.13 and later declare their convention. An older log
declares nothing and is `KS`: that is what the format specified, so that is how it
is read.

`frame` is an escape hatch for a log that did not honour the specification.
SymbolicAWEModels wrote `Q_b_to_w` into the field unconverted, so its logs of that
era hold `KA` already and need `load_log(name; frame=KA)`, or their orientations
come back upside down.
"""
function load_log(filename::String; path="", debug=false, frame::FrameConvention=KS)
    if path == ""
        path = DATA_PATH[1]
    end
    fullname = filename
    if ! isfile(filename)
        candidate = joinpath(path, basename(filename)) * ".arrow"
        if isfile(candidate)
            fullname = candidate
        else
            fullname = joinpath(path, basename(filename))
        end
    end
    table   = Arrow.Table(fullname)
    P =  length(table.Z[1])
    # Float type is whatever the file was written with, so Float32 logs stay Float32.
    F =  eltype(table.Z[1])
    colmeta = Dict(:var_01=>Arrow.getmetadata(table.var_01)["name"],
                   :var_02=>Arrow.getmetadata(table.var_02)["name"],
                   :var_03=>Arrow.getmetadata(table.var_03)["name"],
                   :var_04=>Arrow.getmetadata(table.var_04)["name"],
                   :var_05=>Arrow.getmetadata(table.var_05)["name"],
                   :var_06=>Arrow.getmetadata(table.var_06)["name"],
                   :var_07=>Arrow.getmetadata(table.var_07)["name"],
                   :var_08=>Arrow.getmetadata(table.var_08)["name"],
                   :var_09=>Arrow.getmetadata(table.var_09)["name"],
                   :var_10=>Arrow.getmetadata(table.var_10)["name"],
                   :var_11=>Arrow.getmetadata(table.var_11)["name"],
                   :var_12=>Arrow.getmetadata(table.var_12)["name"],
                   :var_13=>Arrow.getmetadata(table.var_13)["name"],
                   :var_14=>Arrow.getmetadata(table.var_14)["name"],
                   :var_15=>Arrow.getmetadata(table.var_15)["name"],
                   :var_16=>Arrow.getmetadata(table.var_16)["name"],
    )
    # example_metadata = KiteUtils.Arrow.getmetadata(table.var_01)
    if debug
        return table
    end
    n = length(table.time)
    zero_col(len) = [zeros(MVector{len, F}) for _ in 1:n]
    cycle = zeros(Int16, n)
    fig_8 = zeros(Int16, n)
    turn_rates = zero_col(3)
    azimuth_rate = zeros(F, n)
    kcu_steering = zeros(F, n)
    set_steering = zeros(F, n)
    heading_rate = zeros(F, n)
    bearing = zeros(F, n)
    attractor = zero_col(2)
    v_wind_gnd = zero_col(3)
    v_wind_200m = zero_col(3)
    v_wind_kite = zero_col(3)
    AoA = zeros(F, n)
    side_slip = zeros(F, n)
    alpha3 = zeros(F, n)
    alpha4 = zeros(F, n)
    CL2 = zeros(F, n)
    CD2 = zeros(F, n)
    aero_force_b = zero_col(3)
    aero_moment_b = zero_col(3)
    tether_induced_force = zero_col(3)
    tether_induced_moment = zero_col(3)
    twist_angles = zero_col(0)
    acc = zeros(F, n)
    set_torque = zero_col(0)
    set_speed = zero_col(0)
    set_force = zero_col(0)
    winch_force = zero_col(0)

    for name in [:cycle, :fig_8, :turn_rates, :azimuth_rate, :kcu_steering,
                 :set_steering, :heading_rate, :bearing, :attractor, :v_wind_gnd,
                 :v_wind_200m, :v_wind_kite, :AoA, :side_slip, :alpha3, :alpha4, :CL2, :CD2,
                 :aero_force_b, :aero_moment_b, :tether_induced_force, :tether_induced_moment,
                 :twist_angles, :acc, :set_torque, :set_speed,
                 :set_force, :force, :winch_force]
        if haskey(table, name)
            if name == :cycle
                cycle = table.cycle
            elseif name == :fig_8
                fig_8 = table.fig_8
            elseif name == :turn_rates
                turn_rates = table.turn_rates
            elseif name == :azimuth_rate
                azimuth_rate = table.azimuth_rate
            elseif name == :kcu_steering
                kcu_steering = table.kcu_steering
            elseif name == :set_steering
                set_steering = table.set_steering
            elseif name == :heading_rate
                heading_rate = table.heading_rate
            elseif name == :bearing
                bearing = table.bearing
            elseif name == :attractor
                attractor = table.attractor
            elseif name == :v_wind_gnd
                v_wind_gnd = table.v_wind_gnd
            elseif name == :v_wind_200m
                v_wind_200m = table.v_wind_200m
            elseif name == :v_wind_kite
                v_wind_kite = table.v_wind_kite
            elseif name == :AoA
                AoA = table.AoA
            elseif name == :side_slip
                side_slip = table.side_slip
            elseif name == :alpha3
                alpha3 = table.alpha3
            elseif name == :alpha4
                alpha4 = table.alpha4
            elseif name == :CL2
                CL2 = table.CL2
            elseif name == :CD2
                CD2 = table.CD2
            elseif name == :aero_force_b 
                aero_force_b = table.aero_force_b 
            elseif name == :aero_moment_b 
                aero_moment_b = table.aero_moment_b 
            elseif name == :tether_induced_force 
                tether_induced_force = table.tether_induced_force 
            elseif name == :tether_induced_moment 
                tether_induced_moment = table.tether_induced_moment 
            elseif name == :twist_angles 
                twist_angles = table.twist_angles
            elseif name == :acc
                acc = table.acc
            elseif name == :set_torque
                set_torque = table.set_torque
            elseif name == :set_speed
                set_speed = table.set_speed
            elseif name == :set_force
                set_force = table.set_force
            elseif name == :force
                winch_force = table.force
            elseif name == :winch_force
                winch_force = table.winch_force
            else
                error("Unknown field: $name")
            end
 
        end
        
    end
    # Single-winch logs store l_tether, v_reelout and winch_force as scalars
    # rather than one entry per winch, and older multi-winch logs are fixed at
    # four slots; `fit` maps either onto this file's own count.
    entries(col) = eltype(col) <: Number ? 1 : length(col[1])
    function fit(col, len)
        eltype(col) <: Number &&
            return [(v = zeros(MVector{len, F}); v[1] = x; v) for x in col]
        entries(col) == len && return col
        return [(v = zeros(MVector{len, F});
                 copyto!(v, 1, x, 1, min(len, length(x))); v) for x in col]
    end
    # Twist surfaces: flap_angle sizes them in new logs; older ones only have
    # twist_angles, which was capped at four back then.
    D = haskey(table, :flap_angle) ? entries(table.flap_angle) :
        (haskey(table, :twist_angles) ? entries(table.twist_angles) : 0)
    flap_angle = haskey(table, :flap_angle) ? table.flap_angle :
        [zeros(MVector{D, F}) for _ in 1:n]
    twist_angles = fit(twist_angles, D)
    # Only columns the file actually has may size W; the zero fallbacks above are
    # fixed-width placeholders and would otherwise force every log to four.
    W = maximum((entries(getproperty(table, name))
        for name in (:v_reelout, :winch_force, :force,
                     :set_torque, :set_speed, :set_force)
        if haskey(table, name)); init=1)
    T = entries(table.l_tether)
    l_tether, v_reelout = fit(table.l_tether, T), fit(table.v_reelout, W)
    winch_force = fit(winch_force, W)
    set_torque, set_speed = fit(set_torque, W), fit(set_speed, W)
    set_force = fit(set_force, W)
    vel_kite = fit(table.vel_kite, 3)
    turn_rates, attractor = fit(turn_rates, 3), fit(attractor, 2)
    v_wind_gnd, v_wind_200m = fit(v_wind_gnd, 3), fit(v_wind_200m, 3)
    v_wind_kite = fit(v_wind_kite, 3)
    aero_force_b, aero_moment_b = fit(aero_force_b, 3), fit(aero_moment_b, 3)
    tether_induced_force = fit(tether_induced_force, 3)
    tether_induced_moment = fit(tether_induced_moment, 3)
    # Differential-state back-compat: logs written before these columns existed
    # restart from rest, so every one of them defaults to zero.
    L = haskey(table, :pulley_len) ? length(table.pulley_len[1]) : 0
    column(name, len) = haskey(table, name) ? getproperty(table, name) :
        [zeros(MVector{len, F}) for _ in 1:n]
    VX, VY, VZ = column(:VX, P), column(:VY, P), column(:VZ, P)
    twist_vel = column(:twist_vel, D)
    pulley_len, pulley_vel = column(:pulley_len, L), column(:pulley_vel, L)
    # Orientation back-compat: new logs store Qw/Qx/Qy/Qz (one entry per oriented
    # frame); old logs store a single `orient` quaternion column.
    if haskey(table, :Qw)
        O = length(table.Qw[1])
        Qw, Qx, Qy, Qz = table.Qw, table.Qx, table.Qy, table.Qz
    elseif haskey(table, :orient)
        O = 1
        Qw = [MVector{1, F}(table.orient[t][1]) for t in 1:n]
        Qx = [MVector{1, F}(table.orient[t][2]) for t in 1:n]
        Qy = [MVector{1, F}(table.orient[t][3]) for t in 1:n]
        Qz = [MVector{1, F}(table.orient[t][4]) for t in 1:n]
    else
        O = 1
        Qw = [ones(MVector{1, F}) for _ in 1:n]
        Qx = [zeros(MVector{1, F}) for _ in 1:n]
        Qy = [zeros(MVector{1, F}) for _ in 1:n]
        Qz = [zeros(MVector{1, F}) for _ in 1:n]
    end
    declared = log_convention(table)
    convention = isnothing(declared) ? frame : declared
    if isnothing(declared)
        @warn "Log $(basename(fullname)) declares no frame convention, so it predates " *
              "KiteUtils 0.13 and is specified to be KS. Reading its orientations as " *
              "$convention. A log SymbolicAWEModels wrote in that era holds KA in " *
              "breach of that, and needs load_log(...; frame=KA)."
    end
    if convention !== KA
        Qw = [MVector{O, F}(q) for q in Qw]
        Qx = [MVector{O, F}(q) for q in Qx]
        Qy = [MVector{O, F}(q) for q in Qy]
        Qz = [MVector{O, F}(q) for q in Qz]
        fromKS2KA_columns!(Qw, Qx, Qy, Qz)
    end
    turn_rate_x, turn_rate_y, turn_rate_z =
        column(:turn_rate_x, O), column(:turn_rate_y, O), column(:turn_rate_z, O)
    S = haskey(table, :spring_force) ? length(table.spring_force[1]) : 0
    aero_force_x, aero_force_y, aero_force_z =
        column(:aero_force_x, P), column(:aero_force_y, P), column(:aero_force_z, P)
    drag_force_x, drag_force_y, drag_force_z =
        column(:drag_force_x, P), column(:drag_force_y, P), column(:drag_force_z, P)
    spring_force = column(:spring_force, S)
    syslog = StructArray{SysState{P, O, D, L, W, T, S, F}}((table.time, table.t_sim, table.sys_state, cycle, fig_8,
                                       table.e_mech, Qw, Qx, Qy, Qz, turn_rates, table.elevation, table.azimuth,
                                       azimuth_rate, l_tether, v_reelout, winch_force, table.depower, table.steering,
                                       kcu_steering, set_steering, table.heading, heading_rate, table.course, 
                                       bearing, attractor, table.v_app, v_wind_gnd, v_wind_200m, 
                                       v_wind_kite, AoA, side_slip, alpha3, alpha4, 
                                       CL2, CD2, aero_force_b, aero_moment_b, tether_induced_force,
                                       tether_induced_moment, twist_angles, 
                                       vel_kite, acc, table.X, table.Y, table.Z,
                                       flap_angle, VX, VY, VZ,
                                       aero_force_x, aero_force_y, aero_force_z,
                                       drag_force_x, drag_force_y, drag_force_z,
                                       spring_force,
                                       turn_rate_x, turn_rate_y, turn_rate_z,
                                       twist_vel, pulley_len, pulley_vel,
                                       set_torque, set_speed, set_force,
                                       table.var_01, table.var_02, table.var_03, table.var_04, 
                                       table.var_05, table.var_06, table.var_07, table.var_08, table.var_09, 
                                       table.var_10, table.var_11, table.var_12, table.var_13, table.var_14, 
                                       table.var_15, table.var_16))
    return SysLog{P}(basename(fullname[1:end-6]), colmeta, syslog)
end
