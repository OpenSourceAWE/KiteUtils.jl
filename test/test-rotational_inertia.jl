# SPDX-FileCopyrightText: 2022 Uwe Fechner, Daan van Wolffelaar
# SPDX-License-Identifier: MIT

using Test
using KiteUtils

@testset verbose=true "test_rotational_inertia" begin
    @testset "point mass" begin
        X = [20]
        Y = [511]
        Z = [123]
        M = [21]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 0
        @test Ixy == 0
        @test Ixz == 0
        @test Iyy == 0
        @test Iyz == 0
        @test Izz == 0
    end

    @testset "line in x" begin
        X = [-10, 10]
        Y = [20, 20]
        Z = [-3, -3]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 0
        @test Ixy == 0
        @test Ixz == 0
        @test Iyy == 840
        @test Iyz == 0
        @test Izz == 840
    end

    @testset "line in y" begin
        X = [10, 10]
        Y = [-20, 20]
        Z = [-3, -3]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 3360
        @test Ixy == 0
        @test Ixz == 0
        @test Iyy == 0
        @test Iyz == 0
        @test Izz == 3360
    end

    @testset "line in z" begin
        X = [10, 10]
        Y = [20, 20]
        Z = [3, -3]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 75.6
        @test Ixy == 0
        @test Ixz == 0
        @test Iyy == 75.6
        @test Iyz == 0
        @test Izz == 0
    end

    @testset "line in xy" begin
        X = [-10, 10]
        Y = [-20, 20]
        Z = [-3, -3]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 3360
        @test Ixy == 1680
        @test Ixz == 0
        @test Iyy == 840
        @test Iyz == 0
        @test Izz == 4200
    end

    @testset "line in xz" begin
        X = [-10, 10]
        Y = [-3, -3]
        Z = [-20, 20]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 3360
        @test Ixy == 0
        @test Ixz == 1680
        @test Iyy == 4200
        @test Iyz == 0
        @test Izz == 840
    end

    @testset "line in yz" begin
        X = [-3, -3]
        Y = [-10, 10]
        Z = [-20, 20]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test Ixx == 4200 
        @test Ixy == 0
        @test Ixz == 0
        @test Iyy == 3360
        @test Iyz == 1680
        @test Izz == 840
    end

    @testset "line in xyz" begin
        X = [-10, 10]
        Y = [-20, 20]
        Z = [3, -3]
        M = [7, 3]

        Ixx, Ixy, Ixz, Iyy, Iyz, Izz = KiteUtils.calculate_rotational_inertia(X, Y, Z, M)

        @test isapprox(Ixx, 3435.6)
        @test Ixy == 1680
        @test Ixz == -252
        @test isapprox(Iyy, 915.6)
        @test Iyz == -504
        @test Izz == 4200
    end
end