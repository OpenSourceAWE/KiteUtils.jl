# unit tests for calculation of the orientation
using LinearAlgebra, Rotations, Test, StaticArrays
using KiteUtils

# Kite reference frame
# x: from trailing edge to leading edge
# y: to the right looking in flight direction
# z: down

# all coordinates are in ENU (East, North, Up) reference frame
# the orientation is calculated with respect to the NED (North, East, Down) reference frame

@testset verbose=true "test calc_orient_rot and co" begin
@testset "calc_orientation, kite pointing to the north and is at zenith" begin
    # If kite (x axis) is pointing to the north, and is at zenith, then in ENUs reference frame:
    # - x = 0, 1, 0
    # - y = 1, 0, 0
    # - z = 0, 0,-1
    # This would be equal to the NED reference frame.
    x = [0, 1, 0]
    y = [1, 0, 0]
    z = [0, 0,-1]
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll ≈ 0
    @test pitch ≈ 0
    @test yaw ≈ 0
end
@testset "calc_orientation, kite pointing to the west and is at zenith " begin
    x = [-1.0, 0.0, 0.0] # ENU, kite pointing to the west
    y = [0.0, 1.0, 0.0]  # ENU, right tip pointing to the north
    z = [0.0, 0.0, -1.0] # ENU, z axis pointing down
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll ≈ 0
    @test pitch ≈ 0
    @test yaw ≈ -90
end
@testset "calc_orientation, kite pointing to the north, right tip up   " begin
    # x = [0, 1, 0] y = [0, 0, 1] z = [1, 0, 0] should give -90 degrees roll
    x = [ 0, 1, 0]
    y = [ 0, 0, 1]
    z = [ 1, 0, 0]
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll ≈ -90
    @test pitch ≈ 0
    @test yaw ≈ 0
end
@testset "calc_orientation, kite pointing upwards, right tip eastwards " begin
    # If x, y and z are given in ENU
    # x = [0, 0, 1] y = [1, 0, 0] z = [0, 1, 0] should give 90 degrees pitch
    x = [ 0, 0, 1]  # nose pointing up
    y = [ 1, 0, 0]  # right tip pointing east
    z = [ 0, 1, 0]  # z axis pointing to the north
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll ≈ 0
    @test pitch ≈ 90
    @test yaw ≈ 0
end
@testset "calc_orientation, all angles positive                        " begin
    # x, y and z are given in ENU
    x = [0.29619813272602386, 0.8137976813493738, 0.49999999999999994]
    y = [0.8297694655894313, 0.0400087565481419, -0.5566703992264194]
    z = [-0.47302145844036114, 0.5797694655894312, -0.6634139481689384]
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll ≈ 40
    @test pitch ≈ 30
    @test yaw ≈ 20
end
@testset "calc_orientation, yaw = 20°                                  " begin
    # x, y and z are given in ENU
    x = [0.3420201433256687, 0.9396926207859084, 0.0]
    y = [0.9396926207859084, -0.3420201433256687, 0.0]
    z = [0.0, 0.0, -1.0]
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll  ≈ 0
    @test pitch ≈ 0
    @test yaw   ≈ 20
end
@testset "calc_orientation, pitch = 30°                                " begin
    # x, y and z are given in ENU
    x = [0.0, 0.8660254037844387, 0.49999999999999994]
    y = [1.0, 0.0, 0.0]
    z = [0.0, 0.49999999999999994, -0.8660254037844387]
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll  ≈ 0
    @test pitch ≈ 30.0
    @test yaw   ≈ 0
end
@testset "calc_orientation, yaw=20°, pitch = 30°                       " begin
    # x, y and z are given in ENU
    x = [0.29619813272602386, 0.8137976813493738, 0.49999999999999994]
    y = [0.9396926207859084, -0.3420201433256687, 0.0]
    z = [0.17101007166283433, 0.46984631039295416, -0.8660254037844387]
    
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll + 1  ≈ 0 + 1
    @test pitch     ≈ 30.0
    @test yaw       ≈ 20.0
end
@testset "calc_orientation, roll = 40°                                 " begin
    # x, y and z are given in ENU
    x = [0.0, 1.0, 0.0]
    y = [0.766044443118978, 0.0, -0.6427876096865393]
    z = [-0.6427876096865393, 0.0, -0.766044443118978]
    
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    roll, pitch, yaw = rad2deg.(quat2euler(q))
    @test roll       ≈ 40
    @test pitch+1    ≈ 0.0+1
    @test yaw+1      ≈ 0.0+1
end
@testset "quat2viewer                        " begin
    # x, y and z are given in ENU
    x = [0, 1, 0]
    y = [1, 0, 0]
    z = [0, 0,-1]
    
    @assert is_right_handed_orthonormal(x, y, z)
    rot = calc_orient_rot(x, y, z)
    q = QuatRotation(rot)
    q1 = quat2viewer(q)
    roll, pitch, yaw = rad2deg.(quat2euler(q1))
    @test roll ≈ 90
    @test pitch ≈ 0
    @test yaw ≈ 180
end
end
nothing
