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
    update_yaml_scalar(lines, key, value) -> (lines, updated)

Replace the value of the first line whose stripped form starts with `key`, keeping the original
indentation and trailing comment. `key` includes the colon, e.g. `"v_wind:"`. `updated` is `false`
if no such line exists; use [`insert_yaml_scalar_in_section`](@ref) to add the key in that case.

Unlike [`change_value`](@ref), the replacement is not padded to the width of the old value, and the
caller learns whether anything was changed.
"""
function update_yaml_scalar(lines::Vector{String}, key::AbstractString, value)
    value_str = repr(value)
    result = String[]
    updated = false
    pattern = Regex("^(\\s*" * escape_string(key) * "\\s*)([^#]*?)(\\s*(?:#.*)?)\$")
    for line in lines
        stripped = lstrip(line)
        if !updated && startswith(stripped, key)
            matched = match(pattern, line)
            if isnothing(matched)
                push!(result, key * " " * value_str)
            else
                prefix, _, suffix = matched.captures
                push!(result, prefix * value_str * suffix)
            end
            updated = true
        else
            push!(result, line)
        end
    end
    return result, updated
end

"""
    insert_yaml_scalar_in_section(lines, section, key, value) -> (lines, true)

Insert `key value` into `section`, indented like the section's existing children. Both `section`
and `key` include the colon, e.g. `"gui:"` and `"default_turbulence:"`. The section itself is
appended if it is not present at all, so the second return value is always `true`.
"""
function insert_yaml_scalar_in_section(lines::Vector{String}, section::AbstractString,
                                       key::AbstractString, value)
    value_str = repr(value)
    result = String[]
    in_section = false
    inserted = false
    section_indent = 0
    child_indent = "    "
    section_found = false

    for line in lines
        stripped = lstrip(line)
        indent = length(line) - length(stripped)

        if !inserted && in_section && !isempty(stripped)
            if indent <= section_indent
                push!(result, child_indent * key * " " * value_str)
                inserted = true
                in_section = false
            elseif indent > section_indent
                child_indent = line[begin:indent]
            end
        end

        push!(result, line)

        if !inserted && startswith(stripped, section)
            in_section = true
            section_found = true
            section_indent = indent
            child_indent = line[begin:indent] * "    "
        end
    end

    # Still inside the section at end of file: append the key there.
    if !inserted && in_section
        push!(result, child_indent * key * " " * value_str)
        inserted = true
    end

    # Only add a new section if it was never found.
    if !inserted && !section_found
        push!(result, section)
        push!(result, child_indent * key * " " * value_str)
    end
    return result, true
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
