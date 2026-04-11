# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: system.yaml    " begin
    cd(joinpath(@__DIR__, ".."))
    set_data_path("data")
    @test wc_settings() == "wc_settings.yaml"
    @test fpc_settings() == "fpc_settings.yaml"
    @test fpp_settings() == "fpp_settings.yaml"
    @test wc_settings("system.yaml") == "wc_settings.yaml"
    @test fpc_settings("system.yaml") == "fpc_settings.yaml"
    @test fpp_settings("system.yaml") == "fpp_settings.yaml"
    @test vsm_settings("system.yaml") == "vsm_settings.yaml"
    @test aero_geometry_settings("system.yaml") == "aero_geometry.yaml"
    @test struc_geometry_settings("system.yaml") == "struc_geometry.yaml"
end