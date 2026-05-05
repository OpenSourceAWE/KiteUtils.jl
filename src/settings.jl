# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# Provides:
# - Data structures for the flight state and the flight log.
# - Functions for creating a demo flight state, demo flight log, loading and saving flight logs.
# - The functions load_settings() and se() for reading the settings.
# - The parameter P is the number of points of the tether, equal to segments+1
# - In addition helper functions for working with rotations

"""
    Settings

Flat struct, defining the settings of the Simulator and the Viewer.

Use [`load_settings`](@ref) to reload the global module singleton, or
[`Settings(project)`](@ref) to create a fresh, independent instance.

$(TYPEDFIELDS)
"""
@with_kw mutable struct Settings @deftype Float64
    "name of the yaml file with the settings"
    sim_settings::String      = ""

    "filename without extension  [replay only]"
    log_file::String      = ""
    "how many messages to print on the console, 0=none"
    log_level             = 2
    "relative replay speed"
    time_lapse            = 0
    "simulation time             [sim only]"
    sim_time              = 0
    "number of tether segments"
    segments::Int64       = 0
    "sample frequency in Hz"
    sample_freq::Int64    = 0
    "zoom factor for the system view"
    zoom                  = 0
    "relative zoom factor for the 4 point kite"
    kite_scale            = 1.0
    "name or filepath+filename of alternative fixed pitch font"
    fixed_font::String    = ""

    "initial elevation angle             [deg]"
    elevations::Vector{Float64}      = [70]
    "initial elevation rate            [deg/s]"
    elevation_rates::Vector{Float64} = [0]
    "initial azimuth angle               [deg]"
    azimuths::Vector{Float64}        = [0]
    "initial azimuth rate              [deg/s]"
    azimuth_rates::Vector{Float64}   = [0]
    "initial heading angle               [deg]"
    headings::Vector{Float64}        = [0]
    "initial heading rate              [deg/s]"
    heading_rates::Vector{Float64}   = [0]
    "initial tether lengths                [m]"
    l_tethers::Vector{Float64}       = [0]
    "initial kite distances                [m]"
    kite_distances::Vector{Float64}  = [0]
    "initial reel out speeds             [m/s]"
    v_reel_outs::Vector{Float64}     = [0]
    "initial depower settings              [%]"
    depowers::Vector{Float64}        = [0]
    "initial steering settings             [%]"
    steerings::Vector{Float64}       = [0]
    "initial quotient of actual and unstretched tether length"
    delta                            = 0.001
    "relative stiffness of the first round of solving the initial equilibrium"
    stiffness_factor                 = 0.1

    # # three values are only needed for RamAirKite, for KPS3 and KPS4 use only the first value
    # l_tethers: [50.0, 50.0, 50.0] # initial tether lengths     [m]
    # v_reel_outs: [0.0, 0.0, 0.0]  # initial reel out speeds   [m/s]

    "absolute tolerance of the DAE solver [m, m/s]"
    abs_tol               = 0.0
    "relative tolerance of the DAE solver [-]"
    rel_tol               = 0.0
    "DAE solver, can be IDA or DFBDF"
    solver::String        = "DFBDF"
    "can be GMRES or Dense"
    linear_solver::String = "GMRES"
    "maximal order, usually between 3 and 5"
    max_order::Int64      = 4
    "max number of iterations of the steady-state-solver"
    max_iter::Int64       = 1
    "max internal step size of the DAE solver; Inf means no limit"
    dtmax                 = Inf
    "relaxation factor for Newton solver for quasi-steady tether model"
    relaxation = 0

    "steering offset   -0.0032           [-]"
    c0                    = 0
    "steering coefficient one point model"
    c_s                   = 0
    "correction factor one point model"
    c2_cor                = 0
    "influence of the depower angle on the steering sensitivity"
    k_ds                  = 0
    "steering increment (when pressing RIGHT)"
    delta_st              = 0
    "max. steering angle of the side planes for four point model [degrees]"
    max_steering          = 0
    "correction factor for the steering sensitivity four point model"
    cs_4p                 = 1.0

    "max depower angle             [deg]"
    alpha_d_max           = 0
    "at rel_depower=0.236 the kite is fully powered [%]"
    depower_offset        = 23.6

    "file name of the 3D model of the kite for the viewer"
    model::String         = "data/kite.obj"
    "filename with or without extension for the foil shape [in dat format]"
    physical_model::String = ""
    "version of the model to use"
    version::Int64 = 1
    "kite mass incl. sensor unit     [kg]"
    mass                  = 0
    "projected kite area           [m^2]"
    area                  = 0
    "relative side area              [%]"
    rel_side_area         = 0
    "height of the kite              [m]"
    height_k              = 0
    alpha_cl::Vector{Float64} = []
    cl_list::Vector{Float64}  = []
    alpha_cd::Vector{Float64} = []
    cd_list::Vector{Float64}  = []
    "steering dependant moment coefficient"
    cms                   = 0
    "width of the kite               [m]"

    # KPS4 specific parameters
    width                 = 0
    "should be 5                     [degrees]"
    alpha_zero            = 0
    alpha_ztip            = 0
    "relative nose distance; increasing m_k increases C2 of the turn-rate law"
    m_k                   = 0
    rel_nose_mass         = 0
    "mass of the top particle relative to the sum of top and side particles"
    rel_top_mass          = 0
    " steering moment coefficient"
    smc                   = 0
    "pitch rate dependant moment coefficient"
    cmq                   = 0
    "average aerodynamic cord length of the kite [m]"
    cord_length           = 0

    # KPS5 specific parameters
    "unit spring constant coefficient of the kite springs [N]"
    axial_stiffness_kite = 0
    "unit damping coefficient of the kite springs [Ns]"
    axial_damping_kite = 0
    "relative mass of p2"
    rel_mass_p2 = 0
    "relative mass of p3"
    rel_mass_p3 = 0
    "relative mass of p4 and p5"
    rel_mass_p4 = 0

    # Ram air kite specific parameters
    "filename of the foil shape [in dat format]"
    foil_file::String     = "data/ram_air_kite_foil.dat"
    "top bridle points that are not on the kite body in CAD frame"
    top_bridle_points::Vector{Vector{Float64}} = [[0.290199, 0.784697, -2.61305],
                                                  [0.392683, 0.785271, -2.61201],
                                                  [0.498202, 0.786175, -2.62148],
                                                  [0.535543, 0.786175, -2.62148]]
    "bridle tether diameter [mm]"
    bridle_tether_diameter  = 2.0
    "power tether diameter [mm]"
    power_tether_diameter   = 2.0
    "steering tether diameter [mm]"
    steering_tether_diameter= 1.0
    "distance along normalized foil chord for the trailing edge deformation crease"
    crease_frac             = 0.82
    "distances along normalized foil chord for bridle attachment points"
    bridle_fracs::Vector{Float64} = [0.088, 0.31, 0.58, 0.93]
    "the bridle frac index around which the kite twists"
    fixed_index::Int        = 1
    "wether to use quasi-static tether points or not"
    quasi_static::Bool      = false

    "bridle line diameter                [mm]"
    d_line                = 0
    "height of the bridle                  [m]"
    h_bridle              = 0
    "sum of the lengths of the bridle lines [m]"
    l_bridle              = 0
    "relative compression stiffness of the kite springs"
    rel_compr_stiffness   = 0
    "relative damping of the kite spring (relative to main tether)"
    rel_damping           = 0

    "model of the kite control unit, KCU1 or KCU2"
    kcu_model::String     = "KCU1"
    "mass of the kite control unit   [kg]"
    kcu_mass              = 0
    "diameter of the kite control unit for drag calculation [m]"
    kcu_diameter          = 0
    "drag coefficient of the kite control unit"
    cd_kcu                = 0
    "depower setting for alpha_zero = 0 [%]"
    depower_zero      = 0
    "linear approximation [degrees/%]"
    degrees_per_percent_power = 0
    "power to steering line distance  [m]"
    power2steer_dist      = 0
    depower_drum_diameter = 0
    tape_thickness        = 0
    "max velocity of depowering in units per second (full range: 1 unit)"
    v_depower             = 0
    "max velocity of steering in units per second   (full range: 2 units)"
    v_steering            = 0
    "3.0 means: more than 33% error -> full speed"
    depower_gain          = 3.0
    steering_gain         = 3.0

    "tether diameter                 [mm]"
    d_tether              = 0
    "drag coefficient of the tether"
    cd_tether             = 0
    "unit damping coefficient       [Ns]"
    axial_damping         = 0
    "unit spring constant coefficient [N]"
    axial_stiffness       = 0
    "density of Dyneema                [kg/m³]"
    rho_tether            = 0
    "axial tensile modulus of the tether     [Pa]"
    e_tether              = 0

    "the winch model, either AsyncMachine or TorqueControlledMachine"
    winch_model::String   = ""
    "maximal (nominal) tether force; short overload allowed [N]"
    max_force             = 4000
    "maximal reel-out speed                  [m/s]"
    v_ro_max              = 8
    "minimal reel-out speed (=max reel-in speed) [m/s]"
    v_ro_min              = -8
    "minimum speed below which the brake is active [m/s]"
    v_min                 = 0.1
    "maximal acceleration                    [m/s²]"
    max_acc               = 0
    "radius of the drum [m]"
    drum_radius = 0.1615
    "ratio of the gear box"
    gear_ratio = 6.2
    "inertia of the motor, gearbox and drum, as seen from the motor [kgm²]"
    inertia_total = 0
    "coulomb friction [N]"
    f_coulomb = 122.0
    "coefficient for the viscous friction [Ns/m]"
    c_vf = 30.6
    "proportional gain for the speed controller"
    p_speed = 0
    "integral gain for the speed controller"
    i_speed = 0

    "wind speed at reference height      [m/s]"
    v_wind                = 0
    "initial upwind direction          [deg]"
    upwind_dir            = 0
    "angle between upwind direction and the east-north plane [deg]"
    upwind_elevation      = 0
    "wind vector at reference height     [m/s]"
    wind_vec::MVec3       = zeros(MVec3)
    "if true, use wind_vec; if false, use v_wind, upwind_dir and upwind_elevation"
    use_wind_vec::Bool    = false
    "temperature at reference height     [°C]"
    temp_ref              = 0
    "height of groundstation above see level  [m]"
    height_gnd            = 0
    " reference height for the wind speed   [m]"
    h_ref                 = 0
    "air density at zero height and 15 °C   [kg/m³]"
    rho_0                 = 0
    "exponent of the wind profile law"
    alpha                 = 0
    "surface roughness                     [m]"
    z0                    = 0
    "1=EXP, 2=LOG, 3=EXPLOG, 4=FAST_EXP, 5=FAST_LOG, 6=FAST_EXPLOG"
    profile_law::Int64    = 0
    "turbulence intensity relative to Cabauw, NL"
    use_turbulence        = 0
    "wind speeds at ref height for calculating the turbulent wind field [m/s]"
    v_wind_gnds::Vector{Float64} = []
    "average height during reel out          [m]"
    avg_height            = 0
    "relative turbulence at the v_wind_gnds"
    rel_turbs::Vector{Float64} = []
    "the expected value of the turbulence intensity at 15 m/s"
    i_ref                 = 0
    "five times the average wind speed in m/s at hub height over the full year    [m/s]"
    v_ref                 = 0
    "grid size nx, ny, nz and minimal height z_min                                   [m]"
    grid::Vector{Int64} = []
    "grid resolution in z direction                                                [m]"
    height_step           = 0
    "grid resolution in x and y direction                                          [m]"
    grid_step             = 0
    "gravitational acceleration"
    g_earth               = 0
end
function Base.getproperty(set::Settings, sym::Symbol)
    if sym == :l_tether
        (getproperty(set, :l_tethers))[1]
    elseif sym == :kite_distance
        (getproperty(set, :kite_distances))[1]
    elseif sym == :v_reel_out
        (getproperty(set, :v_reel_outs))[1]
    elseif sym == :elevation
        (getproperty(set, :elevations))[1]
    elseif sym == :elevation_rate
        (getproperty(set, :elevation_rates))[1]
    elseif sym == :azimuth
        (getproperty(set, :azimuths))[1]
    elseif sym == :azimuth_rate
        (getproperty(set, :azimuth_rates))[1]
    elseif sym == :heading
        (getproperty(set, :headings))[1]
    elseif sym == :heading_rate
        (getproperty(set, :heading_rates))[1]
    elseif sym == :depower
        (getproperty(set, :depowers))[1]
    elseif sym == :steering
        (getproperty(set, :steerings))[1]
    else
        getfield(set, sym)
    end
end
function Base.setproperty!(set::Settings, sym::Symbol, val)
    if sym == :l_tether
        (getproperty(set, :l_tethers))[1] = val
    elseif sym == :kite_distance
        (getproperty(set, :kite_distances))[1] = val
    elseif sym == :v_reel_out
        (getproperty(set, :v_reel_outs))[1] = val
    elseif sym == :elevation
        (getproperty(set, :elevations))[1] = val
    elseif sym == :elevation_rate
        (getproperty(set, :elevation_rates))[1] = val
    elseif sym == :azimuth
        (getproperty(set, :azimuths))[1] = val
    elseif sym == :azimuth_rate
        (getproperty(set, :azimuth_rates))[1] = val
    elseif sym == :heading
        (getproperty(set, :headings))[1] = val
    elseif sym == :heading_rate
        (getproperty(set, :heading_rates))[1] = val
    elseif sym == :depower
        (getproperty(set, :depowers))[1] = val
    elseif sym == :steering
        (getproperty(set, :steerings))[1] = val
    else
        if val isa Int && (getproperty(set, sym)) isa Float64
            setfield!(set, sym, Float64(val))
        else
            setfield!(set, sym, val)
        end
        if sym in (:use_wind_vec, :wind_vec, :v_wind,
                   :upwind_dir, :upwind_elevation)
            sync_wind!(set)
        end
    end
end

StructTypes.StructType(::Type{Settings}) = StructTypes.Mutable()
function StructTypes.constructfrom(::Type{MVec3}, vec::AbstractVector)
    MVec3(vec[1], vec[2], vec[3])
end
PROJECT::String = "system.yaml"

"""
    Settings(project; relax=false)

Create a fresh [`Settings`](@ref) instance, loading from the given
project file. Unlike [`load_settings`](@ref), this does **not** modify
the global module settings; it returns an independent struct.

## Parameters
- `project`: The name of the project file to load.
- `relax`: If true, missing sections in the settings file are
  skipped instead of raising an error.
"""
function Settings(project; relax=false)
    set = Settings()
    return se(set, project; relax)
end
const SETTINGS = Settings()
const _SE_DICTS = IdDict{Settings, Dict{String, Any}}()

"""
    set_data_path(data_path="")

Set the directory for log and config files.

If called without argument, use the data path of the package to obtain the default settings
when calling se().
"""
function set_data_path(data_path="")
    if data_path==""
        data_path = joinpath(dirname(@__DIR__), "data")
    end
    if data_path != DATA_PATH[1]
        DATA_PATH[1] = data_path
        SETTINGS.segments == 0 # enforce reloading of settings.yaml
    end
end

"""
    get_data_path()

Get the directory for log and config files.
"""
function get_data_path()
    return DATA_PATH[1]
end

"""
    load_settings(project=PROJECT; relax=false)

Reload the global module [`Settings`](@ref) from the given project
file. Returns the updated global settings singleton. To obtain an
independent settings instance instead, use the
[`Settings(project)`](@ref) constructor.

The project must include the path and the suffix .yaml .

## Parameters
- `project`: The name of the project file to load, defaults to
  the project that was loaded before.
- `relax`: If true, missing sections in the settings file are
  skipped instead of raising an error.
"""
function load_settings(project=PROJECT; relax=false)
    SETTINGS.segments=0
    se(project; relax)
end

"""
    update_settings()

Re-read the settings from a previously loaded project. Returns the new settings.
"""
function update_settings()
    load_settings(PROJECT)
end

"""
    sync_wind!(set::Settings)

Synchronise the wind representation in `set`. If `use_wind_vec` is
`true`, compute `v_wind`, `upwind_dir` and `upwind_elevation` from
`wind_vec`. Otherwise compute `wind_vec` from the three scalars.

Angles in `Settings` are stored in **degrees**; the conversion
functions operate in radians, so this function handles the
conversion.
"""
function sync_wind!(set::Settings)
    if set.use_wind_vec
        v, dir, elev = angles_from_wind_vec(set.wind_vec)
        Core.setfield!(set, :v_wind, v)
        Core.setfield!(set, :upwind_dir, rad2deg(dir))
        Core.setfield!(set, :upwind_elevation, rad2deg(elev))
    else
        Core.setfield!(set, :wind_vec, wind_vec_from_angles(
            set.v_wind,
            deg2rad(set.upwind_dir),
            deg2rad(set.upwind_elevation)))
    end
    nothing
end

function copy_files(relpath, files)
    if ! isdir(relpath)
        mkdir(relpath)
    end
    src_path = joinpath(@__DIR__, "..", relpath)
    for file in files
        cp(joinpath(src_path, file), joinpath(relpath, file), force=true)
        chmod(joinpath(relpath, file), 0o774)
    end
    files
end

"""
    copy_settings()

Copy the default settings.yaml and system.yaml files to the folder DATAPATH
(it will be created if it doesn't exist).
"""
function copy_settings(extra_files=[])
    src_path = abspath(joinpath(@__DIR__, "..", "data"))
    if src_path == abspath(DATA_PATH[1])
        DATA_PATH[1] = joinpath(pwd(), "data")
    end
    if ! isdir(DATA_PATH[1])
        mkdir(DATA_PATH[1])
    end
    files = ["settings.yaml", "system.yaml", "settings_ram.yaml", "system_ram.yaml", "kite.obj"]
    append!(files, extra_files)
    copy_files("data", files)
    set_data_path(joinpath(pwd(), "data"))
    # set font
    if Sys.islinux()
        settings = joinpath(DATA_PATH[1], "settings.yaml")
        lines = readfile(settings)
        lines = change_value(lines, "fixed_font:", "\"Liberation Mono\"")
        writefile(lines, settings)
    end
    println("Copied $(length(files)) files to $(DATA_PATH[1]) !")
end

function update_settings(dict, sections, settings=SETTINGS)
    result = Dict{Symbol, Any}()
    for section in sections
        sec_dict = Dict(Symbol(k) => v for (k, v) in dict[section])
        merge!(result, sec_dict)
    end
    StructTypes.constructfrom!(settings, result)
end

"""
    wc_settings(project=PROJECT)

Get the winch controller (WC) settings filename from the project file.

Returns the filename specified in the `wc_settings` field of the system section.
The project file defaults to the currently active PROJECT.
"""
function wc_settings(project=PROJECT)
    # determine which wc_settings to load
    dict = YAML.load_file(joinpath(DATA_PATH[1], project))
    dict["system"]["wc_settings"]
end

"""
    fpc_settings(project=PROJECT)

Get the flight path controller (FPC) settings filename from the project file.

Returns the filename specified in the `fpc_settings` field of the system section.
The project file defaults to the currently active PROJECT.
"""
function fpc_settings(project=PROJECT)
    # determine which fpc_settings to load
    dict = YAML.load_file(joinpath(DATA_PATH[1], project))
    dict["system"]["fpc_settings"]
end

"""
    fpp_settings(project=PROJECT)

Get the flight path planner (FPP) settings filename from the project file.

Returns the filename specified in the `fpp_settings` field of the system section.
The project file defaults to the currently active PROJECT.
"""
function fpp_settings(project=PROJECT)
    # determine which fpp_settings to load
    dict = YAML.load_file(joinpath(DATA_PATH[1], project))
    dict["system"]["fpp_settings"]
end

"""
    vsm_settings_file(project=PROJECT)

Get the vortex step model (VSM) settings filename from the project file.

Returns the filename specified in the `vsm_settings` field of the system section.
The project file defaults to the currently active PROJECT.
"""
function vsm_settings_file(project=PROJECT)
    # determine which vsm_settings to load
    dict = YAML.load_file(joinpath(DATA_PATH[1], project))
    dict["system"]["vsm_settings"]
end

"""
    aero_geometry_file(project=PROJECT)

Get the aerodynamic geometry filename from the project file.

Returns the filename specified in the `aero_geometry` field of the system section.
The project file defaults to the currently active PROJECT.
"""
function aero_geometry_file(project=PROJECT)
    # determine which aero_geometry to load
    dict = YAML.load_file(joinpath(DATA_PATH[1], project))
    dict["system"]["aero_geometry"]
end

"""
    structural_geometry_file(project=PROJECT)

Get the structural geometry filename from the project file.

Returns the filename specified in the `structural_geometry` field of the system section.
The project file defaults to the currently active PROJECT.
"""
function structural_geometry_file(project=PROJECT)
    # determine which structural_geometry to load
    dict = YAML.load_file(joinpath(DATA_PATH[1], project))
    dict["system"]["structural_geometry"]
end

"""
    se(project=PROJECT; relax=false)

Getter function for the [`Settings`](@ref) struct.

The settings.yaml file to load is determined by the content active PROJECT, which defaults to `system.yaml`.
The project file must be located in the directory specified by the data path [`get_data_path`](@ref).
"""
function se(project=PROJECT; relax=false)
    global PROJECT
    return se(SETTINGS, project; relax)
end

"""
    se(settings::Settings, project=PROJECT; relax=false)

Update function for the [`Settings`](@ref) struct.

The settings.yaml file to load is determined by the content active PROJECT, which defaults to `system.yaml`.
The project file must be located in the directory specified by the data path [`get_data_path`](@ref).
"""
function se(settings::Settings, project=PROJECT; relax=false)
    global PROJECT

    # Process project path: remove leading "data/" if present
    path_parts = splitpath(project)
    processed_project = project
    if !isempty(path_parts) && path_parts[1] == "data"
        processed_project = joinpath(path_parts[2:end]...)
    end

    if settings.segments == 0 || processed_project != PROJECT
        # determine which sim_settings to load
        project_path = joinpath(DATA_PATH[1], processed_project)
        dict = YAML.load_file(project_path)
        PROJECT = processed_project
        try
            settings.sim_settings = dict["system"]["sim_settings"]
        catch
            settings.sim_settings = dict["system"]["project"]
            # println("Warning! Key sim_settings not found in $project .")
        end

        # The sim_settings file is resolved relative to the project file's directory.
        project_dir = dirname(processed_project)
        sim_settings_path = joinpath(project_dir, settings.sim_settings)

        # load sim_settings from YAML
        dict = YAML.load_file(joinpath(DATA_PATH[1], sim_settings_path))
        _SE_DICTS[settings] = dict
        # update the settings struct from the dictionary
        required_sections = ["system", "solver", "kite", "tether", "environment"]
        if relax
            for section in required_sections
                if section in keys(dict)
                    update_settings(dict, [section], settings)
                end
            end
        else
            update_settings(dict, required_sections, settings)
        end
        for section in ["initial", "steering", "depower", "kps4", "kps5", "bridle", "winch", "kcu"]
            if section in keys(dict)
                update_settings(dict, [section], settings)
            end
        end
        if haskey(dict, "system")
            tmp = split(dict["system"]["log_file"], "/")
            settings.log_file    = joinpath(tmp[1], tmp[2])
        end
        if haskey(dict, "kite") && haskey(dict["kite"], "height")
            settings.height_k = dict["kite"]["height"]
        end
        sync_wind!(settings)
    end
    return settings
end

"""
    se_dict()

Getter function for the dictionary, representing the settings.yaml file.

Access to the dict is much slower than access to the setting struct, but more flexible.

Usage example:
`z0 = se_dict()["environment"]["z0"]`
"""
function se_dict(set::Settings=SETTINGS)
    if set.segments == 0
        Base.invokelatest(se, set)
    end
    get(_SE_DICTS, set, Dict{String, Any}())
end
