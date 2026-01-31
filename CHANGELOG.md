# Changelog

### KiteUtils v0.11.1 31-01-2026
#### Changed
- fixed all `JETLS.jl` warnings; remark: `JETLS.jl` requires Julia 1.12
- removed the second parameter from the function demo_syslog because it was not used
- all test sets can now be executed independently when using `JETLS.jl` and `https://github.com/aviatesk/TestRunner.jl` 
  from within the editor
- applied `BestieTemplate.jl`; this added the files `Docs.yml`, `Test.yml`, `TestOnPRs.yml` and `ReusableTest.yml`.
  Removed the tests from CI.yml and the `docs` section from `CI.yml`. `CI.yml` is now only running `reuse-lint`.

### KiteUtils v0.11.0 26-08-2025
#### Changed
- BREAKING: renamed c_spring to axial_stiffness and damping to axial_damping
#### Added
- the fields tether_induced_force and tether_induced_moment

### KiteUtils v0.10.16 14-08-2025
#### Fixed
- support subdirectories in data dir

### KiteUtils v0.10.15 10-07-2025
#### Added
- added and exported the interface functions `init!`, `next_step!` and `update_sys_state`
#### Fixed
- disabled warning "Key sim_settings not found..."

### KiteUtils v0.10.14 06-07-2025
#### Added
- the functions `load_settings()` and `se()` have now a named param `relax`. If set to true, no section
  in the `settings.yaml` file is obligatory. This is useful for testing a package like `AtmosphericModels.jl`,
  where the `settings.yaml` does not need to have any other section than the section `environment`.
- the field `grid` was added to the `Settings` struct. It is defined as vector of Int64 values.
#### Changed
- the section `winch` is no longer obligatory, even with `relax=false`

### KiteUtils v0.10.13 28-06-2025
#### Added
- field `g_earth` to `Settings` and `settings_ram.yaml`
- abstract type `AbstractKiteModel`

### KiteUtils v0.10.12 23-06-2025
#### Added
- field `kite_distances` (vector) to `Settings` and `settings.yaml`, section `initial`
- the first element of this vector can be accessed under the name `kite_distance`

### KiteUtils v0.10.11 18-06-2025
#### Added
- added a Settings(project) constructor [#82](https://github.com/ufechner7/KiteUtils.jl/issues/84)

### KiteUtils v0.10.10 11-06-2025
#### Changed
- changed fields to vector where needed for multiple wings
#### Added
- added the depower and steering fields

### KiteUtils v0.10.9 10-06-2025
#### Fixed
- assigning values to `set.l_tether` and `set.v_reel_out` is working again

### KiteUtils v0.10.8 09-06-2025
#### Added
- implemented [#82](https://github.com/ufechner7/KiteUtils.jl/issues/82), new fields
  for Settings in the sections `initial` and `solver`

### KiteUtils v0.10.7 20-05-2025
#### Fixed
- loading of old log files in arrow format with missing columns

### KiteUtils v0.10.6 13-05-2025
#### Fixed
- fixed the log updates of the orientation by correctly initializing the logger

### KiteUtils v0.10.5 05-05-2025
#### Fixed
- fixed the log updates of vectors by using dot assignments

### KiteUtils v0.10.4 04-05-2025
#### Changed
- in the SysState struct, the fields `l_tether`, `v_reelout` and `force` are now vectors to allow logging the state of multiple tethers 
#### Added
- added the fields `side_slip`, `aero_force_b`, `aero_moment_b`, `twist_angles` and `turn_rates` to the SysState struct

### KiteUtils v0.10.3
#### Fixed
- logging of the position vectors (actually, any vectors) should work again

### KiteUtils v0.10.2
#### Added
- the section kps5 with the fields c_spring_kite, damping_kite_spring, rel_mass_p2, rel_mass_p3 and rel_mass_p4
#### Fixed
- if one of the extra sections was missing, not all other extra sections were updated
- close #79, logging of vectors

### KiteUtils v0.10.1
#### Added
- add the field `quasi_static` to the settings struct

### KiteUtils v0.10.0
#### Changed
- update settings for the `KiteModels.jl` `RamAirKite` model
- make some sections of the settings non-obligatory
#### Removed
- breaking: remove the outdated `3l` model settings
- breaking: remove the outdated `3l` initial state functions

### KiteUtils v0.9.7 - 2025-01-22
- add field `kcu_steering`

### KiteUtils v0.9.6 - 2024-12-19
#### Added
- function `KiteUtils.install_examples()`
- add field `upwind_dir`, remove vector `v_wind_ref` from `Settings`and yaml files
- add the fields `max_acc`, `p_speed` and `i_speed` to `Settings`and yaml files

### KiteUtils v0.9.5 - 2024-12-06
#### Changed
- add `bearing` to SysState for logging and plotting

### KiteUtils v0.9.4 - 2024-12-05
#### Changed
- add set_steering, heading_rate, attractor to `SysState` for logging and plotting
#### Fixed
- `build.jl`is now also working for two-element vectors

### KiteUtils v0.9.3 - 2024-11-20
#### Changes
- downgrade min version of StructArrays to v0.6.18

### KiteUtils v0.9.2 - 2024-11-29
#### Added
- add function calculate_rotational_inertia and example for using this function
- add the fields `set_torque`, `set_force`, `set_speed`, `alpha3`, `alpha4`, `roll`, `pitch`, `yaw`
  to `SysState` struct for logging and plotting

### KiteUtils v0.9.1 - 2024-11-15
#### Changes
- add fig_8, cycle and acc to the SysState
- add smc, cmq and cord_length to Settings
#### Fixed
- fix function menu()

### KiteUtils v0.9.0 - 2024-11-09
#### Breaking changes
- you can (and should) now use `SysState{P}()` to create a new, empty SysState and then fill the fields with the actual values in other packages that use KiteUtils. This makes your code robust for later changes to the struct `SysState`.
#### Changes
- all code related to logging of `SysState` structs is now auto-generated by the script `build.jl` based on the content
  of the file `sysstate.yaml`. This makes it much easier to add or remove fields for logging.
- the vectors v_wind_gnd, v_wind_200m and v_wind_kite were added to `SysState`
- the scalars AoA, CL and CD were added to SysState
- the properties `x`, `y` and `z` of `SysLog` now represent the position of the 4-point kite
#### Added
- the properties `x1`, `y1` and `z1` of `SysLog` were added and represent the position of the 1-point kite

### KiteUtils v0.8.4 - 2024-10-31
- add `cms` to settings2.yaml, a steering dependant moment coefficient to represent the deformation based turning moment

### KiteUtils v0.8.3 - 2024-10-22
- add `cs_4p` to `settings2.yaml`, a correction factor for the steering sensitivity of the KPS4 model
- extend documentation of reference frames and the orientation

### KiteUtils v0.8.2 - 2024-10-18
#### Changed
- the function calc_course expects now `upwind_dir` as parameter
- rename all parameters `up_wind_direction` to `upwind_dir`
- the function calc_heading expects now for the orientation the euler angles with respect to the NED reference frame
- it also expects the azimuth to be defined in wind reference frame
- the function fromW2SE expects now the azimuth to be defined in wind reference frame

### KiteUtils v0.8.1 - 2024-10-16
##### Added
- function euler2rot
- function azn2azw (azimuth north to azimuth wind)
- function azimuth_north
##### Removed
- removed function quat2frame because it was not well defined
- removed function calc_azimuth, replaced with more specific functions (see above)
##### Changed
- renamed the parameter `yaw` to `azimuth_north` for `demo_state` and `demo_state_4p`
##### Fixed
- fixed the function quat2viewer

### KiteUtils v0.8.0 - 2024-10-15
#### Added
- add function calc_orient_rot
- add function quat2frame
- add function quat2viewer
- add is_right_handed_orthonormal
- add enu2ned
- add parameter `yaw` to the functions `demo_state` and `demo_state_4p`
#### Fixed
- function quat2euler uses the function `dcm_to_angle` from `ReferenceFrameRotations.jl` now

### KiteUtils v0.7.12 - 2024-10-04
#### Changed
- revert the change of the heading calculation in 7.11
- update the documentation on reference frames

### KiteUtils v0.7.11 - 2024-09-24
#### Added
- the function `quat2euler(q)`, where `q` can be an `AbstractVector` or a `QuatRotation`. It returns roll, pitch and yaw in radian.
#### Changed
- the function `calc_heading()` had the new parameter `upwind_dir` with the default `-pi/2`. Furthermore the result differs by `pi` from the old calculation. The old calculation was wrong.

### KiteUtils v0.7.10 - 2024-09-16
#### Added
- the fields `foil_file`, `polar_file` and `flap_height` to the `Settings` struct
- the function `wrap2pi`
- the function `asin2`
- documentation for the yaml helper functions `readfile`, `writefile` and `change_value`

### KiteUtils v0.7.9 - 2024-09-05
#### Added
- add function `import_log()` for importing of .csv files
#### Changed
- update the documentation of reference frames

### KiteUtils v0.7.8 - 2024-08-22
#### Fix
- add cd_kcu to the KCU parameter settings, second try

### KiteUtils v0.7.7 - 2024-08-14
#### Changed
- add cd_kcu to the KCU parameter settings
- update system2.yaml and system_3l.yaml with the new settings
- the default parameter of the function `se()` is now PROJECT and not "system.yaml". This is a braking change.

### KiteUtils v0.7.6 - 2024-08-11
#### Added
- unit tests for copy_settings()
- waiver regarding the copyright of TU Delft
- the files settings_3l.yaml and system_3l.yaml

### Changed
- copy_settings() now also copies the two new settings files

#### Fixed
- improve CI.yml: code coverage works again, added cache

### KiteUtils v0.7.5 - 2024-08-09
#### Added
- the fields kcu_model, kcu_diameter, depower_zero and degrees_per_percent_power
- the files system2.yaml and system2.yaml which use KCU2

#### Fixed
- when calling se(); se("system2.yaml") the new settings where not used

### KiteUtils v0.7.4 - 2024-08-06
#### Changed
- the first parameter of `demo_state_4p_3lines()` is now the number of middle tether particles

### KiteUtils v0.7.3 - 2024-08-05
#### Added
- function `demo_state_4p_3lines()`
- `dependabot.yml` to the GitHub CI scripts, which keeps the GitHub actions up-to-date
#### Changed
- added the `Base.@kwdef` decorator to the type SysState. This allows it to easily create
  a SysState struct from a JSON message

### KiteUtils v0.7.2 - 2024-07-24
#### Changed
- renamed inertia_motor to inertia_total

### KiteUtils v0.7.1 - 2024-07-24
#### Added
- new parameters `f_coulomb` and `c_vf` for the friction of the winch

### KiteUtils v0.7.0 - 2024-07-24
#### Added
- new parameters `winch_model`, `drum_radius`, `gear_ratio`, `inertia_motor`
- print a warning if the section `kps4_3l` is missing

### KiteUtils v0.6.16 - 2024-06-25
#### Changed
- new field `width_3l`
#### Fixed
- read the fields for the KPS4-3L model from yaml file

### KiteUtils v0.6.15 - 2024-06-21
#### Changed
- add fields needed for the new KPS4-3L model

### KiteUtils v0.6.14 - 2024-06-20
#### Fixed
- all methods of the function save_log() accept now the named parameter `path`

### KiteUtils v0.6.13 - 2024-06-19
#### Fixed
- downgraded RecursiveArrayTools because the latest version stopped working any longer

### KiteUtils v0.6.12 - 2024-06-18
#### Changed
- add 6 more free variables, now 16 free variables can be logged per time step
- drop support for Julia 1.9

### KiteUtils v0.6.11 - 2024-04-22
#### Changed
- the functions `export_log()` support now the named parameter `path` to specify the directory
#### Fixed
- the function `load_log()` works now when a fully qualified filename is passed 

### KiteUtils v0.6.10 - 2024-04-20
#### Added
- new parameters `rel_compr_stiffness` and `rel_damping` in settings.yaml 

#### Changed
- the functions `load_log()` and `save_log()` have the new, optional, named parameter `path` to specify the file path;  if not specified, the default data path is used.

### KiteUtils v0.6.9 - 2024-04-16
#### Added
- function fpc_settings()
- function fpp_settings()

### KiteUtils v0.6.8 - 2024-04-16
#### Added
- function wc_settings(), which returns the name of the wc_settings.yaml file of the current project
#### Changed
- the function load_settings(project) now expects the name of the `systems.yaml` file as parameter
- the key `project` in `systems.yaml` was replaced with the key `sim_settings`
- the key `wc_settings` was added to `systems.yaml`

### KiteUtils v0.6.6 - 2024-04-05
#### Added
- add field `log_level` to `settings.yaml`and Settings struct

### KiteUtils v0.6.5 - 2024-04-03
#### Added
- add field `solver` to `settings.yaml`and Settings struct

### KiteUtils v0.6.4 - 2024-03-29
#### Changed
- the function `load_log()` does not require the number of tether segments as parameter any longer. It is derived from the content of the log file.

### KiteUtils v0.6.3 - 2024-03-26
#### Added
- Add free fields var_01 .. var_02 and column meta data ([#41](https://github.com/ufechner7/KiteUtils.jl/pull/41))

