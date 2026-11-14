```@meta
CurrentModule = KiteUtils
```

# Heading Angle

The **heading angle** $\psi$ describes the direction the nose of the kite is pointing, projected onto the plane tangential to the half-sphere at the kite's current position. That plane is spanned by the first two axes of the **Small Earth (SE) reference frame**.

The heading is a purely geometric angle: it depends on the attitude of the kite and on its position, never on the wind direction.

## Convention

- $\psi = 0$: the nose points up the sphere, towards zenith.
- $\psi > 0$: a right-handed rotation about the outward radial, the axis from the ground station through the kite. $\psi = \pi/2$ points the nose to the right as seen from the ground station, a clockwise turn in that view.

This is the same handedness as the azimuth, which turns anti-clockwise seen from above, a positive rotation about the up axis of ENU. The course angle ([`calc_course`](@ref)) uses the same convention for the direction of the velocity.

## Small Earth frame

At a kite position with elevation $\beta$ and azimuth $\varphi$ ([`azimuth_east`](@ref)), the SE axes, written in ENU, are

$$\mathbf{x}_\mathrm{SE} = \begin{pmatrix} -\sin\beta\cos\varphi \\ -\sin\beta\sin\varphi \\ \cos\beta \end{pmatrix}, \quad
\mathbf{y}_\mathrm{SE} = \begin{pmatrix} \sin\varphi \\ -\cos\varphi \\ 0 \end{pmatrix}, \quad
\mathbf{z}_\mathrm{SE} = \begin{pmatrix} \cos\beta\cos\varphi \\ \cos\beta\sin\varphi \\ \sin\beta \end{pmatrix}.$$

$\mathbf{x}_\mathrm{SE}$ points up the sphere towards zenith, $\mathbf{y}_\mathrm{SE}$ to the right seen from the ground station and $\mathbf{z}_\mathrm{SE}$ along the outward radial, so the frame is right-handed. [`fromW2SE`](@ref) applies this rotation. The same rotation takes a vector from the Wind frame when $\varphi$ is the wind-frame azimuth, since both frames have z up and measure their azimuth from their own x axis.

## Heading angle definition

The nose is the $-x$ axis of the `KA` attitude, already expressed in ENU: $\mathbf{h} = -R_\mathrm{KA}\,\mathbf{e}_x$. With $\mathbf{h}^\mathrm{SE}$ its components in the SE frame,

$$\boxed{\psi = \operatorname{atan2}\!\left(h^\mathrm{SE}_y,\; h^\mathrm{SE}_x\right)}$$

By default (`respos = true`) the result is wrapped to $[0,\, 2\pi)$; with `respos = false` it is returned in $(-\pi,\, \pi]$.

[`calc_heading`](@ref) also accepts the attitude as Euler angles (roll, pitch, yaw), which are `KS`, measured against NED, as the Xsens IMU reports them. The nose is then the `KS` $+x$ axis, rotated by the Euler angles into NED and from there into ENU; the result is the same angle for every attitude and kite position, which `test/test-frames.jl` asserts.

## Example

A kite east of the ground station, at elevation zero, with its nose pointing south:

```julia
using KiteUtils
attitude = [0.0 -1 0; 1 0 0; 0 0 1]       # KA columns: aft north, right tip west, up
calc_heading(attitude, 0.0, 0.0)          # π/2: nose to the right seen from the station
```
