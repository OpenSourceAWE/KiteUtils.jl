# SPDX-FileCopyrightText: 2022 Uwe Fechner, Bart van de Lint
# SPDX-License-Identifier: MIT

using KiteUtils, Test

@testset "KiteUtils.jl: system.yaml    " begin
    @test wc_settings() == "wc_settings.yaml"
    @test fpc_settings() == "fpc_settings.yaml"
    @test fpp_settings() == "fpp_settings.yaml"
end