# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

@testset "KiteUtils.jl: Log files      " begin
    state = KiteUtils.demo_state(7)
    @test typeof(state) == SysState{7}
    @test state.X[end] == 10.0
    @test all(state.pos[end] .≈ [10, 0, 6.0])
    @test_broken repr(state) == "time      [s]:       0.0\nt_sim     [s]:       0.012\nsys_state    :       0\ne_mech    [Wh]:      0.0\norient    [w,x,y,z]: Float32[0.5, 0.5, -0.5, -0.5]\nelevation [rad]:     0.5404195\nazimuth   [rad]:     0.0\nl_tether  [m]:       0.0\nv_reelout [m/s]:     0.0\nforce     [N]:       0.0\ndepower   [-]:       0.0\nsteering  [-]:       0.0\nheading   [rad]:     0.0\ncourse    [rad]:     0.0\nv_app     [m/s]:     0.0\nvel_kite  [m/s]:     Float32[0.0, 0.0, 0.0]\nX         [m]:       Float32[10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]\nY         [m]:       Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]\nZ         [m]:       Float32[6.0000005, 6.0000005, 6.0000005, 6.0000005, 6.0000005, 6.0000005, 6.0000005]\nvar_01       :       0.0\nvar_02       :       0.0\nvar_03       :       0.0\nvar_04       :       0.0\nvar_05       :       0.0\nvar_06       :       0.0\nvar_07       :       0.0\nvar_08       :       0.0\nvar_09       :       0.0\nvar_10       :       0.0\nvar_11       :       0.0\nvar_12       :       0.0\nvar_13       :       0.0\nvar_14       :       0.0\nvar_15       :       0.0\nvar_16       :       0.0\n"
    state = KiteUtils.demo_state_4p(7)
    @test typeof(state) == SysState{11}
    @test state.X[end] ≈ 13.62487f0
    @test state.Y[end] ≈ -2.885
    @test state.Y[end-1] ≈ 2.885
    @test demo_state_4p(7).t_sim == 0.014
    set_data_path("data")
    filename="transition"
    log = import_log(filename)
    @test typeof(log) == SysLog{11}
    @test log.name == "transition"
    @test length(log.syslog) == 8180
    set_data_path(tempdir())
    log = KiteUtils.test(true)
    @test typeof(log) == SysLog{7}
    @test log.syslog.Z[end][7] ≈ 6 # height of the last particle which represents the kite (1p model)
    @test log.z1[end] ≈ 6.0
    @test log.y1[end] ≈ 0.0
    @test log.x1[end] ≈ 10.0
    @test log.x[end] ≈  6.6666665
    @test log.y[end] ≈  0.0
    @test log.z[end] ≈  2.5474184 # height of the prepre-last particle which represents the kite (4p model)
    @test export_log(log) == joinpath(tempdir(), "Test_flight.csv")
end