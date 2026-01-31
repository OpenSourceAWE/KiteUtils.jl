# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: Settings2      " begin
    cd(joinpath(@__DIR__, ".."))
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