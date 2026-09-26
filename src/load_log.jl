# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# The first argument was P and is ignored.
load_log(_, filename::String; kwargs...) = load_log(filename; kwargs...)

"""
    load_log(filename::String; path="", frame=nothing)

Read a log file that was saved as .arrow file. Everything the returned `SysLog` holds
is `KA`: the orientations and every body-resolved column alike, and the table metadata
the file carries comes back as its `metadata` field.

Logs written by KiteUtils 0.13 and later declare their convention and are read by it.
An older log declares nothing and is `KS`, that being what the format specified, so
that is how it is read, with a warning saying so.

`frame` states what an undeclared log actually holds and silences that warning. It is
the escape hatch for a log that did not honour the specification: SymbolicAWEModels
wrote `Q_b_to_w` into the field unconverted, so its logs of that era hold `KA` already
and need `load_log(name; frame=KA)`, or their orientations come back upside down.
Passing `frame=KS` confirms the specified convention for a log known to honour it. A
log that declares a convention is taken at its word and `frame` is not consulted.
"""
function load_log(filename::String; path="", debug=false,
                  frame::Union{Nothing, FrameConvention}=nothing)
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
    # Read the bytes up front rather than letting Arrow mmap the file: a lingering
    # mmap keeps the file locked on Windows, so a save_log to the same path right
    # after a load_log fails there (POSIX allows it, masking the bug on Linux/macOS).
    table   = Arrow.Table(read(fullname))
    if debug
        return table
    end
    colmeta = Dict{Symbol, Vector{Pair{String, String}}}()
    for var in keys(default_colmeta())
        colmeta[var] = ["name" => Arrow.getmetadata(getproperty(table, var))["name"]]
    end
    declared = log_convention(table)
    if isnothing(declared) && isnothing(frame)
        @warn "Log $(basename(fullname)) declares no frame convention, so it predates " *
              "KiteUtils 0.13 and is specified to be KS. Reading it as KS. A log " *
              "SymbolicAWEModels wrote in that era holds KA in breach of that and " *
              "needs load_log(...; frame=KA); load_log(...; frame=KS) confirms the " *
              "specified convention. Either silences this."
    end
    metadata = Dict{String, String}(something(Arrow.getmetadata(table),
                                              Pair{String, String}[]))
    syslog_from_table(table, basename(fullname[1:end-6]), colmeta,
                      something(declared, frame, KS); metadata)
end

# The reader both log formats share: an `Arrow.Table` and a `CsvTable` are addressed
# alike, so back-compat and the conversion out of `convention` happen in one place.
function syslog_from_table(table, log_name, colmeta, convention::FrameConvention;
                           metadata = Dict{String, String}())
    P =  length(table.Z[1])
    # Float type is whatever the file was written with, so Float32 logs stay Float32.
    F =  eltype(table.Z[1])
    n = length(table.time)
    # A column the table does not have is zero-filled: a log written before that
    # column existed restarts from rest rather than from whatever was in memory.
    zero_col(len) = [zeros(MVector{len, F}) for _ in 1:n]
    column(name, len) = haskey(table, name) ? getproperty(table, name) : zero_col(len)
    scalar(name) = haskey(table, name) ? getproperty(table, name) : zeros(F, n)
    counter(name) = haskey(table, name) ? getproperty(table, name) : zeros(Int16, n)

    cycle, fig_8 = counter(:cycle), counter(:fig_8)
    turn_rates, attractor = column(:turn_rates, 3), column(:attractor, 2)
    v_wind_gnd, v_wind_200m = column(:v_wind_gnd, 3), column(:v_wind_200m, 3)
    v_wind_kite, twist_angles = column(:v_wind_kite, 3), column(:twist_angles, 0)
    set_torque, set_speed = column(:set_torque, 0), column(:set_speed, 0)
    set_force = column(:set_force, 0)
    # Before the winch count, the force at the winch was logged as `force`.
    winch_force = haskey(table, :winch_force) ? table.winch_force : column(:force, 0)
    azimuth_rate, kcu_steering = scalar(:azimuth_rate), scalar(:kcu_steering)
    set_steering, heading_rate = scalar(:set_steering), scalar(:heading_rate)
    bearing, acc = scalar(:bearing), scalar(:acc)
    AoA, side_slip = scalar(:AoA), scalar(:side_slip)
    alpha3, alpha4 = scalar(:alpha3), scalar(:alpha4)
    CL2, CD2 = scalar(:CL2), scalar(:CD2)
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
    # A log predating the per-wing split holds one 3-vector per load, and it was the
    # kite's, so it is one wing and its components read back as wing 1. `aero_force_b`
    # was that column's name before the frame reached it.
    K = haskey(table, :aero_force_KA_x) ? entries(table.aero_force_KA_x) : 1
    K <= O || throw(ArgumentError(
        "log $log_name holds the loads of $K wings but only $O oriented frames"))
    function wing_load(name, legacy)
        three_vector = haskey(table, name) ? name : legacy
        map(1:3) do component
            per_wing = Symbol(name, :_, "xyz"[component])
            haskey(table, per_wing) && return getproperty(table, per_wing)
            haskey(table, three_vector) || return zero_col(K)
            return [(v = zeros(MVector{K, F}); v[1] = load[component]; v)
                    for load in getproperty(table, three_vector)]
        end
    end
    aero_force_KA_x, aero_force_KA_y, aero_force_KA_z =
        wing_load(:aero_force_KA, :aero_force_b)
    aero_moment_KA_x, aero_moment_KA_y, aero_moment_KA_z =
        wing_load(:aero_moment_KA, :aero_moment_b)
    turn_rate_x, turn_rate_y, turn_rate_z =
        column(:turn_rate_x, O), column(:turn_rate_y, O), column(:turn_rate_z, O)
    if convention !== KA
        # Loading is the boundary, so everything body-resolved is converted here and
        # the state that comes out holds KA alone. Missing one leaves a mixed-frame
        # SysState, which nothing downstream can tell apart from a correct one.
        writable(len, columns...) = map(col -> [MVector{len, F}(v) for v in col], columns)
        Qw, Qx, Qy, Qz = writable(O, Qw, Qx, Qy, Qz)
        fromKS2KA_columns!(Qw, Qx, Qy, Qz)
        turn_rates = [MVector{3, F}(fromKS2KA_body(v)) for v in turn_rates]
        turn_rate_x, turn_rate_y, turn_rate_z =
            writable(O, turn_rate_x, turn_rate_y, turn_rate_z)
        aero_force_KA_x, aero_force_KA_y, aero_force_KA_z =
            writable(K, aero_force_KA_x, aero_force_KA_y, aero_force_KA_z)
        aero_moment_KA_x, aero_moment_KA_y, aero_moment_KA_z =
            writable(K, aero_moment_KA_x, aero_moment_KA_y, aero_moment_KA_z)
        fromKS2KA_body_columns!(turn_rate_x, turn_rate_y, turn_rate_z)
        fromKS2KA_body_columns!(aero_force_KA_x, aero_force_KA_y, aero_force_KA_z)
        fromKS2KA_body_columns!(aero_moment_KA_x, aero_moment_KA_y, aero_moment_KA_z)
    end
    S = haskey(table, :spring_force) ? entries(table.spring_force) : 0
    N = haskey(table, :gamma_distribution) ? entries(table.gamma_distribution) : 0
    aero_force_x, aero_force_y, aero_force_z =
        column(:aero_force_x, P), column(:aero_force_y, P), column(:aero_force_z, P)
    drag_force_x, drag_force_y, drag_force_z =
        column(:drag_force_x, P), column(:drag_force_y, P), column(:drag_force_z, P)
    set_ext_force_x, set_ext_force_y, set_ext_force_z =
        column(:set_ext_force_x, P), column(:set_ext_force_y, P),
        column(:set_ext_force_z, P)
    spring_force, gamma_distribution =
        column(:spring_force, S), column(:gamma_distribution, N)
    syslog = StructArray{SysState{P, O, K, D, L, W, T, S, N, F}}((
        table.time, table.t_sim, table.sys_state, cycle, fig_8, table.e_mech, Qw, Qx, Qy,
        Qz, turn_rates, table.elevation, table.azimuth, azimuth_rate, l_tether, v_reelout,
        winch_force, table.depower, table.steering, kcu_steering, set_steering,
        table.heading, heading_rate, table.course, bearing, attractor, table.v_app,
        v_wind_gnd, v_wind_200m, v_wind_kite, AoA, side_slip, alpha3, alpha4, CL2, CD2,
        aero_force_KA_x, aero_force_KA_y, aero_force_KA_z, aero_moment_KA_x,
        aero_moment_KA_y, aero_moment_KA_z, twist_angles, vel_kite, acc, table.X, table.Y,
        table.Z, flap_angle, VX, VY, VZ, aero_force_x, aero_force_y, aero_force_z,
        drag_force_x, drag_force_y, drag_force_z, spring_force, gamma_distribution,
        turn_rate_x, turn_rate_y, turn_rate_z, twist_vel, pulley_len, pulley_vel,
        set_torque, set_speed, set_force, set_ext_force_x, set_ext_force_y,
        set_ext_force_z, scalar(:var_01), scalar(:var_02), scalar(:var_03), scalar(:var_04),
        scalar(:var_05), scalar(:var_06), scalar(:var_07), scalar(:var_08), scalar(:var_09),
        scalar(:var_10), scalar(:var_11), scalar(:var_12), scalar(:var_13), scalar(:var_14),
        scalar(:var_15), scalar(:var_16)))
    return SysLog{P}(log_name, colmeta, syslog, metadata)
end
