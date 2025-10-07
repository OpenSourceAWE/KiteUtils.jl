# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

using KiteUtils
using Test

#=
Don't add your tests to runtests.jl. Instead, create files named

    test-title-for-my-test.jl

The file will be automatically included inside a `@testset` with title "Title For My Test".
=#

if basename(pwd()) == "test"; cd(".."); end
@testset "KiteUtils.jl: system.yaml    " begin
    # Ensure we're using the correct data path and file
    set_data_path("data")
    @test wc_settings("system.yaml") == "wc_settings.yaml"
    @test fpc_settings("system.yaml") == "fpc_settings.yaml"
    @test fpp_settings("system.yaml") == "fpp_settings.yaml"
    @test vsm_settings("system.yaml") == "vsm_settings.yaml"
end

for (_, _, files) in walkdir(@__DIR__)
    for file in files
        if isnothing(match(r"^test-.*\.jl$", file))
            continue
        end
        title = titlecase(replace(splitext(file[6:end])[1], "-" => " "))
        title = rpad(title, 25)
        @testset "$title" begin
            include(file)
        end
    end
end
