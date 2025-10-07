# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# example of loading extra settings
using KiteUtils, YAML

# if a struct for the parameter fcs is defined, it can be updated from a config file
#  with the same field names
#  the config file is expected to be in YAML format
function update(fcs)
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
    # StructTypes.constructfrom!(fcs, sec_dict)
end

fcs = nothing
update(fcs)