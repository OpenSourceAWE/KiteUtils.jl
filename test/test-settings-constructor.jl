# Test that Settings(project) correctly loads all YAML fields,
# that deprecated keys warn but still work, and that truly
# unknown keys raise errors.

using KiteUtils, Test

@testset "Settings(project) loads tether fields" begin
    cd(joinpath(@__DIR__, ".."))
    set_data_path("data")

    fresh = Settings("system.yaml")
    @test fresh.axial_stiffness == 614600.0
    @test fresh.axial_damping == 473.0
    @test fresh.height_k == 2.23
end

@testset "Deprecated YAML keys warn and work" begin
    cd(joinpath(@__DIR__, ".."))
    old_path = get_data_path()

    dep_settings = joinpath(tempdir(), "dep_settings.yaml")
    dep_system = joinpath(tempdir(), "dep_system.yaml")
    open(dep_settings, "w") do io
        println(io, "system:")
        println(io, "    log_file: \"data/log\"")
        println(io, "    sim_time: 100.0")
        println(io, "    segments: 6")
        println(io, "    sample_freq: 20")
        println(io, "solver:")
        println(io, "    abs_tol: 0.001")
        println(io, "    rel_tol: 0.001")
        println(io, "kite:")
        println(io, "    mass: 6.2")
        println(io, "    area: 10.0")
        println(io, "    height: 2.23")
        println(io, "tether:")
        println(io, "    damping: 473.0")
        println(io, "    c_spring: 614600.0")
        println(io, "environment:")
        println(io, "    v_wind: 9.0")
    end
    open(dep_system, "w") do io
        println(io, "system:")
        println(io, "    sim_settings: \"dep_settings.yaml\"")
    end

    set_data_path(tempdir())
    s = @test_warn r"deprecated" Settings("dep_system.yaml")
    @test s.axial_stiffness == 614600.0
    @test s.axial_damping == 473.0
    @test s.height_k == 2.23
    set_data_path(old_path)
end

@testset "Unknown YAML key raises error" begin
    cd(joinpath(@__DIR__, ".."))
    old_path = get_data_path()

    bad_settings = joinpath(tempdir(), "bad_settings.yaml")
    bad_system = joinpath(tempdir(), "bad_system.yaml")
    open(bad_settings, "w") do io
        println(io, "system:")
        println(io, "    log_file: \"data/log\"")
        println(io, "    sim_time: 100.0")
        println(io, "    segments: 6")
        println(io, "    sample_freq: 20")
        println(io, "solver:")
        println(io, "    abs_tol: 0.001")
        println(io, "    rel_tol: 0.001")
        println(io, "kite:")
        println(io, "    mass: 6.2")
        println(io, "    area: 10.0")
        println(io, "tether:")
        println(io, "    bogus_field: 999.0")
        println(io, "environment:")
        println(io, "    v_wind: 9.0")
    end
    open(bad_system, "w") do io
        println(io, "system:")
        println(io, "    sim_settings: \"bad_settings.yaml\"")
    end

    set_data_path(tempdir())
    @test_throws ErrorException Settings("bad_system.yaml")
    set_data_path(old_path)
end

@testset "set_data_path forces reload" begin
    cd(joinpath(@__DIR__, ".."))
    set_data_path("data")
    load_settings("system.yaml")
    @test KiteUtils.SETTINGS.segments == 6

    old_path = get_data_path()
    set_data_path(tempdir())
    @test KiteUtils.SETTINGS.segments == 0
    set_data_path(old_path)
end
