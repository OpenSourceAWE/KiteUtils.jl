# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

"""
    load_log(filename::String; path="")

Read a log file that was saved as .arrow file.
"""
load_log(_, filename::String) = load_log(filename) # for compatibility, the first argument was P and is ignored
function load_log(filename::String; path="", debug=false)
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
    T =  eltype(table.Z[1])
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
    zero_col(len) = [zeros(MVector{len, T}) for _ in 1:n]
    cycle = zeros(Int16, n)
    fig_8 = zeros(Int16, n)
    turn_rates = zero_col(3)
    azimuth_rate = zeros(T, n)
    kcu_steering = zeros(T, n)
    set_steering = zeros(T, n)
    heading_rate = zeros(T, n)
    bearing = zeros(T, n)
    attractor = zero_col(2)
    v_wind_gnd = zero_col(3)
    v_wind_200m = zero_col(3)
    v_wind_kite = zero_col(3)
    AoA = zeros(T, n)
    side_slip = zeros(T, n)
    alpha3 = zeros(T, n)
    alpha4 = zeros(T, n)
    CL2 = zeros(T, n)
    CD2 = zeros(T, n)
    aero_force_b = zero_col(3)
    aero_moment_b = zero_col(3)
    tether_induced_force = zero_col(3)
    tether_induced_moment = zero_col(3)
    twist_angles = zero_col(4)
    acc = zeros(T, n)
    set_torque = zero_col(4)
    set_speed = zero_col(4)
    set_force = zero_col(4)
    roll = zeros(T, n)
    pitch = zeros(T, n)
    yaw = zeros(T, n)
    winch_force = zero_col(4)

    for name in [:cycle, :fig_8, :turn_rates, :azimuth_rate, :kcu_steering,
                 :set_steering, :heading_rate, :bearing, :attractor, :v_wind_gnd,
                 :v_wind_200m, :v_wind_kite, :AoA, :side_slip, :alpha3, :alpha4, :CL2, :CD2,
                 :aero_force_b, :aero_moment_b, :tether_induced_force, :tether_induced_moment,
                 :twist_angles, :acc, :set_torque, :set_speed,
                 :set_force, :roll, :pitch, :yaw, :force, :winch_force]
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
            elseif name == :roll
                roll = table.roll
            elseif name == :pitch
                pitch = table.pitch
            elseif name == :yaw
                yaw = table.yaw
            elseif name == :force
                winch_force = table.force
            elseif name == :winch_force
                winch_force = table.winch_force
            else
                error("Unknown field: $name")
            end
 
        end
        
    end
    # Flap back-compat: new logs store flap_angle (one per aero segment); logs
    # written before the column existed have none, so default to empty (D = 0).
    D = haskey(table, :flap_angle) ? length(table.flap_angle[1]) : 0
    flap_angle = haskey(table, :flap_angle) ? table.flap_angle :
        [zeros(MVector{D, T}) for _ in 1:n]
    # Single-tether logs store l_tether, v_reelout and winch_force as scalars
    # rather than one entry per winch; widen those into slot 1.
    function widen(col, len)
        eltype(col) <: Number || return col
        return [(v = zeros(MVector{len, T}); v[1] = x; v) for x in col]
    end
    l_tether = widen(table.l_tether, 4)
    v_reelout = widen(table.v_reelout, 4)
    vel_kite = widen(table.vel_kite, 3)
    winch_force = widen(winch_force, 4)
    set_torque, set_speed = widen(set_torque, 4), widen(set_speed, 4)
    set_force, twist_angles = widen(set_force, 4), widen(twist_angles, 4)
    turn_rates, attractor = widen(turn_rates, 3), widen(attractor, 2)
    v_wind_gnd, v_wind_200m = widen(v_wind_gnd, 3), widen(v_wind_200m, 3)
    v_wind_kite = widen(v_wind_kite, 3)
    aero_force_b, aero_moment_b = widen(aero_force_b, 3), widen(aero_moment_b, 3)
    tether_induced_force = widen(tether_induced_force, 3)
    tether_induced_moment = widen(tether_induced_moment, 3)
    # Differential-state back-compat: logs written before these columns existed
    # restart from rest, so every one of them defaults to zero.
    L = haskey(table, :pulley_len) ? length(table.pulley_len[1]) : 0
    column(name, len) = haskey(table, name) ? getproperty(table, name) :
        [zeros(MVector{len, T}) for _ in 1:n]
    VX, VY, VZ = column(:VX, P), column(:VY, P), column(:VZ, P)
    twist_surface_angle = column(:twist_surface_angle, D)
    twist_surface_vel = column(:twist_surface_vel, D)
    pulley_len, pulley_vel = column(:pulley_len, L), column(:pulley_vel, L)
    # Orientation back-compat: new logs store Qw/Qx/Qy/Qz (one entry per oriented
    # frame); old logs store a single `orient` quaternion column.
    if haskey(table, :Qw)
        O = length(table.Qw[1])
        Qw, Qx, Qy, Qz = table.Qw, table.Qx, table.Qy, table.Qz
    elseif haskey(table, :orient)
        O = 1
        Qw = [MVector{1, T}(table.orient[t][1]) for t in 1:n]
        Qx = [MVector{1, T}(table.orient[t][2]) for t in 1:n]
        Qy = [MVector{1, T}(table.orient[t][3]) for t in 1:n]
        Qz = [MVector{1, T}(table.orient[t][4]) for t in 1:n]
    else
        O = 1
        Qw = [ones(MVector{1, T}) for _ in 1:n]
        Qx = [zeros(MVector{1, T}) for _ in 1:n]
        Qy = [zeros(MVector{1, T}) for _ in 1:n]
        Qz = [zeros(MVector{1, T}) for _ in 1:n]
    end
    turn_rate_x, turn_rate_y, turn_rate_z =
        column(:turn_rate_x, O), column(:turn_rate_y, O), column(:turn_rate_z, O)
    syslog = StructArray{SysState{P, O, D, L, T}}((table.time, table.t_sim, table.sys_state, cycle, fig_8,
                                       table.e_mech, Qw, Qx, Qy, Qz, turn_rates, table.elevation, table.azimuth,
                                       azimuth_rate, l_tether, v_reelout, winch_force, table.depower, table.steering,
                                       kcu_steering, set_steering, table.heading, heading_rate, table.course, 
                                       bearing, attractor, table.v_app, v_wind_gnd, v_wind_200m, 
                                       v_wind_kite, AoA, side_slip, alpha3, alpha4, 
                                       CL2, CD2, aero_force_b, aero_moment_b, tether_induced_force,
                                       tether_induced_moment, twist_angles, 
                                       vel_kite, acc, table.X, table.Y, table.Z,
                                       flap_angle, VX, VY, VZ,
                                       turn_rate_x, turn_rate_y, turn_rate_z,
                                       twist_surface_angle, twist_surface_vel,
                                       pulley_len, pulley_vel,
                                       set_torque, set_speed, set_force, roll, pitch,
                                       yaw, table.var_01, table.var_02, table.var_03, table.var_04, 
                                       table.var_05, table.var_06, table.var_07, table.var_08, table.var_09, 
                                       table.var_10, table.var_11, table.var_12, table.var_13, table.var_14, 
                                       table.var_15, table.var_16))
    return SysLog{P}(basename(fullname[1:end-6]), colmeta, syslog)
end
