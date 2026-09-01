# SPDX-FileCopyrightText: 2026 Bart van de Lint
# SPDX-License-Identifier: MIT

using LinearAlgebra, Rotations, StaticArrays, Test
using KiteUtils

# The KS chain as it was before the calculations moved onto KA. Kept here, and only
# here, so that the KA formulation can be shown to reproduce it exactly.
function heading_KS_reference(orientation, elevation, azimuth; upwind_dir=-pi/2,
                              respos=true)
    down_wind_direction = wrap2pi(upwind_dir + π)
    headingEG = fromEX2EG(fromKS2EX(SVector(1.0, 0.0, 0.0), orientation))
    headingSE = fromW2SE(fromEG2W(headingEG, down_wind_direction), elevation, azimuth)
    angle = atan(headingSE[2], headingSE[1])
    angle < 0 && respos ? angle + 2π : angle
end

function clock_KS_reference(orientation, elevation, azimuth; upwind_dir=-pi/2,
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
        @test fromENU2NED(vec) == SVector(2.0, 1.0, -3.0)
        @test fromNED2ENU(fromENU2NED(vec)) == vec
        @test_throws ArgumentError fromKS2KA(vec)
    end
    @testset "orientation needs a rotation on both sides" begin
        # Kite at zenith, nose north. KS is then the identity against NED; the same
        # attitude in KA has the aft axis pointing south and the up axis up.
        rot_KS = calc_orient_rot([0, 1, 0], [1, 0, 0], [0, 0, -1])
        @test rot_KS ≈ I
        rot_KA = fromKS2KA(rot_KS)
        @test rot_KA[:, 1] ≈ [0, -1, 0]   # aft, pointing south in ENU
        @test rot_KA[:, 2] ≈ [1, 0, 0]    # right tip, pointing east in ENU
        @test rot_KA[:, 3] ≈ [0, 0, 1]    # up
        @test fromKA2KS(rot_KA) ≈ rot_KS
        @test all(rad2deg.(euler_KS(rot_KA)) .≈ (0, 0, 0))
    end
    @testset "euler_KS against physical attitudes" begin
        # Body axes given as KA (aft, right, up) in ENU, so the orientation is [x y z].
        for (x, y, z, expected) in (([0.0, -1, 0], [1.0, 0, 0], [0.0, 0, 1], (0, 0, 0)),
                                    ([-1.0, 0, 0], [0.0, -1, 0], [0.0, 0, 1], (0, 0, 90)),
                                    (normalize([0, 1.0, -1]), [-1.0, 0, 0],
                                     normalize([0, 1.0, 1]), (0, 45, 180)))
            @assert is_right_handed_orthonormal(x, y, z)
            @test all(rad2deg.(euler_KS(hcat(x, y, z))) .≈ expected)
        end
    end
    @testset "round trips over every form" begin
        for (roll, pitch, yaw) in attitudes
            rot_KS = euler2rot(roll, pitch, yaw)
            rot_KA = fromKS2KA(rot_KS)
            @test fromKA2KS(rot_KA) ≈ rot_KS
            @test det(rot_KA) ≈ 1
            q_KA = fromKS2KA(QuatRotation(rot_KS))
            @test RotMatrix{3}(q_KA) ≈ rot_KA
            v_KA = fromKS2KA(Rotations.params(QuatRotation(rot_KS)))
            @test QuatRotation(v_KA) ≈ q_KA
            @test all(euler_KS(q_KA) .≈ (roll, pitch, yaw))
            @test all(euler_KS((roll, pitch, yaw) |> collect) .≈ (roll, pitch, yaw))
        end
    end
    @testset "heading and clock angle: KA equals the old KS chain" begin
        for (roll, pitch, yaw) in attitudes
            euler = [roll, pitch, yaw]
            q_KA = fromKS2KA(QuatRotation(euler2rot(roll, pitch, yaw)))
            for (elevation, azimuth) in positions
                @test calc_heading(q_KA, elevation, azimuth) ≈
                      heading_KS_reference(euler, elevation, azimuth)
                @test calc_clock_angle(q_KA, elevation, azimuth) ≈
                      clock_KS_reference(euler, elevation, azimuth)
                # Euler angles are always KS, so the old call sites keep working.
                @test calc_heading(euler, elevation, azimuth) ≈
                      heading_KS_reference(euler, elevation, azimuth)
                @test calc_clock_angle(euler, elevation, azimuth) ≈
                      clock_KS_reference(euler, elevation, azimuth)
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
        q_KS = Rotations.params(QuatRotation(calc_orient_rot([0, 1, 0], [1, 0, 0],
                                                             [0, 0, -1])))
        q_KA = fromKS2KA(q_KS)
        for step in eachindex(log.syslog)
            log.syslog.Qw[step][1], log.syslog.Qx[step][1] = q_KS[1], q_KS[2]
            log.syslog.Qy[step][1], log.syslog.Qz[step][1] = q_KS[3], q_KS[4]
        end
        set_data_path(mktempdir())
        # Written without the stamp, exactly as a pre-0.13 KiteUtils would have.
        KiteUtils.Arrow.write(joinpath(get_data_path(), "old_style.arrow"), log.syslog,
                              colmetadata=log.colmeta)
        @test isnothing(log_convention(KiteUtils.Arrow.Table(
            joinpath(get_data_path(), "old_style.arrow"))))

        loaded = load_log("old_style")                      # warns, assumes KS
        @test all(collect(loaded.syslog.orient[1]) .≈ q_KA)
        @test all(rad2deg.(euler_KS(loaded.syslog.orient[1])) .≈ (0, 0, 0))

        # A SAM-written log of the same era was already KA; frame=KA leaves it alone.
        untouched = load_log("old_style"; frame=KA)
        @test all(collect(untouched.syslog.orient[1]) .≈ q_KS)

        # A declared log is taken at its word and never converted.
        log.name = "declared"
        for step in eachindex(log.syslog)
            log.syslog.Qw[step][1], log.syslog.Qx[step][1] = q_KA[1], q_KA[2]
            log.syslog.Qy[step][1], log.syslog.Qz[step][1] = q_KA[3], q_KA[4]
        end
        save_log(log)
        @test log_convention(KiteUtils.Arrow.Table(
            joinpath(get_data_path(), "declared.arrow"))) == KA
        kept = @test_logs load_log("declared")
        @test all(collect(kept.syslog.orient[1]) .≈ q_KA)
        set_data_path(data_path)
    end
    @testset "quat2viewer matches the KS reference implementation" begin
        for (roll, pitch, yaw) in attitudes
            q_KS = QuatRotation(euler2rot(roll, pitch, yaw))
            @test RotMatrix{3}(QuatRotation(quat2viewer(fromKS2KA(q_KS)))) ≈
                  RotMatrix{3}(QuatRotation(KiteUtils.quat2viewer_KS(q_KS)))
        end
    end
end
nothing
