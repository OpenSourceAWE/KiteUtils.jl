# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test, LinearAlgebra

@testset "wind_vec_from_angles" begin
    # Wind from west (upwind_dir = -pi/2), horizontal
    # Downwind is east, so wind_vec should point east
    wv = wind_vec_from_angles(10.0, -pi/2, 0.0)
    @test wv[1] ≈ 10.0  atol=1e-10  # east
    @test wv[2] ≈  0.0  atol=1e-10  # north
    @test wv[3] ≈  0.0  atol=1e-10  # up

    # Wind from north (upwind_dir = 0), horizontal
    # Downwind is south, so wind_vec should point south
    wv = wind_vec_from_angles(10.0, 0.0, 0.0)
    @test wv[1] ≈  0.0   atol=1e-10  # east
    @test wv[2] ≈ -10.0  atol=1e-10  # north (south)
    @test wv[3] ≈  0.0   atol=1e-10  # up

    # Wind from south (upwind_dir = pi), horizontal
    # Downwind is north
    wv = wind_vec_from_angles(10.0, pi, 0.0)
    @test wv[1] ≈  0.0  atol=1e-10
    @test wv[2] ≈ 10.0  atol=1e-10
    @test wv[3] ≈  0.0  atol=1e-10

    # Wind from east (upwind_dir = pi/2), horizontal
    # Downwind is west
    wv = wind_vec_from_angles(10.0, pi/2, 0.0)
    @test wv[1] ≈ -10.0  atol=1e-10
    @test wv[2] ≈   0.0  atol=1e-10
    @test wv[3] ≈   0.0  atol=1e-10

    # Wind from above (upwind_elevation > 0), wind blows downward
    wv = wind_vec_from_angles(10.0, -pi/2, pi/6)
    @test wv[3] < 0  # downward

    # Wind from below (upwind_elevation < 0), wind blows upward
    wv = wind_vec_from_angles(10.0, -pi/2, -pi/6)
    @test wv[3] > 0  # upward

    # Zero wind speed
    wv = wind_vec_from_angles(0.0, -pi/2, 0.0)
    @test norm(wv) ≈ 0.0

    # Wind from 10 deg east of north (upwind_dir = deg2rad(10)),
    # horizontal. Downwind azimuth = 10 + 180 = 190 deg from north.
    dir_10 = deg2rad(10.0)
    wv = wind_vec_from_angles(10.0, dir_10, 0.0)
    downwind_az = dir_10 + π
    @test wv[1] ≈ 10.0 * sin(downwind_az)  atol=1e-10  # east
    @test wv[2] ≈ 10.0 * cos(downwind_az)  atol=1e-10  # north
    @test wv[3] ≈ 0.0                      atol=1e-10

    # Wind from 10 deg east of north with 15 deg elevation
    elev_15 = deg2rad(15.0)
    wv = wind_vec_from_angles(10.0, dir_10, elev_15)
    h = 10.0 * cos(elev_15)
    @test wv[1] ≈ h * sin(downwind_az)      atol=1e-10
    @test wv[2] ≈ h * cos(downwind_az)      atol=1e-10
    @test wv[3] ≈ -10.0 * sin(elev_15)      atol=1e-10

    # Speed is preserved
    wv = wind_vec_from_angles(7.5, 1.2, 0.3)
    @test norm(wv) ≈ 7.5  atol=1e-10
end

@testset "angles_from_wind_vec" begin
    # Wind blowing east = wind from west
    v, dir, elev = angles_from_wind_vec([10.0, 0.0, 0.0])
    @test v    ≈ 10.0    atol=1e-10
    @test dir  ≈ -pi/2   atol=1e-10
    @test elev ≈  0.0    atol=1e-10

    # Wind blowing south = wind from north
    v, dir, elev = angles_from_wind_vec([0.0, -10.0, 0.0])
    @test v    ≈ 10.0  atol=1e-10
    @test dir  ≈  0.0  atol=1e-10
    @test elev ≈  0.0  atol=1e-10

    # Wind blowing north = wind from south
    v, dir, elev = angles_from_wind_vec([0.0, 10.0, 0.0])
    @test v    ≈ 10.0  atol=1e-10
    @test abs(dir) ≈ pi  atol=1e-10  # pi or -pi both valid
    @test elev ≈  0.0  atol=1e-10

    # Wind blowing west = wind from east
    v, dir, elev = angles_from_wind_vec([-10.0, 0.0, 0.0])
    @test v    ≈ 10.0   atol=1e-10
    @test dir  ≈  pi/2  atol=1e-10
    @test elev ≈  0.0   atol=1e-10

    # Wind blowing downward = upwind_elevation > 0
    v, dir, elev = angles_from_wind_vec([0.0, 0.0, -10.0])
    @test v    ≈ 10.0   atol=1e-10
    @test elev ≈  pi/2  atol=1e-10

    # Non-cardinal: wind from 10 deg east of north, horizontal
    dir_10 = deg2rad(10.0)
    downwind_az = dir_10 + π
    wv = [10.0 * sin(downwind_az), 10.0 * cos(downwind_az), 0.0]
    v, dir, elev = angles_from_wind_vec(wv)
    @test v    ≈ 10.0    atol=1e-10
    @test dir  ≈ dir_10  atol=1e-10
    @test elev ≈ 0.0     atol=1e-10

    # Non-cardinal: wind from 10 deg with 15 deg elevation
    elev_15 = deg2rad(15.0)
    h = 10.0 * cos(elev_15)
    wv = [h * sin(downwind_az), h * cos(downwind_az),
          -10.0 * sin(elev_15)]
    v, dir, elev = angles_from_wind_vec(wv)
    @test v    ≈ 10.0     atol=1e-10
    @test dir  ≈ dir_10   atol=1e-10
    @test elev ≈ elev_15  atol=1e-10

    # Zero wind
    v, dir, elev = angles_from_wind_vec([0.0, 0.0, 0.0])
    @test v    == 0.0
    @test dir  == 0.0
    @test elev == 0.0
end

@testset "round trip" begin
    # angles -> vec -> angles
    for (speed, dir, elev) in [
        (10.0, -pi/2,  0.0),
        (10.0,  0.0,   0.0),
        ( 5.0,  pi/4,  0.1),
        ( 8.0, -pi/3, -0.2),
        ( 3.0,  2.5,   pi/6),
        (12.0, -2.0,  -pi/4),
    ]
        wv = wind_vec_from_angles(speed, dir, elev)
        v2, dir2, elev2 = angles_from_wind_vec(wv)
        @test v2   ≈ speed  atol=1e-10
        @test elev2 ≈ elev  atol=1e-10
        # upwind_dir wraps, so compare via wrap2pi
        @test wrap2pi(dir2 - dir) ≈ 0.0  atol=1e-10
    end

    # vec -> angles -> vec
    for wv_in in [
        [10.0, 0.0, 0.0],
        [0.0, -5.0, 0.0],
        [3.0, 4.0, 0.0],
        [-2.0, 3.0, 1.0],
        [1.0, -1.0, -2.0],
        [0.0, 0.0, -7.0],
    ]
        v, dir, elev = angles_from_wind_vec(wv_in)
        wv_out = wind_vec_from_angles(v, dir, elev)
        @test wv_out ≈ wv_in  atol=1e-10
    end
end

@testset "sync_wind!" begin
    # auto-sync on load: wind_vec computed from angles
    set = deepcopy(se())
    @test set.use_wind_vec == false
    @test norm(set.wind_vec) ≈ set.v_wind  atol=1e-10

    # auto-sync on property set: change v_wind, wind_vec updates
    set.v_wind = 12.0
    @test norm(set.wind_vec) ≈ 12.0  atol=1e-10

    # auto-sync on property set: change upwind_dir, wind_vec updates
    set.upwind_dir = 0.0  # from north, blows south
    @test set.wind_vec[2] ≈ -12.0  atol=1e-10

    # round trip via use_wind_vec toggle
    set.upwind_elevation = 15.0
    vec_copy = copy(set.wind_vec)
    set.use_wind_vec = true  # now angles are derived from vec
    @test set.v_wind ≈ 12.0   atol=1e-10
    @test set.upwind_dir ≈ 0.0  atol=1e-10
    @test set.upwind_elevation ≈ 15.0  atol=1e-10
end
