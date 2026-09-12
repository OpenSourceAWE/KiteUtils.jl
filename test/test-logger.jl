# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "Logger:                      " begin
    set_data_path(tempdir())
    steps = 20*30
    logger = Logger(7, steps)
    state = demo_state(7)
    for _ in 1:steps
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
    @test save_log(logger) == joinpath(tempdir(), "sim_log.arrow")
    @test length(logger.time_vec) == 100
    @test length(load_log("sim_log").syslog) == 2
    log = load_log("transition.arrow2"; path=joinpath(@__DIR__, "..", "data"))
    @test length(log.syslog.time) == 8180
end

@testset "SysLog from a Logger         " begin
    set_data_path(tempdir())
    logger = Logger(7, 10)
    state = demo_state(7)
    for step in 1:3
        state.time = step
        log!(logger, state)
    end
    flight_log = sys_log(logger, "sys_log_test")
    @test length(flight_log.syslog) == 3
    @test flight_log.syslog.time == [1.0, 2.0, 3.0]
    @test length(logger.time_vec) == 10
    save_log(logger, "sys_log_test")
    @test load_log("sys_log_test").syslog.time == flight_log.syslog.time
    @test length(logger.time_vec) == 10
end
