# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, LinearAlgebra, StaticArrays, Test

@testset verbose=true "KiteUtils.jl: Transformations" begin
    @testset "Basic Transformations" begin
        ax, ay, az = [1, 0, 0], [0, 1, 0],  [0, 0, 1]
        bx, by, bz = [0, 1, 0], [-1, 0, 0], [0, 0, 1]
        res = rot3d(ax, ay, az, bx, by, bz)
        vec = [1, 0, 0]
        @test res * vec ≈ [0, 1, 0]
        pos_kite = [1.0, 1, 10]
        pos_before =  [1.0, 1, 9]
        v_app = [10, 0, 0.0]
        m = rot(pos_kite, pos_before, v_app)
        @test m == [0.0 0.0 -1.0; -1 0.0 0.0; 0 1 0]
        @test ground_dist(pos_kite) ≈ 1.4142135623730951
        @test calc_elevation(pos_kite) ≈ 1.4303066250413763
        @test azimuth_east(pos_kite) ≈ -0.7853981633974483
        @test acos2(1.0001) == 0.0
        @test acos2(-1.0001) ≈ π
        @test asin2(1.0001) ≈ pi/2
        @test asin2(-1.0001) ≈ -pi/2
        vec1 = SVector(1.0, 2.0, 3.0)
        orient = SVector(0, pi/10, pi / 2.0)
        elevation = deg2rad(71.5)
        azimuth   = 0.0
        @test fromENU2EG(vec1) == [2.0, -1.0, 3.0]
        @test fromW2SE(vec1, elevation, azimuth) == [0.0035903140090769448, 2.0, -3.16227562202369]
        azimuth   = deg2rad(45)
        @test fromW2SE(vec1, elevation, -azimuth) == [ 1.622480056571193,  2.121320343559643, -2.62060269137249]
        @test all(fromKS2EX(vec1, orient)        .≈ [-1.9999999999999998, 1.878107499419996, 2.544152554510513])
        @test calc_heading_w(orient)             ≈  [ 0.9510565162951535, 0.0,              0.3090169943749474]
        upwind_dirs = deg2rad.([-150.0, -90.0, -20.0, 45.0, 120.0])
        elevations = deg2rad.([10.0, 35.0, 71.5, 88.0])
        azimuths_w = deg2rad.([-170.0, -60.0, 0.0, 35.0, 120.0])
        for upwind_dir in upwind_dirs, elevation_case in elevations, azimuth_w in azimuths_w
            heading = KiteUtils.calc_heading(orient, elevation_case, azimuth_w; upwind_dir=upwind_dir, respos=false)
            clock = KiteUtils.calc_clock_angle(orient, elevation_case, azimuth_w; upwind_dir=upwind_dir, respos=false)
            @test wrap2pi(heading - clock) ≈ 0 atol=1e-12
        end
        @test_throws ArgumentError KiteUtils.calc_clock_angle(orient, π / 2, azimuth; respos=false)
        @test isfinite(KiteUtils.calc_clock_angle(orient, π / 2 - 1e-6, azimuth; respos=false))
        @test_broken calc_heading(orient, elevation, -azimuth)  ≈ 5.388664810099589
        calc_course(vec1, elevation, azimuth)
        @test wrap2pi(0.0)   == 0.0
        @test wrap2pi(2π)    == 0.0
        @test wrap2pi(3π)    == float(π)
        @test wrap2pi(-2π)   == 0.0
        @test wrap2pi(-3π)   == float(-π)
        @test wrap2pi(π)     == π
        @test wrap2pi(3.14)  == 3.14
        @test wrap2pi(3.15)  <  0.0
        @test wrap2pi(-3.15) >  0.0
        @test wrap2pi(-3.14) == -3.14
        @test wrap2pi(-π)    == -π
        x = @SVector [0, 1, 0] # in ENU reference frame this is pointing to the south
        y = @SVector [1, 0, 0] # in ENU reference frame this is pointing to the west
        z = @SVector [0, 0, -1] # in ENU reference frame this is pointing down
        rotation = calc_orient_rot(x, y, z; viewer=false)
        @test rotation == I
        orient = quat2viewer(rotation, KS)
        @test orient ≈ [-0.0, 0.0, 0.7071067811865475, 0.7071067811865475]
        rotation = calc_orient_rot(x, y, z; viewer=true)
        @test_broken rotation ≈ [-1.0 0.0 -0.0; 0.0 0.0 1.0; 0 1 0]
    end

    @testset "euler2rot" begin
        @test euler2rot(0, 0, 0) == I
        @test euler2rot(0, 0, π) == [-1.0 0.0 0.0; 0.0 -1.0 0.0; 0.0 0.0 1.0]
        @test euler2rot(0, π, 0) == [-1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 -1.0]
        @test euler2rot(π, 0, 0) == [1.0 0.0 0.0; 0.0 -1.0 0.0; 0.0 0.0 -1.0]
    end
end