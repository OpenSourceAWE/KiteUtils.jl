# SPDX-FileCopyrightText: 2022 Uwe Fechner, Daan van Wolffelaar
# SPDX-License-Identifier: MIT

using KiteUtils
using Test

@testset "KiteUtils.jl: New Constructors" begin
    set_data_path(joinpath(@__DIR__, "..", "data"))
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
    @test dict1["initial"]["elevations"][1] == 420.0
    @test dict2["initial"]["elevations"][1] == 11.11
    # Reset global PROJECT to avoid affecting subsequent tests
    KiteUtils.PROJECT = "system.yaml"
end