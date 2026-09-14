# Exported Functions

```@meta
CurrentModule = KiteUtils
```

# Reading config files
```@docs
set_data_path
get_data_path
load_settings
update_settings
copy_settings
copy_examples
se
se_dict
sync_wind!
check_wind_input
wc_settings
fpc_settings
fpp_settings
vsm_settings_file
aero_geometry_file
structural_geometry_file
```
Also look at the default example: [settings.yaml](https://github.com/ufechner7/KiteUtils.jl/blob/main/data/settings.yaml) .

# Modify .yaml files
```@docs
readfile
writefile
change_value
update_yaml_scalar
insert_yaml_scalar_in_section
get_comment
get_unit
```

# Creating test data
```@docs
demo_state
demo_state_4p
demo_syslog
demo_log
get_particles
```

# Loading, saving and converting log files
```@docs
log!
load_log
save_log
import_log
export_log
default_colmeta
sys_log
syslog
Base.getproperty
```
The function ```set_data_path(data_path)``` can be used to set the directory for the log files. 

## Frame conventions
Convert an orientation between the two body-frame conventions, `KS` and `KA`. A vector
resolved in the body frame is not an orientation and takes `fromKS2KA_body`; a world
vector takes `fromENU2NED` or `fromNED2ENU`.
```@docs
fromKS2KA
fromKA2KS
fromKS2KA_body
fromKA2KS_body
orient_matrix
euler_KS
log_metadata
log_convention
fromKS2KA_columns!
```

## Rotation matrices and conversions
```@docs
calc_orient_rot
fromENU2NED
fromNED2ENU
is_right_handed_orthonormal
quat2euler
quat2viewer
euler2rot
rot3d(ax, ay, az, bx, by, bz)
rot(pos_kite, pos_before, v_app)
```

## Coordinate system transformations
```@docs
fromENU2EG
fromEG2W
fromW2SE
fromKS2EX
fromEX2EG
```

## Wind vector conversions
```@docs
wind_vec_from_angles
angles_from_wind_vec
```

## Geometric calculations
Calculate the elevation angle, the azimuth angle and the ground distance based on the kite position. In addition,
calculate the heading angle, the heading vector, the asin and acos (safe versions) and the initial kite reference frame.
```@docs
calc_elevation
calc_heading
calc_course
calc_heading_w
azimuth_east
azimuth_north
azn2azw
ground_dist
acos2
asin2
wrap2pi
initial_kite_ref_frame
```

## Physical calculations
```@docs
calculate_rotational_inertia
```