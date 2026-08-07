# SPDX-FileCopyrightText: 2026 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils, Test

using KiteUtils: insert_yaml_scalar_in_section, readfile, update_yaml_scalar, writefile, YAML

@testset "update_yaml_scalar" begin
    lines = ["gui:", "    default_turbulence: 0.0   # scaling factor", "    fixed_font: \"\""]
    new_lines, updated = update_yaml_scalar(lines, "default_turbulence:", 0.5)
    @test updated
    @test new_lines[2] == "    default_turbulence: 0.5   # scaling factor"
    # untouched lines are passed through unchanged
    @test new_lines[[1, 3]] == lines[[1, 3]]

    # strings are written with quotes, so the result parses back as a string
    new_lines, updated = update_yaml_scalar(lines, "default_turbulence:", "default")
    @test updated
    @test new_lines[2] == "    default_turbulence: \"default\"   # scaling factor"

    # missing key: nothing is changed and the caller is told
    new_lines, updated = update_yaml_scalar(lines, "v_wind:", 1.0)
    @test !updated
    @test new_lines == lines

    # only the first match is updated
    lines2 = ["    key: 1.0", "    key: 2.0"]
    new_lines, updated = update_yaml_scalar(lines2, "key:", 3.0)
    @test updated
    @test new_lines == ["    key: 3.0", "    key: 2.0"]
end

@testset "insert_yaml_scalar_in_section" begin
    # insert before the next top-level section, with the indentation of the existing children
    lines = ["gui:", "  fixed_font: \"\"", "environment:", "  v_wind: 9.0"]
    new_lines, inserted = insert_yaml_scalar_in_section(lines, "gui:", "default_turbulence:", 0.5)
    @test inserted
    @test new_lines == ["gui:", "  fixed_font: \"\"", "  default_turbulence: 0.5",
                        "environment:", "  v_wind: 9.0"]

    # section is the last one in the file
    lines = ["environment:", "    v_wind: 9.0", "gui:", "    fixed_font: \"\""]
    new_lines, inserted = insert_yaml_scalar_in_section(lines, "gui:", "default_turbulence:", 0.5)
    @test inserted
    @test new_lines[end] == "    default_turbulence: 0.5"

    # section header without any children yet
    lines = ["gui:"]
    new_lines, _ = insert_yaml_scalar_in_section(lines, "gui:", "default_turbulence:", 0.5)
    @test new_lines == ["gui:", "    default_turbulence: 0.5"]

    # section missing entirely: it is appended together with the key
    lines = ["environment:", "    v_wind: 9.0"]
    new_lines, inserted = insert_yaml_scalar_in_section(lines, "gui:", "default_turbulence:", 0.5)
    @test inserted
    @test new_lines == ["environment:", "    v_wind: 9.0", "gui:", "    default_turbulence: 0.5"]
end

@testset "yaml scalar round trip" begin
    # the pair as used by callers: update, else insert, then read the result back with YAML
    file = joinpath(mktempdir(), "gui.yaml")
    writefile(["# comment", "gui:", "    fixed_font: \"\""], file)
    for value in (0.5, "default")
        lines = readfile(file)
        new_lines, updated = update_yaml_scalar(lines, "default_turbulence:", value)
        if !updated
            new_lines, _ = insert_yaml_scalar_in_section(lines, "gui:", "default_turbulence:",
                                                         value)
        end
        writefile(new_lines, file)
        @test YAML.load_file(file)["gui"]["default_turbulence"] == value
    end
    # the comment survived both writes
    @test readfile(file)[1] == "# comment"
end
