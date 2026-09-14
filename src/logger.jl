# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

include("_logger.jl")

"""
    Logger(P, steps; orients=1, deflections=0, pulleys=0, winches=1,
           tethers=winches, segments=0, precision=MyFloat)

Pre-allocate a log of `P` points for `steps` time steps. The remaining counts
are keywords so that adding a dimension does not add another positional method:
`orients` oriented frames, `deflections` twist surfaces, `pulleys` pulleys,
`winches` winches, `tethers` tethers and `segments` segments. `tethers` defaults
to `winches`, which is right whenever each winch drives one tether. Pass
`precision=Float64` to log a differential state that round-trips `integrator.u`
exactly.
"""
function Logger(P, steps; orients=1, deflections=0, pulleys=0, winches=1,
                tethers=winches, segments=0, precision=MyFloat)
    Logger{P, orients, deflections, pulleys, winches, tethers, segments,
           precision, steps}()
end

include("_log.jl")

function length(logger::Logger)
    logger.index - 1
end

include("_syslog.jl")

"""
    sys_log(logger::Logger, name="sim_log"; colmeta=default_colmeta())

Convert the data of a `Logger` into a `SysLog`, holding the rows that were
logged, the name of the log and the column meta data.
"""
function sys_log(logger::Logger, name="sim_log"; colmeta=default_colmeta())
    SysLog{logger.points}(name, colmeta, syslog(logger))
end

"""
    save_log(logger::Logger, name="sim_log", compress=true; path="",
             colmeta=default_colmeta())

Save the rows that were logged as .arrow file. By default lz4 compression is
used, if you use **false** as second parameter no compression is used.
"""
function save_log(logger::Logger, name="sim_log", compress=true; path="",
                  colmeta=default_colmeta())
    save_log(sys_log(logger, name; colmeta), compress; path)
end

function parse_vector(str)
    m = match(r"\[(.*)\]", str)
    strs = split(m[1], ','; keepempty=false)
    Parsers.parse.(Float32, strs)
end

function import_log_(filename::String; path="")
    if path == ""
        path = DATA_PATH[1]
    end
    filename = joinpath(path, filename) * ".csv"
    return (CSV.File(filename))
end

# The columns of a .csv flight log, addressed by name the way an `Arrow.Table` is.
struct CsvTable
    columns::Dict{Symbol, Any}
end

Base.haskey(table::CsvTable, name::Symbol) = haskey(getfield(table, :columns), name)
Base.getproperty(table::CsvTable, name::Symbol) = getfield(table, :columns)[name]

# The type a .csv column of numbers is read into; no count changes a scalar field's type.
function number_type(name)
    state = SysState{1, 1, 0, 0, 1, 1, 0, MyFloat}
    hasfield(state, name) || return MyFloat
    field = fieldtype(state, name)
    field <: Number ? field : MyFloat
end

# A SysState vector goes into a .csv as `Float32[1.0, 2.0]`; every other column is a
# number.
function csv_columns(file)
    columns = Dict{Symbol, Any}()
    for name in propertynames(file)
        values = getproperty(file, name)
        columns[name] = if eltype(values) <: AbstractString
            vectors = parse_vector.(values)
            [MVector{length(first(vectors)), MyFloat}(v) for v in vectors]
        else
            convert(Vector{number_type(name)}, values)
        end
    end
    CsvTable(columns)
end

"""
    import_log(filename; frame=KA)

Read a .csv file with a flight log and return a SysLog object. Everything the returned
`SysLog` holds is `KA`, as after [`load_log`](@ref).

A .csv carries no metadata, so unlike an .arrow it cannot say which convention it was
written in and nothing can be inferred from its age. `frame` states it: a .csv that
[`export_log`](@ref) wrote from a loaded log holds `KA` and is the default; one
exported before KiteUtils 0.13 holds `KS` and needs `frame=KS`.

Parameters:
- filename: name of the file without extension.
"""
function import_log(filename; frame::FrameConvention=KA)
    # A .csv carries no column metadata, so the generic names stand.
    syslog_from_table(csv_columns(import_log_(filename)), filename,
                      default_colmeta(), frame)
end
