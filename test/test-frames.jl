# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

using LinearAlgebra, Rotations, StaticArrays, Test
using KiteUtils

# The KS chain as it was before the calculations moved onto KA. Kept here, and only
# here, so that the KA formulation can be shown to reproduce it exactly.
function heading_ks_reference(orientation, elevation, azimuth; upwind_dir=-pi/2,
                              respos=true)
    down_wind_direction = wrap2pi(upwind_dir + π)
    headingEG = fromEX2EG(fromKS2EX(SVector(1.0, 0.0, 0.0), orientation))
    headingSE = fromW2SE(fromEG2W(headingEG, down_wind_direction), elevation, azimuth)
    angle = atan(headingSE[2], headingSE[1])
    angle < 0 && respos ? angle + 2π : angle
end

function clock_ks_reference(orientation, elevation, azimuth; upwind_dir=-pi/2,
                           respos=true)
    x_kite_EG = fromEX2EG(fromKS2EX(SVector(1.0, 0.0, 0.0), orientation))
    x_kite_ENU = SVector(-x_kite_EG[2], x_kite_EG[1], x_kite_EG[3])
    azimuth_n = wrap2pi(azimuth - upwind_dir - π)
    pos_unit = SVector(-cos(elevation) * sin(azimuth_n), cos(elevation) * cos(azimuth_n),
                       sin(elevation))
    z_kite = -pos_unit
    up = SVector(0.0, 0.0, 1.0)
    ref = normalize(up - dot(up, z_kite) * z_kite)
    perp = cross(z_kite, ref)
    angle = atan(dot(x_kite_ENU, perp), dot(x_kite_ENU, ref))
    angle < 0 && respos ? angle + 2π : angle
end

attitudes = [(r, p, y) for r in deg2rad.(-150:37:150) for p in deg2rad.(-80:23:80)
                       for y in deg2rad.(-170:41:170)]
positions = [(deg2rad(el), deg2rad(az)) for el in (5, 30, 60, 85)
                                        for az in (-170, -60, 0, 45, 120)]

@testset verbose=true "frame conventions" begin
    @testset "conversion matrices" begin
        vec = SVector(1.0, 2.0, 3.0)
        @test ENU2NED(vec) == SVector(2.0, 1.0, -3.0)
        @test NED2ENU(ENU2NED(vec)) == vec
        @test_throws ArgumentError KS2KA(vec)
    end
    @testset "orientation needs a rotation on both sides" begin
        # Kite at zenith, nose north. KS is then the identity against NED; the same
        # attitude in KA has the aft axis pointing south and the up axis up.
        rot_ks = calc_orient_rot([0, 1, 0], [1, 0, 0], [0, 0, -1])
        @test rot_ks ≈ I
        rot_ka = KS2KA(rot_ks)
        @test rot_ka[:, 1] ≈ [0, -1, 0]   # aft, pointing south in ENU
        @test rot_ka[:, 2] ≈ [1, 0, 0]    # right tip, pointing east in ENU
        @test rot_ka[:, 3] ≈ [0, 0, 1]    # up
        @test kite_nose(rot_ka) ≈ [0, 1, 0]
        @test KA2KS(rot_ka) ≈ rot_ks
        @test all(rad2deg.(euler_ks(rot_ka)) .≈ (0, 0, 0))
    end
    @testset "euler_ks against physical attitudes" begin
        # Body axes given as KA (aft, right, up) in ENU, so the orientation is [x y z].
        for (x, y, z, expected) in (([0.0, -1, 0], [1.0, 0, 0], [0.0, 0, 1], (0, 0, 0)),
                                    ([-1.0, 0, 0], [0.0, -1, 0], [0.0, 0, 1], (0, 0, 90)),
                                    (normalize([0, 1.0, -1]), [-1.0, 0, 0],
                                     normalize([0, 1.0, 1]), (0, 45, 180)))
            @assert is_right_handed_orthonormal(x, y, z)
            @test all(rad2deg.(euler_ks(hcat(x, y, z))) .≈ expected)
        end
    end
    @testset "round trips over every form" begin
        for (roll, pitch, yaw) in attitudes
            rot_ks = euler2rot(roll, pitch, yaw)
            rot_ka = KS2KA(rot_ks)
            @test KA2KS(rot_ka) ≈ rot_ks
            @test det(rot_ka) ≈ 1
            q_ka = KS2KA(QuatRotation(rot_ks))
            @test RotMatrix{3}(q_ka) ≈ rot_ka
            v_ka = KS2KA(Rotations.params(QuatRotation(rot_ks)))
            @test QuatRotation(v_ka) ≈ q_ka
            @test all(euler_ks(q_ka) .≈ (roll, pitch, yaw))
            @test all(euler_ks((roll, pitch, yaw) |> collect, KS) .≈ (roll, pitch, yaw))
        end
    end
    @testset "heading and clock angle: KA equals the old KS chain" begin
        for (roll, pitch, yaw) in attitudes
            euler = [roll, pitch, yaw]
            q_ka = KS2KA(QuatRotation(euler2rot(roll, pitch, yaw)))
            for (elevation, azimuth) in positions
                @test calc_heading(q_ka, elevation, azimuth) ≈
                      heading_ks_reference(euler, elevation, azimuth)
                @test calc_clock_angle(q_ka, elevation, azimuth) ≈
                      clock_ks_reference(euler, elevation, azimuth)
                # Euler angles are always KS, so the old call sites keep working.
                @test calc_heading(euler, elevation, azimuth) ≈
                      heading_ks_reference(euler, elevation, azimuth)
                @test calc_clock_angle(euler, elevation, azimuth) ≈
                      clock_ks_reference(euler, elevation, azimuth)
            end
        end
    end
    @testset "logs declare their frame convention" begin
        data_path = get_data_path()
        log = demo_log(7, "frame_stamp")
        set_data_path(mktempdir())
        save_log(log)
        table = KiteUtils.Arrow.Table(joinpath(get_data_path(), "frame_stamp.arrow"))
        @test KiteUtils.Arrow.getmetadata(table)["frame_convention"] == "KA"
        @test (@test_logs load_log("frame_stamp")) isa SysLog
        set_data_path(data_path)
    end
    @testset "an undeclared log is converted on load" begin
        data_path = get_data_path()
        log = demo_log(7, "old_style")
        # A known KS attitude: nose north at zenith, so KA is a quarter turn away.
        q_ks = Rotations.params(QuatRotation(calc_orient_rot([0, 1, 0], [1, 0, 0],
                                                             [0, 0, -1])))
        q_ka = KS2KA(q_ks)
        for step in eachindex(log.syslog)
            log.syslog.Qw[step][1], log.syslog.Qx[step][1] = q_ks[1], q_ks[2]
            log.syslog.Qy[step][1], log.syslog.Qz[step][1] = q_ks[3], q_ks[4]
        end
        set_data_path(mktempdir())
        # Written without the stamp, exactly as a pre-0.13 KiteUtils would have.
        KiteUtils.Arrow.write(joinpath(get_data_path(), "old_style.arrow"), log.syslog,
                              colmetadata=log.colmeta)
        @test isnothing(log_convention(KiteUtils.Arrow.Table(
            joinpath(get_data_path(), "old_style.arrow"))))

        loaded = load_log("old_style")                      # warns, assumes KS
        @test all(collect(loaded.syslog.orient[1]) .≈ q_ka)
        @test all(rad2deg.(euler_ks(loaded.syslog.orient[1])) .≈ (0, 0, 0))

        # A SAM-written log of the same era was already KA; frame=KA leaves it alone.
        untouched = load_log("old_style"; frame=KA)
        @test all(collect(untouched.syslog.orient[1]) .≈ q_ks)

        # A declared log is taken at its word and never converted.
        log.name = "declared"
        for step in eachindex(log.syslog)
            log.syslog.Qw[step][1], log.syslog.Qx[step][1] = q_ka[1], q_ka[2]
            log.syslog.Qy[step][1], log.syslog.Qz[step][1] = q_ka[3], q_ka[4]
        end
        save_log(log)
        @test log_convention(KiteUtils.Arrow.Table(
            joinpath(get_data_path(), "declared.arrow"))) == KA
        kept = @test_logs load_log("declared")
        @test all(collect(kept.syslog.orient[1]) .≈ q_ka)
        set_data_path(data_path)
    end
    @testset "quat2viewer is convention aware" begin
        for (roll, pitch, yaw) in attitudes
            q_ks = QuatRotation(euler2rot(roll, pitch, yaw))
            q_ka = KS2KA(q_ks)
            @test quat2viewer(q_ka) ≈ quat2viewer(q_ks, KS)
        end
    end
end
nothing
