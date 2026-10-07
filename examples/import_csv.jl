# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils

if basename(pwd()) == "examples" 
    set_data_path("../data")
else
    set_data_path("data")
end
filename="transition"

# transition.csv was exported before logs recorded their convention, so it is KS.
log = import_log(filename; frame=KS)
println("Imported csv log file: ", filename * ".csv")
println("Saved log file as: ", save_log(log))