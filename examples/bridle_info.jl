# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils
using LinearAlgebra

if basename(pwd()) == "examples" 
    set_data_path("../data")
else
    set_data_path("data")
end
set = deepcopy(se())

function create_bridle(se)
    # create the bridle
    bridle = KiteUtils.get_particles(se.height_k, se.h_bridle, se.width, se.m_k)
    return bridle
end
function bridle_length(se)
    # calculate the bridle length
    bridle = create_bridle(se)[2:end]
    len = norm(bridle[1] - bridle[2])
    len += norm(bridle[1] - bridle[4])
    len += norm(bridle[1] - bridle[5])
    len += norm(bridle[3] - bridle[2])
    len += norm(bridle[3] - bridle[4])
    len += norm(bridle[3] - bridle[5])
end

println("Total bridle length: ", bridle_length(set), " m")