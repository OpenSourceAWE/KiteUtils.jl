# SPDX-FileCopyrightText: 2024 Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils
using Test, StaticArrays, Rotations

@testset verbose=true "InertialFrame enum" begin
    @test NED isa InertialFrame
    @test ENU isa InertialFrame
    @test NWU isa InertialFrame
    @test NED != ENU
    @test NED != NWU
    @test ENU != NWU
end

@testset verbose=true "euler_enu2ned / euler_ned2enu" begin
    @testset "round-trip enu→ned→enu" begin
        r0, p0, y0 = 0.3, 0.5, 0.7
        rn, pn, yn = euler_enu2ned(r0, p0, y0)
        re, pe, ye = euler_ned2enu(rn, pn, yn)
        @test re ≈ r0 atol=1e-10
        @test pe ≈ p0 atol=1e-10
        @test ye ≈ y0 atol=1e-10
    end

    @testset "round-trip ned→enu→ned" begin
        r0, p0, y0 = 0.4, 0.2, -0.6
        re, pe, ye = euler_ned2enu(r0, p0, y0)
        rn, pn, yn = euler_enu2ned(re, pe, ye)
        @test rn ≈ r0 atol=1e-10
        @test pn ≈ p0 atol=1e-10
        @test yn ≈ y0 atol=1e-10
    end

    @testset "physical consistency via rotation matrix" begin
        # Same physical rotation described in ENU and NED
        # should satisfy R_NED = T * R_ENU
        T = @SMatrix[0 1 0; 1 0 0; 0 0 -1]
        for (re, pe, ye) in [(0.3, 0.5, 0.7),
                             (0.0, 0.0, 0.0),
                             (π/4, 0.0, 0.0),
                             (0.0, π/4, 0.0),
                             (0.0, 0.0, π/2)]
            rn, pn, yn = euler_enu2ned(re, pe, ye)
            R_enu = euler2rot(re, pe, ye)
            R_ned = euler2rot(rn, pn, yn)
            @test R_ned ≈ T * R_enu atol=1e-10
        end
    end
end

@testset verbose=true "fromKS2EX orientation_frame" begin
    vec = SVector(1.0, 2.0, 3.0)
    orient_ned = SVector(0.0, π/10, π/2)
    orient_enu = collect(euler_ned2enu(orient_ned...))

    result_ned = fromKS2EX(vec, orient_ned;
                           orientation_frame=NED)
    result_enu = fromKS2EX(vec, orient_enu;
                           orientation_frame=ENU)

    # Both represent the same physical rotation.
    # Convert ENU result to NED to compare.
    result_enu_as_ned = enu2ned(result_enu)
    @test all(result_ned .≈ result_enu_as_ned)
end

@testset verbose=true "frame_transform" begin
    v = SVector(1.0, 2.0, 3.0)
    # Identity
    @test frame_transform(ENU, ENU) * v == v
    @test frame_transform(NED, NED) * v == v
    @test frame_transform(NWU, NWU) * v == v
    # Round-trip: any frame→other→back = identity
    for (a, b) in [(ENU, NED), (ENU, NWU), (NED, NWU)]
        T_ab = frame_transform(a, b)
        T_ba = frame_transform(b, a)
        @test T_ba * T_ab * v ≈ v
    end
    # Known values
    # ENU [E,N,U] → NED [N,E,D]: (1,2,3)→(2,1,-3)
    @test frame_transform(ENU, NED) * v ==
          SVector(2.0, 1.0, -3.0)
    # ENU [E,N,U] → NWU [N,W,U]: (1,2,3)→(2,-1,3)
    @test frame_transform(ENU, NWU) * v ==
          SVector(2.0, -1.0, 3.0)
    # NED [N,E,D] → NWU [N,W,U]: (1,2,3)→(1,-2,-3)
    @test frame_transform(NED, NWU) * v ==
          SVector(1.0, -2.0, -3.0)
end

@testset verbose=true "euler_convert with NWU" begin
    @testset "round-trip all frame pairs" begin
        r0, p0, y0 = 0.3, 0.5, 0.7
        for (a, b) in [(ENU, NWU), (NED, NWU),
                       (ENU, NED)]
            rb, pb, yb = euler_convert(r0, p0, y0, a, b)
            ra, pa, ya = euler_convert(rb, pb, yb, b, a)
            @test ra ≈ r0 atol=1e-10
            @test pa ≈ p0 atol=1e-10
            @test ya ≈ y0 atol=1e-10
        end
    end

    @testset "physical consistency NWU↔ENU" begin
        T = frame_transform(ENU, NWU)
        for (re, pe, ye) in [(0.3, 0.5, 0.7),
                             (0.0, 0.0, 0.0),
                             (π/4, 0.0, 0.0)]
            rn, pn, yn = euler_convert(
                re, pe, ye, ENU, NWU)
            R_enu = euler2rot(re, pe, ye)
            R_nwu = euler2rot(rn, pn, yn)
            @test R_nwu ≈ T * R_enu atol=1e-10
        end
    end
end

@testset verbose=true "backward compatibility" begin
    # calc_orient_rot with ENU=true should still work
    x = [0, 1, 0]
    y = [1, 0, 0]
    z = [0, 0, -1]
    rot_old = calc_orient_rot(x, y, z; ENU=true)
    rot_ned = calc_orient_rot(
        enu2ned(x), enu2ned(y), enu2ned(z);
        orientation_frame=NED)
    @test rot_old ≈ rot_ned
end
