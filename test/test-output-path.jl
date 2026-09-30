# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "get_output_path creates the folder it names" begin
    output_path = joinpath(mktempdir(), "results")
    set_output_path(output_path)
    @test get_output_path() == output_path
    @test isdir(output_path)
    set_output_path()
    @test KiteUtils.OUTPUT_PATH[1] == "output"
end

@testset "logs are written to and read from the output folder" begin
    set_data_path(joinpath(@__DIR__, "..", "data"))
    log = demo_log(7, "output_round_trip")
    set_data_path(mktempdir())
    set_output_path(mktempdir())
    @test save_log(log) == joinpath(get_output_path(), "output_round_trip.arrow")
    @test load_log("output_round_trip").syslog.time == log.syslog.time
    @test export_log(log) == joinpath(get_output_path(), "output_round_trip.csv")
    @test import_log("output_round_trip").syslog.time == log.syslog.time
    @test isempty(readdir(get_data_path()))
    set_data_path(joinpath(@__DIR__, "..", "data"))
end
