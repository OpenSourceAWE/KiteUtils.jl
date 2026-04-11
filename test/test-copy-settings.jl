# SPDX-FileCopyrightText: 2022 Uwe Fechner, Daan van Wolffelaar
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: Copy           " begin
    datapath = get_data_path()
    tmpdir = joinpath(mktempdir(), "data")
    olddir = pwd()
    cd(dirname(tmpdir))
    set_data_path(tmpdir)
    @test get_data_path() == tmpdir
    copy_settings() # copy settings.yaml and system.yaml and settings_ram.yaml and system_ram.yaml
    @test isfile(joinpath(tmpdir, "settings.yaml"))
    @test isfile(joinpath(tmpdir, "system.yaml"))
    @test isfile(joinpath(tmpdir, "settings_ram.yaml"))
    @test isfile(joinpath(tmpdir, "system_ram.yaml"))
    cd(olddir)
    set_data_path(datapath)
end