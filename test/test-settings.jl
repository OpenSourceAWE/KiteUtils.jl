# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: Settings       " begin
    cd(joinpath(@__DIR__, ".."))
    @test se().sim_settings == "settings.yaml"
    @test se().log_file == joinpath("data", "log_8700W_8ms")
    @test se().time_lapse == 1.0
    @test se().sim_time == 409.0
    @test se().log_level == 2
    @test se().kcu_model == "KCU1"
    @test se().relaxation == 0.4
    @test se().elevation_rate == 0.0
    @test se().azimuth_rate == 0.0
    set = deepcopy(se())
    @test set.l_tether == 50.0
    @test set.kite_distance == 51.0
    set.l_tether = 51.0
    @test set.l_tether == 51
    set.kite_distance = 52.0
    @test set.kite_distance == 52.0
    @test set.v_reel_out == 0.0
    set.v_reel_out = 1.0
    @test set.v_reel_out == 1.0
    @test set.elevation == 70.8
    set.elevation = 0.0
    @test set.elevation == 0.0
    @test set.elevation_rate == 0.0
    set.elevation_rate = 1.0
    @test set.elevation_rate == 1.0
    @test set.azimuth == 0.0
    set.azimuth = 1.0
    @test set.azimuth == 1.0
    @test set.azimuth_rate == 0.0
    set.azimuth_rate = 1.0
    @test set.azimuth_rate == 1.0
    @test set.heading == 0.0
    set.heading = 1.0
    @test set.heading == 1.0
    @test set.heading_rate == 0.0
    set.heading_rate = 1.0
    @test set.heading_rate == 1.0
    @test set.depower == 25.0
    set.depower = 1.0
    @test set.depower == 1.0
    @test set.steering == 0.0
    set.steering = 1.0
    @test set.steering == 1.0
    set_data_path("data")
    @test se("system2.yaml").cs_4p == 1.1
    @test length(se().alpha_cl) == 12
    set_data_path(tempdir())
    @test KiteUtils.DATA_PATH[1] == tempdir()
    set_data_path("data")
    set2 = load_settings(joinpath("data", "system.yaml"))
    @test set2.sim_settings == "settings.yaml"
    @test se_dict()["environment"]["z0"] == se().z0
    set3 = update_settings()
    @test set3 == se()
end