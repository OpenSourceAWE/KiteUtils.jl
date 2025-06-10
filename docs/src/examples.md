```@meta
CurrentModule = KiteUtils
```
# Examples

## Create a test project

```
mkdir test
cd test
julia --project
```
and add KiteUtils to the project:
```julia
]activate .
add KiteUtils
<BACKSPACE>
```
finally, copy the default configuration files to your new project:
```julia
using KiteUtils
copy_settings()
```

## Use of the settings
```julia
using KiteUtils
const set = se()
```
```julia
KiteUtils.Settings
  project: String "settings.yaml"
  log_file: String "data/log_8700W_8ms"
  model: String "data/kite.obj"
  segments: Int64 6
  sample_freq: Int64 20
  time_lapse: Float64 1.0
  zoom: Float64 0.03
  fixed_font: String ""
  v_reel_out: Float64 0.0
  c0: Float64 0.0
  c_s: Float64 2.59
  c2_cor: Float64 0.93
  k_ds: Float64 1.5
  area: Float64 10.18
  mass: Float64 6.2
  height_k: Float64 2.23
  alpha_cl: Array{Float64}((12,)) [-180.0, -160.0, -90.0, -20.0, -10.0, -5.0, 0.0, 20.0, 40.0, 90.0, 160.0, 180.0]
  cl_list: Array{Float64}((12,)) [0.0, 0.5, 0.0, 0.08, 0.125, 0.15, 0.2, 1.0, 1.0, 0.0, -0.5, 0.0]
  alpha_cd: Array{Float64}((11,)) [-180.0, -170.0, -140.0, -90.0, -20.0, 0.0, 20.0, 90.0, 140.0, 170.0, 180.0]
  cd_list: Array{Float64}((11,)) [0.5, 0.5, 0.5, 1.0, 0.2, 0.1, 0.2, 1.0, 0.5, 0.5, 0.5]
  ...
  l_bridle: Float64 33.4
  l_tether: Float64 392.0
  damping: Float64 473.0
  c_spring: Float64 614600.0
  elevation: Float64 70.7
  sim_time: Float64 100.0
```

You can see the available setting parameters by typing
```set.<TAB><TAB>```
at the Julia prompt. Defining ```set``` as constant improves the performance of the access to the 
parameters. You can still change the values of the parameters, only the types are fixed.

## The system state, type SysState
The state of the kitepower system is captured in the struct [`SysState`](@ref) .
```julia
julia> using KiteUtils

julia> st = demo_state(7)
time      [s]:       0.0
orient    [w,x,y,z]: Float32[0.5, 0.5, -0.5, -0.5]
elevation [rad]:     0.5404195
azimuth   [rad]:     0.0
l_tether  [m]:       0.0
v_reelout [m/s]:     0.0
force     [N]:       0.0
depower   [-]:       0.0
steering  [-]:       0.0
heading   [rad]:     0.0
course    [rad]:     0.0
v_app     [m/s]:     0.0
vel_kite  [m/s]:     Float32[0.0, 0.0, 0.0]
X         [m]:       Float32[0.0, 1.6666666, 3.3333333, 5.0, 6.6666665, 8.333333, 10.0]
Y         [m]:       Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
Z         [m]:       Float32[0.0, 0.15380114, 0.6194867, 1.4100224, 2.5474184, 4.063342, 6.0000005]
```

For simulation the time is since the start of the simulation, for flight logs the time is since launch.  
You can access the fields of the state using the dot notation:
```julia
julia> rad2deg(st.elevation)
30.963757f0
```

The orientation is stored as unit quaternion (see: [Quaterinos\_and\_spatial\_rotation](https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation)).

If you need to work with rotations, use the package Rotatations.jl (see: [Rotations.jl](https://github.com/JuliaGeometry/Rotations.jl))  
Example:
```julia
julia> using Rotations

julia> q = QuatRotation(st.orient)
3×3 QuatRotation{Float32} with indices SOneTo(3)×SOneTo(3)(Quaternion{Float32}(0.5, 0.5, -0.5, -0.5, true)):
  0.0  0.0  -1.0
 -1.0  0.0   0.0
  0.0  1.0   0.0
```
The components X, Y and Z are vectors of the x, y and z positions of the tether particles. The last element of these vectors
represents the kite position.
```julia
julia> kite_pos = [st.X[end], st.Y[end], st.Z[end]]
3-element Vector{Float32}:
 10.0
  0.0
  6.0000005
```
## The system log
The system log can be used to store the result of a simulation or of a test flight. 
It stores an array of SysState structs, to be precise: a [StructArray](https://github.com/JuliaArrays/StructArrays.jl) .
```julia
julia> log=demo_log(7)
julia> syslog=log.syslog
```
You can acces this array by index:
```julia
syslog[end]
time      [s]:       10.0
orient    [w,x,y,z]: Float32[0.5, 0.5, -0.5, -0.5]
elevation [rad]:     0.64350116
azimuth   [rad]:     0.0
l_tether  [m]:       0.0
v_reelout [m/s]:     0.0
force     [N]:       0.0
depower   [-]:       0.0
steering  [-]:       0.0
heading   [rad]:     0.0
course    [rad]:     0.0
v_app     [m/s]:     0.0
vel_kite  [m/s]:     Float32[0.0, 0.0, 0.0]
X         [m]:       Float32[0.0, 1.6666666, 3.3333333, 5.0, 6.6666665, 8.333333, 10.0]
Y         [m]:       Float32[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
Z         [m]:       Float32[0.0, 0.15380114, 0.6194867, 1.4100224, 2.5474184, 4.063342, 6.0000005]

```
But you can also access the syslog component wise:
```julia
julia> rad2deg.(syslog.elevation)
201-element Vector{Float64}:
  0.0
  0.17188759349740207
  0.343776734459538
  0.5156689836913548
  0.6875658486369466
  0.8594689568023267
  1.0313798022913758
  ⋮
 35.80299102537142
 36.01521524816747
 36.22800637666463
 36.44138148633583
 36.655340577181065
 36.86990072467326
```
Note: To apply the function rad2deg on a vector the dot notation ```rad2deg.``` is used.

## The type SysLog
The type SysLog is a struct of a syslog as explained above and its name. In addition the properties x, y and z are defined, which represent the position
of the kite over time.
```julia
julia> log = demo_log(7)
SysLog{7}("Test_flight", SysState{7}[time      [s]:            0.0
orient    [QuatRotation]: Float32[0.0 0.0 -1.0; -1.0 0.0 0.0; 0.0 1.0 0.0]
x         [m]:            10.0
y         [m]:            0.0
z         [m]:            0.0
...
```
You can access the elements using the dot notation, for example an array of the values for the height:
```
julia> log.z
201-element Vector{Float32}:
 0.0
 0.030000001
 0.060000002
 0.09
 0.120000005
 0.15
 0.18
 ⋮
 5.8500004
 5.8800006
 5.9100003
 5.9400005
 5.9700003
 6.0000005
```
This is useful for example for 2D plotting. Example:
```julia
using Plots
plot(log.syslog.time, log.z)
```
This command creates a 2D plot of the height vs. the time. After the command ```using Plots``` you will be asked if you want to install
the Plots package. Just press ENTER and it will get installed.

## Saving, exporting and importing log files

Saving a log file:
```julia
julia> log = demo_log(7);
julia> save_log(log)
```
The semicolon at the end of the first line suppresses the output.

Exporting a log file in csv format:
```julia
julia> log = demo_log(7);
julia> export_log(log)
```
By default the log file is save in the data folder. You can set a different folder as data folder with the function **`set_data_path`**. 

```julia
julia> log = demo_log(7);
julia> set_data_path(tempdir())
julia> export_log(log)
```

Output on Linux:
```julia
"/tmp/Test_flight.csv"
```
The output on Windows will be different because the default temporary directory is different.

You can import a .csv file using the following code:
```julia
set_data_path("data")
filename="transition"

log = import_log(filename)
save_log(log)
```
This will import the file `transition.csv` and save it as `transition.arrow` file.