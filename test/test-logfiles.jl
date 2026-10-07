# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test, StructArrays

@testset "KiteUtils.jl: Log files      " begin
    state = KiteUtils.demo_state(7)
    @test typeof(state) == SysState{7, 1, 1, 0, 0, 1, 1, 0, 0, Float32}
    @test state.X[end] == 10.0
    @test all(state.pos[end] .≈ [10, 0, 6.0])
    @test repr(state) == "time [s]:          0.0\nt_sim [s]:         0.012\nsys_state [-]:     0\ncycle [-]:         0\nfig_8 [-]:         0\ne_mech [Wh]:       0.0\norient [-]:        Float32[0.70710677, -0.70710677, 0.0, 0.0]\nturn_rates [rad/s]:Float32[0.0, 0.0, 0.0]\nelevation [rad]:   0.5404195\nazimuth [rad]:     0.0\nazimuth_rate [rad/s]:0.0\nl_tether [m]:      Float32[0.0]\nv_reelout [m/s]:   Float32[0.0]\nwinch_force [N]:   Float32[0.0]\ndepower [0..1]:    0.0\nsteering [-1..1]:  0.0\nkcu_steering [-1..1]:0.0\nset_steering [-1..1]:0.0\nheading [rad]:     0.0\nheading_rate [rad/s]:0.0\ncourse [rad]:      0.0\nbearing [rad]:     0.0\nattractor [rad]:   Float32[0.0, 0.0]\nv_app [m/s]:       0.0\nv_wind_gnd [m/s]:  Float32[10.4855, 0.0, -3.08324]\nv_wind_200m [m/s]: Float32[10.4855, 0.0, -3.08324]\nv_wind_kite [m/s]: Float32[10.4855, 0.0, -3.08324]\nAoA [rad]:         0.0\nside_slip [rad]:   0.0\nalpha3 [rad]:      0.0\nalpha4 [rad]:      0.0\nCL2 [-]:           0.0\nCD2 [-]:           0.0\naero_force_KA_x [N]:Float32[0.0]\naero_force_KA_y [N]:Float32[0.0]\naero_force_KA_z [N]:Float32[0.0]\naero_moment_KA_x [Nm]:Float32[0.0]\naero_moment_KA_y [Nm]:Float32[0.0]\naero_moment_KA_z [Nm]:Float32[0.0]\ntwist_angles [rad]:Float32[]\nvel_kite [m/s]:    Float32[0.0, 0.0, 0.0]\nacc [m/s²]:        0.0\nX [m]:             Float32[0.0, 1.6666666, 3.3333333, 5.0, 6.6666665, 8.333333, 10.0]\nY [m]:             Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nZ [m]:             Float32[0.0, 0.15380114, 0.6194867, 1.4100224, 2.5474184, 4.063342, 6.0000005]\nflap_angle [rad]:  Float32[]\nVX [m/s]:          Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nVY [m/s]:          Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nVZ [m/s]:          Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\naero_force_x [N]:  Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\naero_force_y [N]:  Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\naero_force_z [N]:  Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\ndrag_force_x [N]:  Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\ndrag_force_y [N]:  Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\ndrag_force_z [N]:  Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nspring_force [N]:  Float32[]\ngamma_distribution [m²/s]:Float32[]\nturn_rate_x [rad/s]:Float32[0.0]\nturn_rate_y [rad/s]:Float32[0.0]\nturn_rate_z [rad/s]:Float32[0.0]\ntwist_vel [rad/s]: Float32[]\npulley_len [m]:    Float32[]\npulley_vel [m/s]:  Float32[]\nset_torque [Nm]:   Float32[0.0]\nset_speed [m/s]:   Float32[0.0]\nset_force [N]:     Float32[0.0]\nset_ext_force_x [N]:Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nset_ext_force_y [N]:Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nset_ext_force_z [N]:Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nvar_01 [-]:        0.0\nvar_02 [-]:        0.0\nvar_03 [-]:        0.0\nvar_04 [-]:        0.0\nvar_05 [-]:        0.0\nvar_06 [-]:        0.0\nvar_07 [-]:        0.0\nvar_08 [-]:        0.0\nvar_09 [-]:        0.0\nvar_10 [-]:        0.0\nvar_11 [-]:        0.0\nvar_12 [-]:        0.0\nvar_13 [-]:        0.0\nvar_14 [-]:        0.0\nvar_15 [-]:        0.0\nvar_16 [-]:        0.0\n"
    state = KiteUtils.demo_state_4p(7)
    @test typeof(state) == SysState{11, 1, 1, 0, 0, 1, 1, 0, 0, Float32}
    @test state.X[end] ≈ 13.62487f0
    @test state.Y[end] ≈ -2.885
    @test state.Y[end-1] ≈ 2.885
    @test demo_state_4p(7).t_sim == 0.014
    set_data_path(joinpath(@__DIR__, "..", "data"))
    filename="transition"
    # An archived .csv, exported long before the convention was recorded.
    log = import_log(filename; frame=KS)
    @test log isa SysLog{11}
    @test log.name == "transition"
    @test length(log.syslog) == 8180
    set_data_path(tempdir())
    log = KiteUtils.test(true)
    @test log isa SysLog{7}
    @test log.syslog.Z[end][7] ≈ 6 # height of the last particle which represents the kite (1p model)
    @test log.z1[end] ≈ 6.0
    @test log.y1[end] ≈ 0.0
    @test log.x1[end] ≈ 10.0
    @test log.x[end] ≈  6.6666665
    @test log.y[end] ≈  0.0
    @test log.z[end] ≈  2.5474184 # height of the prepre-last particle which represents the kite (4p model)
    @test export_log(log) == joinpath(tempdir(), "Test_flight.csv")
    # test that load_log works with a dot in the filename (e.g. log_1.11.arrow)
    dotted_name = "transition.1.11"
    src = joinpath("data", "transition.arrow")
    dst = joinpath(tempdir(), dotted_name * ".arrow")
    cp(src, dst; force=true)
    set_data_path(tempdir())
    # The logs in data/ predate the frame declaration and hold KS, so every load
    # of one says so; without that they warn, and the suite drowns in it.
    log2 = load_log(dotted_name; frame=KS)           # without extension
    @test log2 isa SysLog
    @test length(log2.syslog) == 8180
    log3 = load_log(dotted_name * ".arrow"; frame=KS) # with extension
    @test log3 isa SysLog
    @test length(log3.syslog) == 8180
    # verify azimuth_rate round-trips through save_log / load_log
    set_data_path(tempdir())
    logger = Logger(7, 3)
    for i in 1:3
        ss = KiteUtils.demo_state(7)
        ss.azimuth_rate = Float32(i) * 0.1f0
        log!(logger, ss)
    end
    save_log(logger, "azimuth_rate_test")
    rt = load_log("azimuth_rate_test")
    @test rt isa SysLog
    @test rt.syslog.azimuth_rate ≈ Float32[0.1, 0.2, 0.3]
    # verify import_log gracefully skips azimuth_rate when column is absent (old CSV format)
    set_data_path("data")
    log_csv = import_log("transition"; frame=KS)
    @test log_csv isa SysLog
    @test all(log_csv.syslog.azimuth_rate .== 0.0f0)  # absent column → default 0
end

@testset "KiteUtils.jl: flap_angle      " begin
    # Back-compat: an .arrow written before the flap_angle column existed must
    # still load, with flap_angle zeroed at the file's own twist-surface count.
    set_data_path(joinpath(@__DIR__, "..", "data"))
    old = load_log("Test_flight"; frame=KS)
    @test old isa SysLog
    @test length(old.syslog[1].flap_angle) ==
          length(old.syslog[1].twist_angles)
    @test all(v -> all(iszero, v), old.syslog.flap_angle)
    # Roundtrip: flap_angle values survive save_log / load_log (D > 0).
    set_data_path(tempdir())
    D = 3
    logger = Logger(7, 2; deflections=D)
    for i in 1:2
        ss = SysState(7; deflections = D)
        ss.flap_angle .= Float32[0.1i, 0.2i, 0.3i]
        log!(logger, ss)
    end
    save_log(logger, "flap_angle_test")
    rt = load_log("flap_angle_test")
    @test rt isa SysLog
    @test length(rt.syslog[1].flap_angle) == D
    @test rt.syslog[1].flap_angle ≈ Float32[0.1, 0.2, 0.3]
    @test rt.syslog[2].flap_angle ≈ Float32[0.2, 0.4, 0.6]
end

@testset "KiteUtils.jl: legacy log columns" begin
    # Two regressions that no test covered, both only reachable by materialising
    # a row — `load_log` alone returned a SysLog that looked fine.
    set_data_path(joinpath(@__DIR__, "..", "data"))
    for name in ("Test_flight", "transition", "sim_log", "failure_low_right")
        log = load_log(name; frame=KS)
        # Single-winch logs store l_tether/v_reelout/winch_force as scalars
        # rather than one entry per winch. Materialising threw before they were
        # fitted onto the file's own winch count.
        row = log.syslog[1]
        @test length(row.l_tether) >= 1
        @test length(row.v_reelout) == length(row.l_tether)
        @test length(row.winch_force) == length(row.l_tether)
        @test length(row.set_torque) == length(row.l_tether)
        # Columns the file does not have were allocated with `undef` and never
        # written, so they used to materialise as whatever was in memory.
        @test all(isfinite, row.turn_rates)
        @test all(isfinite, row.attractor)
        @test all(isfinite, row.set_torque)
        @test isfinite(row.heading_rate)
        # Every archived log predates these columns.
        @test length(row.pulley_len) == length(row.gamma_distribution) == 0
        for field in (:set_ext_force_x, :set_ext_force_y, :set_ext_force_z)
            @test length(getproperty(row, field)) == length(row.X)
            @test all(iszero, getproperty(row, field))
        end
    end
    # A log with no twist_angles column defaults it to zero rather than garbage.
    old = load_log("sim_log"; frame=KS)
    @test all(iszero, old.syslog[1].twist_angles)
end

@testset "KiteUtils.jl: differential state" begin
    # Every archived log predates the differential-state columns, so loading them
    # exercises the back-compat path: absent columns default to zero, and the
    # float type stays whatever the file was written with.
    set_data_path(joinpath(@__DIR__, "..", "data"))
    for name in ("Test_flight", "transition", "sim_log", "failure_low_right")
        old = load_log(name; frame=KS)
        @test old isa SysLog
        @test eltype(old.syslog[1].X) == Float32
        @test all(iszero, old.syslog[1].VX)
        @test all(iszero, old.syslog[1].VZ)
        @test all(iszero, old.syslog[1].turn_rate_y)
        @test length(old.syslog[1].pulley_len) == 0
        @test length(old.syslog[1].pulley_vel) == 0
    end

    # A Float64 log round-trips the differential state exactly. The values below
    # are chosen so that rounding them to Float32 would change them.
    set_data_path(tempdir())
    P, D, L, W = 3, 2, 4, 2
    logger = Logger(P, 2; bodies=1, deflections=D, pulleys=L, winches=W,
                    precision=Float64)
    written = map(1:2) do step
        ss = SysState(P; bodies=1, deflections=D, pulleys=L, winches=W, precision=Float64)
        ss.X .= [1 + 2.0^-40 * step, 2, 3]
        ss.VX .= [4 + 2.0^-40 * step, 5, 6]
        ss.VY .= [7, 8, 9 + 2.0^-40 * step]
        ss.VZ .= [10, 11, 12]
        ss.Qw .= [1 - 2.0^-40 * step, 0]
        ss.turn_rate_x .= [13 + 2.0^-40 * step, 14]
        ss.turn_rate_z .= [15, 16]
        ss.twist_angles .= [0.1, 0.2 + 2.0^-40 * step]
        ss.twist_vel .= [0.3, 0.4]
        ss.pulley_len .= [17 + 2.0^-40 * step, 18, 19, 20]
        ss.pulley_vel .= [21, 22, 23, 24]
        ss.l_tether .= [25 + 2.0^-40 * step, 26]
        ss.v_reelout .= [29, 30]
        log!(logger, ss)
        ss
    end
    save_log(logger, "differential_state_test")
    rt = load_log("differential_state_test")
    @test rt isa SysLog
    @test eltype(rt.syslog[1].X) == Float64
    @test length(rt.syslog[1].pulley_len) == L
    for step in 1:2, field in (:X, :VX, :VY, :VZ, :Qw, :turn_rate_x, :turn_rate_z,
                               :twist_angles, :twist_vel,
                               :pulley_len, :pulley_vel, :l_tether, :v_reelout)
        @test getproperty(rt.syslog[step], field) ==
              getproperty(written[step], field)
    end
end

@testset "KiteUtils.jl: log metadata    " begin
    set_data_path(tempdir())
    logger = Logger(7, 3)
    for _ in 1:3
        log!(logger, KiteUtils.demo_state(7))
    end
    document = "{\"sections\": [1, 2], \"note\": \"ünïcode and a newline\n\"}"

    save_log(logger, "metadata_test"; metadata = Dict("document" => document))
    with_document = load_log("metadata_test")
    @test with_document.metadata["document"] == document
    @test with_document.metadata["created"] == logger.created

    save_log(logger, "no_metadata_test")
    without_document = load_log("no_metadata_test")
    @test !haskey(without_document.metadata, "document")
    @test without_document.metadata["created"] == logger.created

    carried = KiteUtils.sys_log(logger, "metadata_carried")
    carried.metadata["document"] = document
    save_log(carried, false)
    @test load_log("metadata_carried").metadata["document"] == document

    # A stale declaration travelling on a loaded log cannot outrank what is written.
    carried.metadata["frame_convention"] = string(KS)
    save_log(carried, false)
    @test load_log("metadata_carried").metadata["frame_convention"] == string(KA)

    # A dict the table metadata cannot hold is refused before a file is opened.
    fresh_path = mktempdir()
    @test_throws TypeError save_log(carried, false; path = fresh_path,
                                    metadata = Dict("sections" => 2))
    @test isempty(readdir(fresh_path))
end

@testset "KiteUtils.jl: logger creation time" begin
    set_data_path(tempdir())
    logger = Logger(7, 1)
    log!(logger, KiteUtils.demo_state(7))

    @test occursin(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$", logger.created)

    # The stamp is the moment the Logger was built, not the moment of saving.
    logger.created = "1970-01-01T00:00:00"
    save_log(logger, "created_test")
    @test load_log("created_test").metadata["created"] == "1970-01-01T00:00:00"

    save_log(logger, "created_override"; metadata = Dict("created" => "mine"))
    @test load_log("created_override").metadata["created"] == "mine"
end

@testset "KiteUtils.jl: csv round trip  " begin
    # export_log writes every SysState column, so import_log has to read every one
    # back: a column it does not name comes back zeroed, and nothing says so.
    set_data_path(tempdir())
    P, D, L, W, S = 3, 2, 4, 2, 5
    logger = Logger(P, 2; wings=2, bodies=1, deflections=D, pulleys=L, winches=W,
                    segments=S)
    written = map(1:2) do step
        ss = SysState(P; wings=2, bodies=1, deflections=D, pulleys=L, winches=W,
                      segments=S)
        # One distinct value per field, so a column read into the wrong field, or
        # not read at all, cannot pass.
        for (i, field) in enumerate(fieldnames(SysState))
            value = getfield(ss, field)
            if value isa AbstractVector
                value .= [10i + j + step / 8 for j in eachindex(value)]
            elseif value isa Integer
                setfield!(ss, field, Int16(10i + step))
            else
                setfield!(ss, field, typeof(value)(10i + step / 8))
            end
        end
        log!(logger, ss)
        ss
    end
    export_log(KiteUtils.sys_log(logger, "csv_round_trip"))
    read_back = import_log("csv_round_trip")
    @test read_back isa SysLog{P}
    @test length(read_back.syslog) == 2
    for step in 1:2, field in fieldnames(SysState)
        @test getproperty(read_back.syslog[step], field) ==
              getproperty(written[step], field)
    end
end

@testset "aerodynamic loads are indexed by wing" begin
    set_data_path(tempdir())
    logger = Logger(3, 1; wings=2, bodies=1)
    written = SysState(3; wings=2, bodies=1)
    written.aero_force_KA_x .= [11, 12]
    written.aero_force_KA_y .= [21, 22]
    written.aero_force_KA_z .= [31, 32]
    written.aero_moment_KA_z .= [41, 42]
    log!(logger, written)
    save_log(logger, "per_wing_test")
    row = load_log("per_wing_test").syslog[1]
    @test typeof(row) == SysState{3, 3, 2, 0, 0, 1, 1, 0, 0, Float32}
    for field in (:aero_force_KA_x, :aero_force_KA_y, :aero_force_KA_z, :aero_moment_KA_z)
        @test getproperty(row, field) == getproperty(written, field)
    end
    @test all(iszero, row.aero_moment_KA_x)
end

@testset "a log with more wings than oriented frames is rejected on load" begin
    set_data_path(tempdir())
    logger = Logger(3, 1; wings=2, bodies=0)
    log!(logger, SysState(3; wings=2, bodies=0))
    save_log(logger, "more_wings_than_frames")
    table = KiteUtils.Arrow.Table(joinpath(tempdir(), "more_wings_than_frames.arrow"))
    columns = Dict{Symbol, Any}(name => collect(getproperty(table, name))
                                for name in propertynames(table))
    for quaternion in (:Qw, :Qx, :Qy, :Qz)
        columns[quaternion] = [q[1:1] for q in columns[quaternion]]
    end
    colmeta = Dict(Symbol("var_", lpad(i, 2, '0')) =>
                   ["name" => "var_" * lpad(i, 2, '0')] for i in 1:16)
    KiteUtils.Arrow.write(joinpath(tempdir(), "truncated_frames.arrow"),
                          NamedTuple(columns); colmetadata=colmeta,
                          metadata=KiteUtils.log_metadata())
    @test_throws ArgumentError load_log("truncated_frames")
end

@testset "a pre-split log: the two aerodynamic loads are wing 1, tether loads dropped" begin
    set_data_path(tempdir())
    logger = Logger(3, 1)
    log!(logger, SysState(3))
    save_log(logger, "per_body_split")
    split_table = KiteUtils.Arrow.Table(joinpath(tempdir(), "per_body_split.arrow"))
    columns = Dict{Symbol, Any}(name => collect(getproperty(split_table, name))
                                for name in propertynames(split_table))
    for load in ("aero_force_KA", "aero_moment_KA"), axis in ("x", "y", "z")
        delete!(columns, Symbol(load, "_", axis))
    end
    # Before 0.13 the two loads were one 3-vector each under aero_force_b and
    # aero_moment_b, and tether_induced_force is a column SysState no longer has.
    columns[:aero_force_b] = [Float32[7, 8, 9]]
    columns[:aero_moment_b] = [Float32[4, 5, 6]]
    columns[:tether_induced_force] = [Float32[1, 2, 3]]
    colmeta = Dict(Symbol("var_", lpad(i, 2, '0')) =>
                   ["name" => "var_" * lpad(i, 2, '0')] for i in 1:16)
    KiteUtils.Arrow.write(joinpath(tempdir(), "legacy_body_load.arrow"),
                          NamedTuple(columns); colmetadata=colmeta,
                          metadata=KiteUtils.log_metadata())
    row = load_log("legacy_body_load").syslog[1]
    @test row.aero_force_KA_x == Float32[7]
    @test row.aero_force_KA_y == Float32[8]
    @test row.aero_force_KA_z == Float32[9]
    @test row.aero_moment_KA_x == Float32[4]
    @test row.aero_moment_KA_y == Float32[5]
    @test row.aero_moment_KA_z == Float32[6]
end

@testset "a model without pulleys, panels or surfaces logs zero-length columns" begin
    set_data_path(tempdir())
    logger = Logger(3, 2; deflections=0, pulleys=0, segments=0, panels=0)
    for _ in 1:2
        log!(logger, SysState(3))
    end
    save_log(logger, "zero_length_test")
    row = load_log("zero_length_test").syslog[1]
    @test typeof(row) == SysState{3, 1, 1, 0, 0, 1, 1, 0, 0, Float32}
    for field in (:twist_angles, :twist_vel, :flap_angle, :pulley_len, :pulley_vel,
                  :spring_force, :gamma_distribution)
        @test length(getproperty(row, field)) == 0
    end
end

@testset "the panel circulation and the external force input round-trip" begin
    set_data_path(tempdir())
    logger = Logger(3, 1; panels=4)
    written = SysState(3; panels=4)
    written.gamma_distribution .= [1.5, 2.5, 3.5, 4.5]
    written.set_ext_force_x .= [10, 20, 30]
    written.set_ext_force_y .= [40, 50, 60]
    written.set_ext_force_z .= [70, 80, 90]
    log!(logger, written)
    save_log(logger, "panel_input_test")
    row = load_log("panel_input_test").syslog[1]
    @test typeof(row) == SysState{3, 1, 1, 0, 0, 1, 1, 0, 4, Float32}
    for field in (:gamma_distribution, :set_ext_force_x, :set_ext_force_y,
                  :set_ext_force_z)
        @test getproperty(row, field) == getproperty(written, field)
    end
end

@testset "demo_syslog sizes every column by the counts it is given" begin
    syslog = demo_syslog(7, 3, 3, 4, 2, 3, 5, 6; wings=2, duration=1)
    @test eltype(syslog) == SysState{7, 3, 2, 3, 4, 2, 3, 5, 6, Float32}
    row = syslog[end]
    @test length(row.Qw) == 3
    @test length(row.aero_force_KA_x) == 2
    @test length(row.flap_angle) == 3
    @test length(row.pulley_len) == 4
    @test length(row.set_torque) == 2
    @test length(row.l_tether) == 3
    @test length(row.spring_force) == 5
    @test length(row.gamma_distribution) == 6
end

@testset "demo_syslog reads its counts in the order of KiteUtils 0.13" begin
    @test eltype(demo_syslog(7, 2, 1, 3; duration=1)) ==
          SysState{7, 2, 1, 1, 3, 1, 1, 0, 0, Float32}
end

@testset "wings come first among the frames and the last position slots" begin
    state = SysState(6; wings=2, bodies=1)
    @test typeof(state) == SysState{6, 3, 2, 0, 0, 1, 1, 0, 0, Float32}
    @test length(state.turn_rate_x) == 3
    @test length(state.aero_force_KA_x) == 2
    state.Qw .= [0.1, 0.2, 0.3]
    state.X .= 1:6
    @test wing_Q(state, 2)[1] == 0.2f0
    @test body_Q(state, 1)[1] == 0.3f0
    @test wing_pos(state, 1)[1] == 4
    @test body_pos(state, 1)[1] == 6
    wing_pos(state, 2) .= [7, 8, 9]
    @test (state.X[5], state.Y[5], state.Z[5]) == (7, 8, 9)
    @test_throws BoundsError wing_Q(state, 3)
    @test_throws BoundsError body_pos(state, 2)
    @test_throws AssertionError SysState{6, 1, 2, 0, 0, 1, 1, 0, 0, Float32}()
    logger = Logger(6, 1; wings=2, bodies=1)
    log!(logger, state)
    logged = syslog(logger)
    @test wing_Q(logged, 2)[1][1] == 0.2f0
    @test body_pos(logged, 1)[1] == [6, 0, 0]
end

@testset "orients=O is one wing and O - 1 bodies" begin
    @test typeof(SysState(6; orients=3)) == typeof(SysState(6; wings=1, bodies=2))
    @test typeof(SysState(6; wings=2, orients=3)) == typeof(SysState(6; wings=2, bodies=1))
    @test typeof(Logger(6, 1; orients=3)) == typeof(Logger(6, 1; wings=1, bodies=2))
    @test typeof(demo_state(6; orients=3)) == typeof(SysState(6; bodies=2))
end

@testset "aero_force_KA and aero_moment_KA are wing 1's loads as a 3-vector" begin
    state = SysState(3; wings=2)
    state.aero_force_KA = [1, 2, 3]
    state.aero_moment_KA .= [4, 5, 6]
    state.aero_force_KA[2] = 7
    @test (state.aero_force_KA_x, state.aero_force_KA_y, state.aero_force_KA_z) ==
          ([1, 0], [7, 0], [3, 0])
    @test state.aero_moment_KA == [4, 5, 6]
    @test state.aero_moment_KA_z == [6, 0]
    @test :aero_force_KA in propertynames(state)
    logger = Logger(3, 1; wings=2)
    log!(logger, state)
    @test syslog(logger).aero_force_KA[1] == [1, 7, 3]
    @test syslog(logger).aero_moment_KA[1] == [4, 5, 6]
end

@testset "KiteUtils.jl: re-saving a loaded log" begin
    set_data_path(tempdir())
    logger = Logger(3, 1)
    log!(logger, SysState(3))
    colmeta = Dict(Symbol("var_", lpad(i, 2, '0')) => ["name" => "quantity_$i"]
                   for i in 1:16)
    save_log(logger, "resave_source"; colmeta)
    loaded = load_log("resave_source")
    loaded.name = "resave_target"
    save_log(loaded, false)
    @test load_log("resave_target").colmeta == colmeta
end
