# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: system.yaml    " begin
    set_data_path(joinpath(@__DIR__, "..", "data"))
    @test wc_settings() == "wc_settings.yaml"
    @test fpc_settings() == "fpc_settings.yaml"
    @test fpp_settings() == "fpp_settings.yaml"
    @test vsm_settings_file() == "vsm_settings.yaml"
    @test aero_geometry_file() == "aero_geometry.yaml"
    @test structural_geometry_file() == "struc_geometry.yaml"
    @test wc_settings("system.yaml") == "wc_settings.yaml"
    @test fpc_settings("system.yaml") == "fpc_settings.yaml"
    @test fpp_settings("system.yaml") == "fpp_settings.yaml"
    @test vsm_settings_file("system.yaml") == "vsm_settings.yaml"
    @test aero_geometry_file("system.yaml") == "aero_geometry.yaml"
    @test structural_geometry_file("system.yaml") == "struc_geometry.yaml"
    @test vsm_settings("system.yaml") == "vsm_settings.yaml"
    @test aero_geometry_settings("system.yaml") == "aero_geometry.yaml"
    @test struc_geometry_settings("system.yaml") == "struc_geometry.yaml"
end