# SPDX-FileCopyrightText: 2025 Bart van de Lint
# SPDX-License-Identifier: MIT

using LinearAlgebra

@testset verbose=true "KiteUtils.jl: SystemStructure" begin

    @testset "Point constructor" begin
        # Test basic Point constructor with regular Int
        pos_cad = KVec3(1.0, 2.0, 3.0)
        p = Point(1, pos_cad, DYNAMIC; mass=5.0)

        @test p.idx == 1
        @test p.type == DYNAMIC
        @test p.mass == 5.0
        @test p.pos_cad == pos_cad
        @test p.vel_w == zeros(KVec3)
        @test p.bridle_damping == 0.0
        @test p.fix_sphere == false

        # Test with different DynamicsType
        p_static = Point(2, pos_cad, STATIC; mass=10.0)
        @test p_static.type == STATIC
        @test p_static.mass == 10.0

        p_qs = Point(3, pos_cad, QUASI_STATIC)
        @test p_qs.type == QUASI_STATIC

        p_wing = Point(4, pos_cad, WING; wing_idx=2)
        @test p_wing.type == WING
        @test p_wing.wing_idx == 2

        # Test with optional parameters
        vel = KVec3(1.0, 0.0, 0.0)
        p_vel = Point(5, pos_cad, DYNAMIC; vel_w=vel, bridle_damping=0.5, fix_sphere=true)
        @test p_vel.vel_w == vel
        @test p_vel.bridle_damping == 0.5
        @test p_vel.fix_sphere == true
    end

    @testset "Group constructor" begin
        point_idxs = [1, 2, 3, 4]  # Regular Int array
        le_pos = KVec3(0.0, 0.0, 0.0)
        chord = KVec3(1.0, 0.0, 0.0)
        y_airf = KVec3(0.0, 1.0, 0.0)

        g = Group(1, point_idxs, le_pos, chord, y_airf, DYNAMIC, 0.25)

        @test g.idx == 1
        @test g.le_pos == le_pos
        @test g.chord == chord
        @test g.y_airf == y_airf
        @test g.type == DYNAMIC
        @test g.moment_frac == 0.25
        @test g.damping == 50.0  # default value
        @test g.twist == 0.0
        @test g.twist_ω == 0.0

        # Test with custom damping
        g2 = Group(2, point_idxs, le_pos, chord, y_airf, QUASI_STATIC, 0.5; damping=100.0)
        @test g2.damping == 100.0
        @test g2.type == QUASI_STATIC
    end

    @testset "Segment constructor with Settings" begin
        set = se()
        point_idxs = (1, 2)  # Regular Int tuple

        # Test BRIDLE segment
        seg_bridle = Segment(1, set, point_idxs, BRIDLE; l0=1.0)
        @test seg_bridle.idx == 1
        @test seg_bridle.l0 == 1.0
        @test seg_bridle.diameter ≈ 0.001 * set.bridle_tether_diameter
        @test seg_bridle.compression_frac == 0.0

        # Test POWER_LINE segment
        seg_power = Segment(2, set, point_idxs, POWER_LINE; l0=2.0)
        @test seg_power.diameter ≈ 0.001 * set.power_tether_diameter

        # Test STEERING_LINE segment
        seg_steering = Segment(3, set, point_idxs, STEERING_LINE; l0=3.0)
        @test seg_steering.diameter ≈ 0.001 * set.steering_tether_diameter

        # Test with custom stiffness and damping
        seg_custom = Segment(4, set, point_idxs, POWER_LINE;
                            l0=1.5, axial_stiffness=1000.0, axial_damping=50.0)
        @test seg_custom.axial_stiffness == 1000.0
        @test seg_custom.axial_damping == 50.0

        # Test with compression fraction
        seg_comp = Segment(5, set, point_idxs, BRIDLE; compression_frac=0.1)
        @test seg_comp.compression_frac == 0.1
    end

    @testset "Segment constructor without Settings" begin
        point_idxs = (1, 2)  # Regular Int tuple
        seg = Segment(1, point_idxs, 1000.0, 50.0, 0.004; l0=1.5, compression_frac=0.1)

        @test seg.idx == 1
        @test seg.axial_stiffness == 1000.0
        @test seg.axial_damping == 50.0
        @test seg.diameter == 0.004
        @test seg.l0 == 1.5
        @test seg.compression_frac == 0.1
        @test seg.len == 0.0
        @test seg.force == 0.0
    end

    @testset "Pulley constructor" begin
        segment_idxs = (1, 2)  # Regular Int tuple

        # Test DYNAMIC pulley
        p_dyn = Pulley(1, segment_idxs, DYNAMIC)
        @test p_dyn.idx == 1
        @test p_dyn.type == DYNAMIC
        @test p_dyn.sum_len == 0.0
        @test p_dyn.len == 0.0
        @test p_dyn.vel == 0.0

        # Test QUASI_STATIC pulley
        p_qs = Pulley(2, segment_idxs, QUASI_STATIC)
        @test p_qs.type == QUASI_STATIC
    end

    @testset "Tether constructor" begin
        segment_idxs = [1, 2, 3]  # Regular Int array
        t = Tether(1, segment_idxs, 1)

        @test t.idx == 1
        @test t.winch_idx == 1
        @test t.stretched_len == 0.0
    end

    @testset "Winch constructor with Settings" begin
        set = se()
        tether_idxs = [1, 2]  # Regular Int array

        w = Winch(1, set, tether_idxs; tether_len=50.0, tether_vel=0.5, brake=false)

        @test w.idx == 1
        @test w.tether_len == 50.0
        @test w.tether_vel == 0.5
        @test w.tether_acc == 0.0
        @test w.brake == false
        @test w.gear_ratio == set.gear_ratio
        @test w.drum_radius == set.drum_radius
        @test w.f_coulomb == set.f_coulomb
        @test w.c_vf == set.c_vf
        @test w.inertia_total == set.inertia_total

        # Test with brake engaged
        w_brake = Winch(2, set, tether_idxs; brake=true)
        @test w_brake.brake == true
    end

    @testset "Winch constructor without Settings" begin
        tether_idxs = [1]  # Regular Int array
        w = Winch(1, tether_idxs, 10.0, 0.5, 100.0, 0.1, 5.0;
                 tether_len=100.0, tether_vel=1.0, brake=true)

        @test w.idx == 1
        @test w.gear_ratio == 10.0
        @test w.drum_radius == 0.5
        @test w.f_coulomb == 100.0
        @test w.c_vf == 0.1
        @test w.inertia_total == 5.0
        @test w.tether_len == 100.0
        @test w.tether_vel == 1.0
        @test w.brake == true
    end

    @testset "BaseWing constructor and quaternion conversion" begin
        group_idxs = [1, 2, 3]  # Regular Int array
        R_b_c = Matrix{SimFloat}(I, 3, 3)
        pos_cad = KVec3(0.0, 0.0, 0.0)

        wing = BaseWing(1, group_idxs, R_b_c, pos_cad; y_damping=150.0)

        @test wing.idx == 1
        @test wing.R_b_c == R_b_c
        @test wing.pos_cad == pos_cad
        @test wing.y_damping == 150.0
        @test wing.fix_sphere == false

        # Test quaternion initialization (should be identity)
        @test length(wing.Q_b_w) == 4

        # Test R_b_w property getter (quaternion to rotation matrix)
        R = wing.R_b_w
        @test size(R) == (3, 3)

        # Test R_b_w property setter (rotation matrix to quaternion)
        # Create a rotation matrix for 90 degrees around z-axis
        theta = pi/2
        R_test = [cos(theta) -sin(theta) 0.0;
                  sin(theta)  cos(theta) 0.0;
                  0.0         0.0        1.0]
        wing.R_b_w = R_test

        # Get it back and check it's approximately the same
        R_back = wing.R_b_w
        @test isapprox(R_back, R_test, atol=1e-10)
    end

    @testset "Transform constructor" begin
        elevation = deg2rad(45.0)
        azimuth = deg2rad(30.0)
        heading = deg2rad(10.0)
        base_pos = KVec3(0.0, 0.0, 0.0)

        # Test with wing_idx and base_pos using regular Int
        t1 = Transform(1, elevation, azimuth, heading;
                      wing_idx=1, base_pos=base_pos, base_point_idx=1)
        @test t1.idx == 1
        @test t1.elevation == elevation
        @test t1.azimuth == azimuth
        @test t1.heading == heading
        @test t1.wing_idx == 1
        @test isnothing(t1.rot_point_idx)
        @test t1.base_pos == base_pos
        @test t1.base_point_idx == 1

        # Test with rot_point_idx
        t2 = Transform(2, elevation, azimuth, heading;
                      rot_point_idx=5, base_pos=base_pos, base_point_idx=1)
        @test t2.rot_point_idx == 5
        @test isnothing(t2.wing_idx)

        # Test with base_transform_idx
        t3 = Transform(3, elevation, azimuth, heading;
                      wing_idx=1, base_transform_idx=1)
        @test t3.base_transform_idx == 1
        @test isnothing(t3.base_pos)

        # Test error cases
        @test_throws ErrorException Transform(4, elevation, azimuth, heading;
                                              base_pos=base_pos, base_point_idx=1)  # no wing or point
        @test_throws ErrorException Transform(5, elevation, azimuth, heading;
                                              wing_idx=1, rot_point_idx=1,
                                              base_pos=base_pos, base_point_idx=1)  # both wing and point
    end

    @testset "Transform constructor with Settings" begin
        set = se()
        # Make sure we have elevation/azimuth/heading arrays
        if length(set.elevations) == 0
            set.elevations = [70.8]
            set.azimuths = [0.0]
            set.headings = [0.0]
        end

        base_pos = KVec3(0.0, 0.0, 0.0)
        t = Transform(1, set; base_point_idx=1, wing_idx=1, base_pos=base_pos)

        @test t.idx == 1
        @test t.elevation ≈ deg2rad(set.elevations[1])
        @test t.azimuth ≈ deg2rad(set.azimuths[1])
        @test t.heading ≈ deg2rad(set.headings[1])
        @test t.base_point_idx == 1
        @test t.wing_idx == 1
        @test t.base_pos ≈ base_pos
    end

    @testset "SystemStructure constructor" begin
        set = se()

        # Create minimal system using regular Int
        points = [
            Point(1, KVec3(0.0, 0.0, 0.0), STATIC),
            Point(2, KVec3(1.0, 0.0, 0.0), DYNAMIC; mass=1.0)
        ]

        segments = [
            Segment(1, (1, 2), 1000.0, 50.0, 0.004; l0=0.0)
        ]

        tethers = [
            Tether(1, [1], 1)
        ]

        winches = [
            Winch(1, [1], 10.0, 0.5, 100.0, 0.1, 5.0)
        ]

        transforms = [
            Transform(1, 0.0, 0.0, 0.0;
                     wing_idx=nothing, rot_point_idx=1,
                     base_pos=KVec3(0.0, 0.0, 0.0), base_point_idx=1)
        ]

        sys = SystemStructure("test_system", set;
                             points=points,
                             segments=segments,
                             tethers=tethers,
                             winches=winches,
                             transforms=transforms)

        @test sys.name == "test_system"
        @test sys.set === set
        @test length(sys.points) == 2
        @test length(sys.segments) == 1
        @test length(sys.tethers) == 1
        @test length(sys.winches) == 1
        @test length(sys.transforms) == 1
        @test sys.stabilize == false
        @test sys.fix_wing == false

        # Check that segment l0 was auto-calculated from point positions
        @test segments[1].l0 ≈ 1.0

        # Check that winch tether_len was auto-calculated
        @test winches[1].tether_len ≈ 1.0

        # Check that transform angles were written back to settings
        @test set.elevations[1] ≈ rad2deg(transforms[1].elevation)
        @test set.azimuths[1] ≈ rad2deg(transforms[1].azimuth)
        @test set.headings[1] ≈ rad2deg(transforms[1].heading)
    end

    @testset "SystemStructure with wings and groups" begin
        set = se()

        # Using regular Int throughout
        points = [
            Point(1, KVec3(0.0, 0.0, 0.0), STATIC),
            Point(2, KVec3(1.0, 0.0, 0.0), WING; wing_idx=1),
            Point(3, KVec3(1.5, 0.5, 0.0), WING; wing_idx=1),
            Point(4, KVec3(1.5, -0.5, 0.0), WING; wing_idx=1)
        ]

        groups = [
            Group(1, [2, 3, 4],
                  KVec3(1.0, 0.0, 0.0), KVec3(1.0, 0.0, 0.0), KVec3(0.0, 1.0, 0.0),
                  DYNAMIC, 0.25)
        ]

        wings = [
            BaseWing(1, [1], Matrix{SimFloat}(I, 3, 3), KVec3(0.0, 0.0, 0.0))
        ]

        transforms = [
            Transform(1, 0.0, 0.0, 0.0;
                     wing_idx=1, base_pos=KVec3(0.0, 0.0, 0.0), base_point_idx=1)
        ]

        sys = SystemStructure("test_with_wings", set;
                             points=points,
                             groups=groups,
                             wings=wings,
                             transforms=transforms)

        @test length(sys.wings) == 1
        @test length(sys.groups) == 1

        # Check that y, x, and jac arrays were properly sized
        ny = 3 + length(wings[1].group_idxs) + 3
        nx = 3 + 3 + length(wings[1].group_idxs)
        @test size(sys.y) == (length(wings), ny)
        @test size(sys.x) == (length(wings), nx)
        @test size(sys.jac) == (length(wings), nx, ny)
    end

    @testset "Enumerations" begin
        # Test SegmentType enum
        @test Int(POWER_LINE) == 0
        @test Int(STEERING_LINE) == 1
        @test Int(BRIDLE) == 2

        # Test DynamicsType enum
        @test Int(DYNAMIC) == 0
        @test Int(QUASI_STATIC) == 1
        @test Int(WING) == 2
        @test Int(STATIC) == 3
    end

    @testset "Quaternion/Rotation conversion functions" begin
        # Test identity quaternion
        q_identity = [1.0, 0.0, 0.0, 0.0]
        R_identity = KiteUtils.quaternion_to_rotation_matrix(q_identity)
        @test isapprox(R_identity, Matrix{SimFloat}(I, 3, 3), atol=1e-10)

        # Test quaternion -> rotation -> quaternion round trip
        q_test = normalize([1.0, 0.5, 0.3, 0.2])
        R_test = KiteUtils.quaternion_to_rotation_matrix(q_test)
        q_back = KiteUtils.rotation_matrix_to_quaternion(R_test)
        # Quaternions q and -q represent the same rotation
        @test isapprox(q_back, q_test, atol=1e-10) || isapprox(q_back, -q_test, atol=1e-10)

        # Test rotation matrix -> quaternion -> rotation round trip
        theta = pi/4
        R_rot = [cos(theta) -sin(theta) 0.0;
                 sin(theta)  cos(theta) 0.0;
                 0.0         0.0        1.0]
        q_rot = KiteUtils.rotation_matrix_to_quaternion(R_rot)
        R_back = KiteUtils.quaternion_to_rotation_matrix(q_rot)
        @test isapprox(R_back, R_rot, atol=1e-10)

        # Test that rotation matrix is orthonormal
        @test isapprox(R_back * R_back', Matrix{SimFloat}(I, 3, 3), atol=1e-10)
        @test isapprox(det(R_back), 1.0, atol=1e-10)
    end

end
