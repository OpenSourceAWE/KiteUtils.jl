# SPDX-FileCopyrightText: 2022 Uwe Fechner, Daan van Wolffelaar
# SPDX-License-Identifier: MIT

using KiteUtils, Test

# kite position in ENU reference frame
@testset verbose=true "azimuth functions" begin
    pos_kite_east  = [100.0, 0, 100.0]  # east
    pos_kite_north = [0, 100.0, 100.0]  # north
    pos_kite_south = [0, -100.0, 100.0] # south

    @testset "azimuth_east turns counterclockwise from east" begin
        aze = azimuth_east(pos_kite_east)
        @test rad2deg(aze) ≈ 0.0 atol=1e-10
        aze = azimuth_east(pos_kite_north)
        @test rad2deg(aze) ≈ 90.0 atol=1e-10
        aze = azimuth_east(pos_kite_south)
        @test rad2deg(aze) ≈ -90.0 atol=1e-10
    end

    @testset "azimuth_north                " begin
        azn = azimuth_north(pos_kite_east)
        @test rad2deg(azn) ≈ -90.0 atol=1e-10
        azn = azimuth_north(pos_kite_north)
        @test rad2deg(azn) ≈ 0.0 atol=1e-10
        azn = azimuth_north(pos_kite_south)
        @test (rad2deg(azn) ≈ -180.0) || (rad2deg(azn) ≈ 180.0)
    end

    @testset "azimuth (wind reference frame)" begin
        azn = azimuth_north(pos_kite_east)           # - pi/2
        azw = azn2azw(azn; upwind_dir = -π/2) # wind from west
        @test rad2deg(azw) ≈ 0.0 atol=1e-10
        azw = azn2azw(azn; upwind_dir = 0)    # wind from north
        @test rad2deg(azw) ≈ 90.0 atol=1e-10
        azn = azimuth_north(pos_kite_north)          # zero
        azw = azn2azw(azn; upwind_dir = pi)   # wind from south
        @test rad2deg(azw) ≈ 0.0 atol=1e-10
    end
end
nothing
