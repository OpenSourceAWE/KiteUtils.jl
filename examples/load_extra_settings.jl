# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# example of loading extra settings
using KiteUtils, YAML, StructTypes, Parameters

@with_kw mutable struct FPCSettings @deftype Float64
    dt::Float64              = 0.02   
    log_level::Int64         = 2
    prn::Bool                = false
    prn_ndi_gain::Bool       = false
    prn_est_psi_dot::Bool    = false
    prn_va::Bool             = false
    use_radius::Bool         = true
    use_chi::Bool            = true
    reset_int1::Bool         = true
    reset_int2::Bool         = false
    reset_int1_to_zero::Bool = true
    init_opt_to_zero::Bool   = false
    p  = 20.0
    i  = 1.2
    d  = 10.0
    gain = 0.04
    c1 =  0.0612998898221 # was: 0.0786
    c2 =  1.22597628388   # was: 2.508
    k_c1 = 1.6
    k_c2 = 6.0
    k_c2_high = 12.0
    k_c2_int  =  0.6
    k_ds = 2.0
end

StructTypes.StructType(::Type{FPCSettings}) = StructTypes.Mutable()

# update the fields of fcs from a config file with the same field names
# the config file is expected to be in YAML format
function update(fcs::FPCSettings)
    config_file = joinpath(get_data_path(), fpc_settings())
    if Sys.iswindows()
        config_file = replace(config_file, "/" => "\\")
    end
    if ! isfile(config_file)
        println("Warning: $config_file not found, using default settings.")
        return
    end
    dict = YAML.load_file(config_file)
    sec_dict = Dict(Symbol(k) => v for (k, v) in dict["fpc_settings"])
    StructTypes.constructfrom!(fcs, sec_dict)
end

fcs = FPCSettings()
update(fcs)