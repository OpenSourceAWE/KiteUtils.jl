# SPDX-FileCopyrightText: 2022 Uwe Fechner
# SPDX-License-Identifier: MIT

include("_logger.jl")

"""
    Logger(P, steps; wings=1, orients=wings, bodies=orients-wings, deflections=0,
           pulleys=0, winches=1, tethers=winches, segments=0, panels=0,
           precision=MyFloat)

Pre-allocate a log for `steps` time steps of the `SysState` that
`SysState(P; wings, orients, bodies, ...)` constructs, taking the same keywords.
"""
function Logger(P, steps; wings=1, orients=wings, bodies=orients - wings,
                deflections=0, pulleys=0, winches=1, tethers=winches, segments=0,
                panels=0, precision=MyFloat)
    Logger{P, wings + bodies, wings, deflections, pulleys, winches, tethers, segments,
           panels, precision, steps}()
end

include("_log.jl")

function length(logger::Logger)
    logger.index - 1
end

include("_syslog.jl")

"""
    sys_log(logger::Logger, name="sim_log"; colmeta=default_colmeta(),
            metadata::Dict{String, String}=Dict{String, String}())

Convert the data of a `Logger` into a `SysLog`, holding the rows that were
logged, the name of the log and the column meta data. The table metadata of the
`SysLog` is `metadata` plus the creation time of the logger under the key `created`.
"""
function sys_log(logger::Logger, name="sim_log"; colmeta=default_colmeta(),
                 metadata::Dict{String, String}=Dict{String, String}())
    SysLog{logger.points}(name, colmeta, syslog(logger),
                          merge(Dict("created" => logger.created), metadata))
end

"""
    save_log(logger::Logger, name="sim_log", compress=true; path="",
             colmeta=default_colmeta(),
             metadata::Dict{String, String}=Dict{String, String}())

Save the rows that were logged as .arrow file. Compression is lz4 unless `compress`
is passed as `false`. `metadata` is written as the table metadata of the file, beside
the creation time of the logger under the key `created`, and read back by
[`load_log`](@ref). It is opaque to KiteUtils; the keys [`log_metadata`](@ref) writes
are merged over it, so a log always declares the frame convention it is in.

arrow-js does not implement IPC body decompression, so a log written with the default
lz4 compression cannot be read in a browser.
"""
function save_log(logger::Logger, name="sim_log", compress=true; path="",
                  colmeta=default_colmeta(),
                  metadata::Dict{String, String}=Dict{String, String}())
    save_log(sys_log(logger, name; colmeta, metadata), compress; path)
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
    state = SysState{1, 1, 1, 0, 0, 1, 1, 0, 0, MyFloat}
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
