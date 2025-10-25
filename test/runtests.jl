# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, StaticArrays, LinearAlgebra
using Test

cd("..")
@testset verbose=true "KiteUtils" begin

@testset "KiteUtils.jl: Settings       " begin
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
@testset "KiteUtils.jl: Settings2      " begin
    set = se("system2.yaml")
    @test set.sim_settings == "settings2.yaml"
    @test set.kcu_model == "KCU2"
    @test set.kcu_mass == 15.0
    @test set.kcu_diameter == 0.4
    @test set.depower_zero == 38.0
    @test set.degrees_per_percent_power == 1.0
    @test set.v_depower == 0.053
    @test set.v_steering == 0.212
end
@testset "KiteUtils.jl: SettingsRam      " begin
    set = se("system_ram.yaml")
    @test set.model == "data/ram_air_kite_body.obj"
    @test set.foil_file == "data/ram_air_kite_foil.dat"
    @test set.physical_model == "RamAirKite"
    @test length(set.top_bridle_points) == 4
    @test set.top_bridle_points[1] ≈ [0.290199, 0.784697, -2.61305]
    @test set.top_bridle_points[2] ≈ [0.392683, 0.785271, -2.61201]
    @test set.top_bridle_points[3] ≈ [0.498202, 0.786175, -2.62148]
    @test set.top_bridle_points[4] ≈ [0.535543, 0.786175, -2.62148]
    @test set.crease_frac ≈ 0.82
    @test length(set.bridle_fracs) == 4
    @test set.bridle_fracs ≈ [0.088, 0.31, 0.58, 0.93]
end

@testset "KiteUtils.jl: Copy           " begin
    datapath = get_data_path()
    tmpdir = joinpath(mktempdir(), "data")
    oldir = pwd()
    cd(dirname(tmpdir))
    set_data_path(tmpdir)
    @test get_data_path() == tmpdir
    copy_settings() # copy settings.yaml and system.yaml and settings_ram.yaml and system_ram.yaml
    @test isfile(joinpath(tmpdir, "settings.yaml"))
    @test isfile(joinpath(tmpdir, "system.yaml"))
    @test isfile(joinpath(tmpdir, "settings_ram.yaml"))
    @test isfile(joinpath(tmpdir, "system_ram.yaml"))
    cd(oldir)
    set_data_path(datapath)
end

@testset "KiteUtils.jl: system.yaml    " begin
    @test wc_settings() == "wc_settings.yaml"
    @test fpc_settings() == "fpc_settings.yaml"
    @test fpp_settings() == "fpp_settings.yaml"
end

@testset "KiteUtils.jl: New Constructors" begin
    se1 = Settings("system.yaml")
    @test se1.sim_settings == "settings.yaml"
    se2 = Settings("system_ram.yaml")
    @test se2.model == "data/ram_air_kite_body.obj"
    se2.model = "hey;)"
    @test se1.model == "data/kite.obj"
    @test se2.model == "hey;)"
    @test se2.foil_file == "data/ram_air_kite_foil.dat"
    se1.elevation = 420.0
    se2.elevation = 11.11
    @test se1.elevation == 420.0
    @test se2.elevation == 11.11
    dict1 = se_dict(se1)
    dict2 = se_dict(se2)
    dict1["initial"]["elevations"][1] == 420.0
    dict2["initial"]["elevations"][1] == 11.11
    
end

include("test_logfiles.jl")
include("test_logger.jl")
include("test_transformations.jl")
include("test_orientation.jl")
include("test_azimuth.jl")
include("test_rotational_inertia.jl")
include("test_system_structure.jl")
include("bench.jl")
include("aqua.jl")
end
nothing