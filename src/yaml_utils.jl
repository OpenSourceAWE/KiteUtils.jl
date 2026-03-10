# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

# Functions to modify variables in a yaml file while leaving the comments intact.

"""
    readfile(filename)

Read the lines of a text file.
"""
function readfile(filename)
    open(filename) do file
        readlines(file)
    end
end

"""
    writefile(lines, filename)

Write the lines to a file.
"""
function writefile(lines, filename)
    open(filename, "w") do file
        for line in lines
            write(file, line, '\n')
        end
    end
end

"""
    change_value(lines, varname, value::Union{Integer, Float64})

Change the value of a variable in a yaml file for a number.
"""
function change_value(lines, varname, value::Union{Integer, Float64})
    change_value(lines, varname, repr(value))
end

"""
    change_value(lines, varname, value::String)

Change the value of a variable in a yaml file.
"""
function change_value(lines, varname, value::String)
    res = String[]
    for line in lines
        if startswith(lstrip(line), varname)
            start = (findfirst(varname, line)).stop+1
            stop = something(findfirst('#', line), length(line) + 1) - 1
            new_line = ""
            leading = true
            j = 1
            for (i, chr) in pairs(line)
                if i < start || i > stop
                    new_line *= chr
                elseif line[i] == ' ' && leading
                    new_line *= ' '
                elseif j <= length(value)
                    new_line *= value[j]
                    j += 1
                    leading = false
                elseif i <= stop
                    new_line *= ' '
                end
            end
            push!(res, new_line)
        else
            push!(res, line)
        end
    end
    res
end

"""
    get_comment(lines, key)

Get the comment of a variable in a yaml file.
"""
function get_comment(lines, key)
    for line in lines
        if startswith(lstrip(line), key)
            col = findfirst("#", line)
            if ! isnothing(col)
                return "\"" * line[col[1]+2:end] * "\""
            end
        end
    end
    return ""
end

"""
    get_unit(lines, key)

Get the unit of a variable in a yaml file. The unit must be defined in square brackets.
"""
function get_unit(lines, key)
    comment = get_comment(lines, key)
    if comment != ""
        begin_ = findfirst("[", comment)
        if isnothing(begin_)
            return "[-]"
        else
            return comment[begin_[1]:end-1]
        end
    end
    return "[-]"
end
