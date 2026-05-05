```@meta
CurrentModule = KiteUtils
```
# Reference frames

## Position and velocity
For position and velocity vectors of the model the **ENU** (East North Up) reference frame is used.

The controller is using the **W** (Wind) reference frame as shown in the figure below, y-axis downwind and z-axis up.

The orientation of the kite is expressed with respect to the **NED** (North, East, Down)
reference frame. In the code this frame is also called **EX** (Earth Xsens), because the
Xsens IMU reports orientation in NED. Since the rest of the codebase uses ENU for
positions and velocities, the helper functions `enu2ned()` and `ned2enu()` are provided
to convert vectors between the two frames.

The **KS** (kite sensor) reference frame is the sensor-fixed reference frame. The origin
is defined by the location where the sensor is mounted. This is a rotating reference
frame. Currently, in the simulation, this is equal to the **K** (kite) reference frame,
which is defined as follows:
- **x**: from trailing edge to leading edge
- **y**: to the right looking in flight direction
- **z**: down

Other reference frames are the **EG** (North West Up), and the **SE** (small earth)
reference frames which is defined in the plane tangential to the half-sphere with a unit
radius and the origin at the tether exit point of the ground-station.

## Wind direction
The `upwind_dir` (degrees) is the direction the wind is coming from. Zero is at north; clockwise positive.
Default: `-90`, wind from west.

The `upwind_elevation` (degrees) is the angle between the upwind direction and the east-north plane (ENU frame).
Default: `0`, horizontal wind.

## Elevation and azimuth
The position of the kite can be described with two angles, the azimuth angle φ and the elevation angle β .The elevation angle is zero when the height of the kite is zero, and 90° when it is at Zenith.
Three azimuth angles are used, the azimuth angle in the wind reference frame and $\mathrm{azimuth\_east}$ and $\mathrm{azimuth\_north}$. The azimuth angles in wind reference frame and $\mathrm{azimuth\_north}$ are defined positive anti-clockwise when seen from above, $\mathrm{azimuth\_east}$ is defined positive clockwise when seen from above. In the log file and the system state $\mathrm{azimuth}$ in wind reference frame is used (for KiteUtils 0.8.2 and higher).

The functions `calc_heading()` and `calc_clock_angle()` both use this same wind-frame azimuth convention.

## Orientation of the kite
For the orientation, either a quaternion or roll, pitch and yaw angles are used. The
orientation is defined with respect to the NED reference frame (see above), because
that is the convention used by the Xsens IMU. Quaternions and Euler angles stored in
`SysState.orient` follow this NED convention. The function `quat2euler()` expects a
NED-based quaternion as input.

The origin of the kite reference frame around which it rotates is the centre point
defined as $0.5 * (C + D)$, where C and D are positions of the point masses of the
model close to the tips of the wing.
- yaw angle: zero north, clockwise positive as seen from above

## Control inputs
see: [Reference frames and control inputs](https://ufechner7.github.io/KiteModels.jl/dev/#Reference-frames-and-control-inputs)

## Small earth reference frame

To understand how the control system is working it is necessary to introduce the small
earth reference frame. This name is chosen as an analogy to the geographic coordinate
system, describing a position on planet earth: It makes clear to the reader that navigation
methods, used on earth (like great circle navigation to find the shortest way between two
points on the sphere) can also be used to navigate kites. The position of the kite and
the ground station are measured in the "Earth Centered Earth Fixed" reference frame.
The position of the kite relative to the ground station has to be converted into the "Wind
Reference Frame" ($x_w , y_w , z_w$) as shown in Fig. 5.1. 

The origin of the wind reference
frame is placed at the anchor point of the tether and its $x_w$ axis is always pointing in
the direction of the averaged wind velocity. To obtain the coordinates of the kite in the
small earth reference frame its position is projected on the unit sphere around the origin
of the wind reference frame. Now, the position of the kite can be described with two
angles, the azimuth angle φ and the elevation angle β . The movement of the kite in the
direction of the tether is determined by the winch controller and can be ignored by the
kite controller. The objective of the flight path controller as described in this thesis is to
fly the kite on a prescribed trajectory that is adapted to the wind conditions.

![Small earth reference frame](small_earth.png)

In Fig. 5.1 the vectors $x_k, y_k$ and $z_k$ define the body-fixed kite reference frame. In this
chapter, the combination of the wing and the kite control unit (KCU) is seen as kite.
The $y_k$ axis is defined by the vector from the left to the right wing tip, the $z_k$ axis is
pointing downwards from the position of the kite parallel to the upper part of the tether,
and the $x_k$ axis is orthogonal to $y_k$ and $z_k$ . The heading angle ψ is the angle between the
direction towards zenith and the vector $x_k$ as projected on the tangential plane touching
the position of the kite on the half sphere. If tether is not straight, $z_k$ and $z_{SE}$ are not
aligned.

Fechner U. A Methodology for the Design of Kite-Power Control Systems. 2016. 212 p. https://doi.org/10.4233/uuid:85efaf4c-9dce-4111-bc91-7171b9da4b77