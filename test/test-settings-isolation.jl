# SPDX-FileCopyrightText: 2026 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: Settings isolation" begin
    datapath = joinpath(@__DIR__, "..", "data")
    set_data_path(datapath)

    # Settings(project) must not change the project of the global settings
    glob = load_settings("system.yaml")
    @test glob.sim_settings == "settings.yaml"
    other = Settings("system_ram.yaml")
    @test other.sim_settings == "settings_ram.yaml"
    @test KiteUtils.PROJECT == "system.yaml"
    @test se().sim_settings == "settings.yaml"
    @test update_settings().sim_settings == "settings.yaml"
    # an independent instance reloads from its own project, not from the global one
    other.segments = 0
    @test se(other) === other
    @test other.sim_settings == "settings_ram.yaml"
    @test KiteUtils.PROJECT == "system.yaml"

    # set_data_path forces the global settings to be reloaded from the new path
    tmp = joinpath(mktempdir(), "data")
    cp(datapath, tmp)
    file = joinpath(tmp, "settings.yaml")
    write(file, replace(read(file, String), r"segments:\s*\d+" => "segments: 13"; count=1))
    @test se().segments == 6
    set_data_path(tmp)
    @test se().segments == 13
    set_data_path(datapath)
    @test se().segments == 6
    # a directory that only holds log files keeps the loaded settings
    set_data_path(mktempdir())
    @test se().segments == 6
    set_data_path(datapath)
end
