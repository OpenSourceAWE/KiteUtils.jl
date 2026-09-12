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
    # A log written before a column existed reads back as zeros rather than throwing.
    column(name, len) = haskey(table, name) ? getproperty(table, name) : zero_col(len)
    scalar(name, T=F) = haskey(table, name) ? getproperty(table, name) : zeros(T, n)

    cycle, fig_8 = scalar(:cycle, Int16), scalar(:fig_8, Int16)
    azimuth_rate, heading_rate = scalar(:azimuth_rate), scalar(:heading_rate)
    kcu_steering, set_steering = scalar(:kcu_steering), scalar(:set_steering)
    bearing, acc = scalar(:bearing), scalar(:acc)
    AoA, side_slip = scalar(:AoA), scalar(:side_slip)
    alpha3, alpha4 = scalar(:alpha3), scalar(:alpha4)
    CL2, CD2 = scalar(:CL2), scalar(:CD2)
    turn_rates, attractor = column(:turn_rates, 3), column(:attractor, 2)
    v_wind_gnd, v_wind_200m = column(:v_wind_gnd, 3), column(:v_wind_200m, 3)
    v_wind_kite, twist_angles = column(:v_wind_kite, 3), column(:twist_angles, 0)
    set_torque, set_speed = column(:set_torque, 0), column(:set_speed, 0)
    set_force = column(:set_force, 0)
    # `force` was this column's name before `winch_force`.
    winch_force = haskey(table, :winch_force) ? table.winch_force : column(:force, 0)

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
    flap_angle = column(:flap_angle, D)
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
    L = haskey(table, :pulley_len) ? entries(table.pulley_len) : 0
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
    # A log predating the per-body split holds one 3-vector per body load, and it
    # was the kite's, so its components read back as frame 1.
    function body_load(base, legacy)
        map(1:3) do component
            name = Symbol(base, :_b_, "xyz"[component])
            haskey(table, name) && return getproperty(table, name)
            haskey(table, legacy) || return zero_col(O)
            return [(v = zeros(MVector{O, F}); v[1] = load[component]; v)
                    for load in getproperty(table, legacy)]
        end
    end
    aero_force_b_x, aero_force_b_y, aero_force_b_z =
        body_load(:aero_force, :aero_force_b)
    aero_moment_b_x, aero_moment_b_y, aero_moment_b_z =
        body_load(:aero_moment, :aero_moment_b)
    tether_induced_force_b_x, tether_induced_force_b_y, tether_induced_force_b_z =
        body_load(:tether_induced_force, :tether_induced_force)
    tether_induced_moment_b_x, tether_induced_moment_b_y, tether_induced_moment_b_z =
        body_load(:tether_induced_moment, :tether_induced_moment)
    S = haskey(table, :spring_force) ? entries(table.spring_force) : 0
    N = haskey(table, :gamma_distribution) ? entries(table.gamma_distribution) : 0
    aero_force_x, aero_force_y, aero_force_z =
        column(:aero_force_x, P), column(:aero_force_y, P), column(:aero_force_z, P)
    drag_force_x, drag_force_y, drag_force_z =
        column(:drag_force_x, P), column(:drag_force_y, P), column(:drag_force_z, P)
    set_ext_force_enu_x, set_ext_force_enu_y, set_ext_force_enu_z =
        column(:set_ext_force_enu_x, P), column(:set_ext_force_enu_y, P),
        column(:set_ext_force_enu_z, P)
    spring_force, gamma_distribution =
        column(:spring_force, S), column(:gamma_distribution, N)
    syslog = StructArray{SysState{P, O, D, L, W, T, S, N, F}}((
        table.time, table.t_sim, table.sys_state, cycle, fig_8, table.e_mech, Qw, Qx, Qy,
        Qz, turn_rates, table.elevation, table.azimuth, azimuth_rate, l_tether, v_reelout,
        winch_force, table.depower, table.steering, kcu_steering, set_steering,
        table.heading, heading_rate, table.course, bearing, attractor, table.v_app,
        v_wind_gnd, v_wind_200m, v_wind_kite, AoA, side_slip, alpha3, alpha4, CL2, CD2,
        aero_force_b_x, aero_force_b_y, aero_force_b_z, aero_moment_b_x, aero_moment_b_y,
        aero_moment_b_z, tether_induced_force_b_x, tether_induced_force_b_y,
        tether_induced_force_b_z, tether_induced_moment_b_x, tether_induced_moment_b_y,
        tether_induced_moment_b_z, twist_angles, vel_kite, acc, table.X, table.Y, table.Z,
        flap_angle, VX, VY, VZ, aero_force_x, aero_force_y, aero_force_z, drag_force_x,
        drag_force_y, drag_force_z, spring_force, gamma_distribution, turn_rate_x,
        turn_rate_y, turn_rate_z, twist_vel, pulley_len, pulley_vel, set_torque, set_speed,
        set_force, set_ext_force_enu_x, set_ext_force_enu_y, set_ext_force_enu_z,
        table.var_01, table.var_02, table.var_03, table.var_04, table.var_05, table.var_06,
        table.var_07, table.var_08, table.var_09, table.var_10, table.var_11, table.var_12,
        table.var_13, table.var_14, table.var_15, table.var_16))
    return SysLog{P}(basename(fullname[1:end-6]), colmeta, syslog)
end
