```@meta
CurrentModule = KiteUtils
```
# Reference frames

**ENU world, `KA` body, everywhere. `KS` only at the edges.**

## Kinds of frame

A reference frame is an origin plus an axis convention.

**ENU** (East North Up) and **NED** (North East Down) name axis conventions. Either can be
placed at any origin, and the world frames below do exactly that.

A **world frame** is earth-fixed: its axes keep pointing the same way whatever the kite
does, so for our purposes it is an
[inertial frame](https://en.wikipedia.org/wiki/Inertial_frame_of_reference). Positions,
velocities, wind and forces drawn in space are expressed in one.

A **body frame** is rigidly attached to the kite and turns with it, so each of its axes
points somewhere different in the world at every instant. Aerodynamic forces and moments,
turn rates, angle of attack and side slip are expressed in one.

An **orientation** is the rotation from a body frame to a world frame; its columns are the
body axes written in world coordinates. Only the axis conventions enter it, not the origins.
Converting one therefore takes a rotation on both sides, which is what
[`convert_orientation`](@ref) does. [`convert_world`](@ref) and [`convert_body`](@ref)
rotate one side each and are for vectors.

## World frames

All three of the earth-fixed frames below share one origin, the tether exit point of the
ground station, and differ only by a rotation about the vertical.

The **ENU** (East North Up) reference frame is the simulation frame. Every position,
velocity and world-frame force is expressed in it. It is defined as follows:
- **x**: east
- **y**: north
- **z**: up

The **EG** (Earth Groundstation) reference frame is ENU turned a quarter turn about the
vertical. It is defined as follows:
- **x**: north
- **y**: west
- **z**: up

The **W** (Wind) reference frame is the frame the flight path controller works in. It is EG
turned further about the vertical so that one axis follows the wind, as shown in the figure
below. It is defined as follows:
- **x**: downwind
- **y**: cross-wind, to the left when looking downwind from above
- **z**: up

The **SE** (Small Earth) reference frame is the plane tangential to the unit half-sphere
around the ground station, touching it at the position of the kite. Unlike the three above
it is a rotating reference frame, following the kite. Its **x** axis points towards zenith,
which is why the heading is zero when the nose of the kite points up the sphere, its **z**
axis points from the kite back towards the ground station, and its **y** axis completes the
right-handed set.

The **NED** (North East Down) axis convention has no frame of its own here: nothing is
positioned in it. It exists only as the convention orientation angles are measured against,
because that is what the Xsens IMU reports, and in the code it is also called **EX** (Earth
Xsens). It is defined as follows:
- **x**: north
- **y**: east
- **z**: down

## Body frames

Two body-frame conventions occur in the OpenSourceAWE packages, and the enum
[`FrameConvention`](@ref) names them. Each is paired with the axis convention its
orientation is reported against: `KA` with ENU, `KS` with NED.

The **KA** (kite aero) reference frame is the convention of `SysState` and of every
calculation in this package. Like `KS` it is a rotating reference frame, and its origin is
a free per-model choice. It is defined as follows:
- **x**: from leading edge to trailing edge
- **y**: spanwise, from the left to the right wing tip
- **z**: up

These are the aerodynamic axes, so drag is +x, side force +y and lift +z, and at zenith
they line up with ENU. Any package may assume the sense `x · (TE − LE) > 0` with y
spanwise positive. A geometry authored the other way round inverts the aerodynamics rather
than relabelling them, so the sense is a requirement and not a preference.

The **KS** (kite sensor) reference frame is the sensor-fixed reference frame, reported
against NED because that is the convention the Xsens IMU reports in. Its origin is defined
by the location where the sensor is mounted. In the simulation this is equal to the **K**
(kite) reference frame, which is defined as follows:
- **x**: from trailing edge to leading edge
- **y**: to the right looking in flight direction
- **z**: down

`KS` survives in three places and nowhere else:

- inside `KiteModels`, whose solver and aerodynamics are built on it;
- in the `roll`, `pitch` and `yaw` angles, which are reported against NED because that is
  what the sensors deliver and the flight controllers expect;
- at sensor ingest.

Everywhere else, converting is a call to [`convert_world`](@ref), [`convert_body`](@ref) or
[`convert_orientation`](@ref), chosen by the kind of quantity: a world vector takes the
world rotation, a body vector the body rotation, an orientation one on each side.
`enu2ned()` and `ned2enu()` remain available for plain world vectors.

### The neighbouring packages

| package                 | body frame            | established by                       |
|:------------------------|:----------------------|:-------------------------------------|
| SymbolicAWEModels.jl    | `KA`                  | computed from both shipped kites     |
| ASKITE                  | `KA`-shaped geometry  | CAD identical to V3Kite.jl's         |
| KiteModels.jl           | `KS`                  | `kite_ref_frame`, z down the tether  |
| EKF-AWE                 | forward x, ENU world  | `postprocess/postprocessing.py`      |
| AWETrim                 | undocumented          | needs reading or asking              |

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
For the orientation, either a quaternion or roll, pitch and yaw angles are used.

Quaternions stored in `SysState` are `KA`: the body-to-ENU rotation of the aft-right-up
body frame. Its columns are the body axes expressed in ENU, so `-x` is the nose, which is
what [`kite_nose`](@ref) returns and what `calc_heading()` and `calc_clock_angle()` are
built on. It is the only orientation the state carries.

Roll, pitch and yaw are not stored. [`euler_ks`](@ref)`(ss.orient)` reports them, measured
against NED, that being the convention of the Xsens IMU and of flight test data. Yaw is
zero at north, clockwise positive seen from above. The function `quat2euler()` expects a
`KS` quaternion, so it is only correct on the result of
`convert_orientation(q; from=KA, to=KS)`.

The origin the kite rotates about is a per-model choice and does not affect the
orientation. For the four-point model it is the centre point $0.5 * (C + D)$, where C and D
are the point masses close to the wing tips.

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

In Fig. 5.1 the vectors $x_k, y_k$ and $z_k$ define the body-fixed kite reference frame
in the `KS` convention. In this
chapter, the combination of the wing and the kite control unit (KCU) is seen as kite.
The $y_k$ axis is defined by the vector from the left to the right wing tip, the $z_k$ axis is
pointing downwards from the position of the kite parallel to the upper part of the tether,
and the $x_k$ axis is orthogonal to $y_k$ and $z_k$ . The heading angle ψ is the angle between the
direction towards zenith and the vector $x_k$ as projected on the tangential plane touching
the position of the kite on the half sphere. If tether is not straight, $z_k$ and $z_{SE}$ are not
aligned.

Fechner U. A Methodology for the Design of Kite-Power Control Systems. 2016. 212 p. https://doi.org/10.4233/uuid:85efaf4c-9dce-4111-bc91-7171b9da4b77