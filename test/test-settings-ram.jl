# SPDX-FileCopyrightText: 2022 Uwe Fechner, Daan van Wolffelaar
# SPDX-License-Identifier: MIT

using KiteUtils
using Test

@testset "KiteUtils.jl: SettingsRam      " begin
    set_data_path(joinpath(@__DIR__, "..", "data"))
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
    # Reset to default project to avoid affecting other tests
    se("system.yaml")
end