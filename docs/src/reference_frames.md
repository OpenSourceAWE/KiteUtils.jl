```@meta
CurrentModule = KiteUtils
```
# Reference frames

**ENU world, `KA` body, everywhere. `KS` only at the edges.**

## What a reference frame is here

Every vector in this package is expressed in one of two kinds of frame.

- A **world frame** is earth-fixed: its axes keep pointing the same way whatever the kite
  does, so for our purposes it is an
  [inertial frame](https://en.wikipedia.org/wiki/Inertial_frame_of_reference). Positions,
  velocities, wind and forces drawn in space live here.
- A **body frame** is rigidly attached to the kite and turns with it, so each of its axes
  points somewhere different in the world at every instant. Aerodynamic forces and moments,
  turn rates, angle of attack and side slip live here.

An **orientation** is the rotation from a body frame to a world frame: its columns are the
body axes written in world coordinates. That is why an orientation cannot be converted like
a vector. Changing the body convention *and* the world convention means rotating it on both
sides, which is what [`convert_orientation`](@ref) does and
[`convert_world`](@ref)/[`convert_body`](@ref) deliberately do not.

One line per frame:

- **ENU** — world. x east, y north, z up. Every position, velocity and world-frame force.
- **NED**, in the code **EX** (Earth Xsens) — world. x north, y east, z down. Used only as
  the frame `roll`, `pitch` and `yaw` are measured against, that being what the IMU reports.
- **EG** (Earth Ground station) — world. x north, y west, z up.
- **W** (Wind) — world. ENU turned so that y points downwind, z up. The flight path
  controller works here.
- **SE** (Small Earth) — world. The plane tangential to the unit half-sphere at the kite,
  origin at the tether exit point of the ground station.
- **KA** (kite aero) — body. x leading to trailing edge, y left tip to right tip, z up.
- **KS** (kite sensor) — body. x trailing to leading edge, y right, z down.

## Body frames

Two body-frame conventions occur in the OpenSourceAWE packages, and the enum
[`FrameConvention`](@ref) names them. Each comes paired with the world frame its
orientation is reported against: `KA` with ENU, `KS` with NED.

**`KA`** is the convention of `SysState` and of every calculation in this package:

- **x**: from leading edge to trailing edge
- **y**: spanwise, from the left to the right wing tip
- **z**: up

These are the aerodynamic axes, so drag is +x, side force +y and lift +z, and at zenith
they line up with ENU. Any package may assume the sense `x · (TE − LE) > 0` with y
spanwise positive; a geometry authored the other way round does not merely relabel the
aerodynamics, it inverts them. The origin is a free per-model choice — it does not enter a
rotation — but it must be documented per model.

**`KS`** is the sensor-fixed frame: **x** from trailing edge to leading edge, **y** to the
right looking in flight direction, **z** down, reported against NED because that is the
convention the Xsens IMU reports in. `KS` survives in three places and nowhere else:

- inside `KiteModels`, whose solver and aerodynamics are built on it;
- in the `roll`, `pitch` and `yaw` angles, which are reported against NED because that is
  what the sensors deliver and the flight controllers expect;
- at sensor ingest.

Everywhere else, converting is a call to [`convert_world`](@ref), [`convert_body`](@ref) or
[`convert_orientation`](@ref). The three are not interchangeable: a world vector takes the
world rotation, a body vector the body rotation, and an orientation — being a body-to-world
rotation — takes one on each side. `enu2ned()` and `ned2enu()` remain available for plain
world vectors.

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
built on.

Roll, pitch and yaw are `KS`: measured against NED, because that is the convention of the
Xsens IMU and of the flight controllers. [`euler_ks`](@ref) reports them from a `KA`
attitude. The function `quat2euler()` expects a `KS` quaternion as input, so it is only
correct on the result of `convert_orientation(q; from=KA, to=KS)`.

- yaw angle: zero north, clockwise positive as seen from above

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