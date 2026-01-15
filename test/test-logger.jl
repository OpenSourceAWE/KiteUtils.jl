# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

@testset "Logger:                      " begin
    set_data_path(tempdir())
    steps = 20*30
    logger = Logger(7, steps)
    state = demo_state(7)
    for i in 1:steps
        @test (@allocated log!(logger, state)) == 0
    end
    @test logger.time_vec == zeros(steps)
    @test save_log(logger) == joinpath(tempdir(), "sim_log.arrow")
    logger = Logger(7, 2)
    @test length(logger) == 0
    log!(logger, state)
    log!(logger, state)
    log!(logger, state)
    @test length(logger) == 2
    logger = Logger(7, 100)
    log!(logger, state)
    log!(logger, state)
    @test length(logger.time_vec) == 100
    save_log(logger) == joinpath(tempdir(), "sim_log.arrow")
    @test length(logger.time_vec) == 2
    log = load_log("transition.arrow2"; path=joinpath(@__DIR__, "..", "data"))
    length(log.syslog.time) == 8180
end