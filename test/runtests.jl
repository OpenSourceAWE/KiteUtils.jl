# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils
using Test

#=
Don't add your tests to runtests.jl. Instead, create files named

    test-title-for-my-test.jl

The file will be automatically included inside a `@testset` with title "Title For My Test".
=#

@testset "KiteUtils.jl: system.yaml    " begin
    # Ensure we're using the correct data path and file
    set_data_path("data")
    @test wc_settings("system.yaml") == "wc_settings.yaml"
    @test fpc_settings("system.yaml") == "fpc_settings.yaml"
    @test fpp_settings("system.yaml") == "fpp_settings.yaml"
    @test vsm_settings("system.yaml") == "vsm_settings.yaml"
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
if basename(pwd()) == "test"; cd(".."); end

for (_, _, files) in walkdir(@__DIR__)
    for file in files
        if isnothing(match(r"^test-.*\.jl$", file))
            continue
        end
        title = titlecase(replace(splitext(file[6:end])[1], "-" => " "))
        title = rpad(title, 25)
        @testset "$title" begin
            include(file)
        end
    end
end
