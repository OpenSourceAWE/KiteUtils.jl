```@meta
CurrentModule = KiteUtils
```

# Heading Angle

The **heading angle** $\psi$ describes the direction the nose of the kite is pointing,
projected onto the plane tangential to the half-sphere at the kite's current position.
This projection plane is the **Small Earth (SE) reference frame**.

## Coordinate frames involved

| Frame | Abbrev. | Convention |
|-------|---------|------------|
| Kite Sensor | **KS** | $x$: trailing → leading edge; $y$: right wing; $z$: down |
| Earth Xsens (NED) | **EX** | $x$: North; $y$: East; $z$: Down |
| Earth Groundstation | **EG** | $x$: North; $y$: West; $z$: Up |
| Wind | **W** | $x$: upwind; $y$: downwind; $z$: Up |
| Small Earth | **SE** | tangential to unit sphere at kite's position |

## Transformation chain

The heading vector starts as the unit vector along the kite's nose in the **KS** frame,

$$\mathbf{h}^\mathrm{KS} = \begin{pmatrix} 1 \\ 0 \\ 0 \end{pmatrix},$$

and is then transformed through four frames until it reaches **SE**, where the heading angle is read off.

### Step 1 — KS → EX (NED):  apply Euler angles

Given the kite orientation as Euler angles $(\phi, \theta, \psi_\mathrm{NED})$ (roll, pitch, yaw)
defined with respect to the NED reference frame:

$$R_\mathrm{roll} =
\begin{pmatrix}
1 & 0 & 0 \\
0 & \cos\phi & -\sin\phi \\
0 & \sin\phi & \cos\phi
\end{pmatrix}, \quad
R_\mathrm{pitch} =
\begin{pmatrix}
\cos\theta & 0 & \sin\theta \\
0 & 1 & 0 \\
-\sin\theta & 0 & \cos\theta
\end{pmatrix}, \quad
R_\mathrm{yaw} =
\begin{pmatrix}
\cos\psi_\mathrm{NED} & -\sin\psi_\mathrm{NED} & 0 \\
\sin\psi_\mathrm{NED} & \cos\psi_\mathrm{NED} & 0 \\
0 & 0 & 1
\end{pmatrix}$$

The combined rotation applied in yaw → pitch → roll order gives

$$\mathbf{h}^\mathrm{EX} = R_\mathrm{yaw}\, R_\mathrm{pitch}\, R_\mathrm{roll}\, \mathbf{h}^\mathrm{KS}.$$

### Step 2 — EX → EG:  NED to North-West-Up

The EG frame shares the North axis ($x$) with NED but flips both $y$ (East → West) and $z$ (Down → Up):

$$R_\mathrm{EX \to EG} =
\begin{pmatrix}
1 &  0 &  0 \\
0 & -1 &  0 \\
0 &  0 & -1
\end{pmatrix}, \qquad
\mathbf{h}^\mathrm{EG} = R_\mathrm{EX \to EG}\, \mathbf{h}^\mathrm{EX}.$$

### Step 3 — EG → W:  rotate into Wind frame

Let $\alpha$ be the **down-wind direction** (the direction the wind is blowing *towards*),
measured in the EG frame as an angle from North, positive clockwise from above.
It is related to the configurable `upwind_dir` by $\alpha = \mathrm{upwind\_dir} + \pi$.

$$R_\mathrm{EG \to W}(\alpha) =
\begin{pmatrix}
\cos\alpha & -\sin\alpha & 0 \\
\sin\alpha &  \cos\alpha & 0 \\
0          &  0          & 1
\end{pmatrix}, \qquad
\mathbf{h}^\mathrm{W} = R_\mathrm{EG \to W}(\alpha)\, \mathbf{h}^\mathrm{EG}.$$

### Step 4 — W → SE:  project onto the tangential sphere plane

Given the kite's **elevation angle** $\beta$ and **azimuth angle** $\varphi$ (in the wind
reference frame), the transformation to the Small Earth frame consists of three successive
rotations:

$$R_\mathrm{first} =
\begin{pmatrix}
 0 & 0 & 1 \\
 0 & 1 & 0 \\
-1 & 0 & 0
\end{pmatrix}, \quad
R_\mathrm{az}(\varphi) =
\begin{pmatrix}
1 & 0 & 0 \\
0 &  \cos\varphi & \sin\varphi \\
0 & -\sin\varphi & \cos\varphi
\end{pmatrix}, \quad
R_\mathrm{el}(\beta) =
\begin{pmatrix}
\cos\beta & 0 & \sin\beta \\
0         & 1 & 0 \\
-\sin\beta & 0 & \cos\beta
\end{pmatrix}$$

$$\mathbf{h}^\mathrm{SE} = R_\mathrm{el}(\beta)\, R_\mathrm{az}(\varphi)\, R_\mathrm{first}\, \mathbf{h}^\mathrm{W}.$$

## Heading angle definition

The heading angle is the angle of the projected nose vector in the SE plane, measured from the
$x_\mathrm{SE}$ axis (pointing towards zenith at the kite's position):

$$\boxed{\psi = \operatorname{atan2}\!\left(h^\mathrm{SE}_y,\; h^\mathrm{SE}_x\right)}$$

By default (`respos = true`) the result is wrapped to $[0,\, 2\pi)$; with `respos = false`
it is returned in $(-\pi,\, \pi]$.

A heading of $\psi = 0$ means the kite's nose points towards the zenith direction in the SE
plane (the kite is flying "upward"). A heading of $\psi = \pi/2$ means the kite's nose
points to the right (in the SE plane, clockwise when viewed from the ground station).

## API

```@docs
calc_heading
calc_heading_w
calc_clock_angle
calc_course
```
