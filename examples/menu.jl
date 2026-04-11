# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using REPL.TerminalMenus: RadioMenu, request

options = ["bridle_info = include(\"bridle_info.jl\")",
           "import_csv = include(\"import_csv.jl\")",
           "calc_rotational_inertia = include(\"calculate_rotational_inertia.jl\")",
           "quit"]

function example_menu(options)
    active = true
    while active
        menu = RadioMenu(options, pagesize=8)
        choice = request("\nChoose function to execute or `q` to quit: ", menu)

        if choice != -1 && choice != length(options)
            eval(Meta.parse(options[choice]))
        else
            println("Left menu. Press <ctrl><d> to quit Julia!")
            active = false
        end
    end
end

example_menu(options)
