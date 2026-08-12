# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test, StructArrays

@testset "KiteUtils.jl: Log files      " begin
    state = KiteUtils.demo_state(7)
    @test typeof(state) == SysState{7, 1, 0, 0, 1, 1, Float32}
    @test state.X[end] == 10.0
    @test all(state.pos[end] .≈ [10, 0, 6.0])
    @test repr(state) == "time [s]:          0.0\nt_sim [s]:         0.012\nsys_state [-]:     0\ncycle [-]:         0\nfig_8 [-]:         0\ne_mech [Wh]:       0.0\norient [-]:        Float32[0.5, 0.5, -0.5, -0.5]\nturn_rates [rad/s]:Float32[0.0, 0.0, 0.0]\nelevation [rad]:   0.5404195\nazimuth [rad]:     0.0\nazimuth_rate [rad/s]:0.0\nl_tether [m]:      Float32[0.0]\nv_reelout [m/s]:   Float32[0.0]\nwinch_force [N]:   Float32[0.0]\ndepower [0..1]:    0.0\nsteering [-1..1]:  0.0\nkcu_steering [-1..1]:0.0\nset_steering [-1..1]:0.0\nheading [rad]:     0.0\nheading_rate [rad/s]:0.0\ncourse [rad]:      0.0\nbearing [rad]:     0.0\nattractor [rad]:   Float32[0.0, 0.0]\nv_app [m/s]:       0.0\nv_wind_gnd [m/s]:  Float32[10.4855, 0.0, -3.08324]\nv_wind_200m [m/s]: Float32[10.4855, 0.0, -3.08324]\nv_wind_kite [m/s]: Float32[10.4855, 0.0, -3.08324]\nAoA [rad]:         0.0\nside_slip [rad]:   0.0\nalpha3 [rad]:      0.0\nalpha4 [rad]:      0.0\nCL2 [-]:           0.0\nCD2 [-]:           0.0\naero_force_b [N]:  Float32[0.0, 0.0, 0.0]\naero_moment_b [Nm]:Float32[0.0, 0.0, 0.0]\ntether_induced_force [N]:Float32[0.0, 0.0, 0.0]\ntether_induced_moment [Nm]:Float32[0.0, 0.0, 0.0]\ntwist_angles [rad]:Float32[]\nvel_kite [m/s]:    Float32[0.0, 0.0, 0.0]\nacc [m/s²]:        0.0\nX [m]:             Float32[0.0, 1.6666666, 3.3333333, 5.0, 6.6666665, 8.333333, 10.0]\nY [m]:             Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nZ [m]:             Float32[0.0, 0.15380114, 0.6194867, 1.4100224, 2.5474184, 4.063342, 6.0000005]\nflap_angle [rad]:  Float32[]\nVX [m/s]:          Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nVY [m/s]:          Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nVZ [m/s]:          Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nturn_rate_x [rad/s]:Float32[0.0]\nturn_rate_y [rad/s]:Float32[0.0]\nturn_rate_z [rad/s]:Float32[0.0]\ntwist_vel [rad/s]: Float32[]\npulley_len [m]:    Float32[]\npulley_vel [m/s]:  Float32[]\nset_torque [Nm]:   Float32[0.0]\nset_speed [m/s]:   Float32[0.0]\nset_force [N]:     Float32[0.0]\nroll [rad]:        0.0\npitch [rad]:       0.0\nyaw [rad]:         0.0\nvar_01 [-]:        0.0\nvar_02 [-]:        0.0\nvar_03 [-]:        0.0\nvar_04 [-]:        0.0\nvar_05 [-]:        0.0\nvar_06 [-]:        0.0\nvar_07 [-]:        0.0\nvar_08 [-]:        0.0\nvar_09 [-]:        0.0\nvar_10 [-]:        0.0\nvar_11 [-]:        0.0\nvar_12 [-]:        0.0\nvar_13 [-]:        0.0\nvar_14 [-]:        0.0\nvar_15 [-]:        0.0\nvar_16 [-]:        0.0\n"
    state = KiteUtils.demo_state_4p(7)
    @test typeof(state) == SysState{11, 1, 0, 0, 1, 1, Float32}
    @test state.X[end] ≈ 13.62487f0
    @test state.Y[end] ≈ -2.885
    @test state.Y[end-1] ≈ 2.885
    @test demo_state_4p(7).t_sim == 0.014
    set_data_path(joinpath(@__DIR__, "..", "data"))
    filename="transition"
    log = import_log(filename)
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
    log2 = load_log(dotted_name)           # without extension
    @test log2 isa SysLog
    @test length(log2.syslog) == 8180
    log3 = load_log(dotted_name * ".arrow") # with extension
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
    log_csv = import_log("transition")
    @test log_csv isa SysLog
    @test all(log_csv.syslog.azimuth_rate .== 0.0f0)  # absent column → default 0
end

@testset "KiteUtils.jl: flap_angle      " begin
    # Back-compat: an .arrow written before the flap_angle column existed must
    # still load, with flap_angle zeroed at the file's own twist-surface count.
    set_data_path(joinpath(@__DIR__, "..", "data"))
    old = load_log("Test_flight")
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
        log = load_log(name)
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
    end
    # A log with no twist_angles column defaults it to zero rather than garbage.
    old = load_log("sim_log")
    @test all(iszero, old.syslog[1].twist_angles)
end

@testset "KiteUtils.jl: differential state" begin
    # Every archived log predates the differential-state columns, so loading them
    # exercises the back-compat path: absent columns default to zero, and the
    # float type stays whatever the file was written with.
    set_data_path(joinpath(@__DIR__, "..", "data"))
    for name in ("Test_flight", "transition", "sim_log", "failure_low_right")
        old = load_log(name)
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
    P, O, D, L, W = 3, 2, 2, 4, 2
    logger = Logger(P, 2; orients=O, deflections=D, pulleys=L, winches=W,
                    precision=Float64)
    written = map(1:2) do step
        ss = SysState{P, O, D, L, W, W, Float64}()
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