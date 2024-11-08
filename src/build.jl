# code to create the file sysstate.jl (and later a lot more)
using YAML, OrderedCollections

include("yaml_utils.jl")

HEADER = """
\"\"\"
    SysState{P}

Basic system state. One of these is saved per time step. P is the number
of tether particles.

\$(TYPEDFIELDS)
\"\"\"
Base.@kwdef mutable struct SysState{P}"""
FOOTER = "end"
inputfile = joinpath("data", "sysstate.yaml")
outputfile = joinpath("src", "_sysstate.jl")
outputfile2 = joinpath("src", "_show.jl")
outputfile3 = joinpath("src", "_demo_syslog.jl")
outputfile4 = joinpath("src", "_logger.jl")
outputfile5 = joinpath("src", "_log.jl")
outputfile6 = joinpath("src", "_syslog.jl")
outputfile7 = joinpath("src", "_save_log.jl")

# read the file sysstate.yaml
sysstate = YAML.load_file(inputfile, dicttype=OrderedDict{String,Any})["sysstate"]
lines = readfile(inputfile)
open(outputfile,"w") do io
    println(io, HEADER)
    for key in keys(sysstate)
        comment = get_comment(lines, key)
        println(io, "    " * comment)
        default = "= 0"
        if sysstate[key] == "MVector{4, Float32}"
            default = "= [1.0, 0.0, 0.0, 0.0]"
        elseif sysstate[key] == "MVector{3, MyFloat}"
            default = "= [0.0, 0.0, 0.0]"
        elseif sysstate[key] == "MVector{P, MyFloat}"
            default = "= zeros(P)"
        end
        println(io, "    " * key * "::" * sysstate[key] * " " * default)   
    end
    println(io, FOOTER)
end
HEADER = "function Base.show(io::IO, st::SysState)" 
open(outputfile2,"w") do io
    println(io, HEADER)
    for key in keys(sysstate)
        unit = get_unit(lines, key)
        description = rpad(key * " " * unit * ":", 19, " ") 
        println(io, "    println(io, \"" * description * "\", st." * key * ")")
    end
    println(io, "end")
end
HEADER = """
\"\"\"
    demo_syslog(P, name="Test flight"; duration=10)

Create a demo flight log  with given name [String] and duration [s] as StructArray. P is the number of tether
particles.
\"\"\"
function demo_syslog(P, name="Test flight"; duration=10)
    max_height = 6.03
    steps   = Int(duration * se().sample_freq) + 1
"""
open(outputfile3,"w") do io
    print(io, HEADER)
    for key in keys(sysstate)
        println(io, "    " * key * "_vec = Vector{" * sysstate[key] * "}(undef, steps)")
    end
    println(io, "    for i in range(0, length=steps)")
    println(io, "        state = demo_state(P, max_height * i/steps, i/se().sample_freq)")
    println(io, "        elevation_vec[i+1] = asin(state.Z[end]/state.X[end])")
    for key in keys(sysstate)
        println(io, "        " * key * "_vec[i+1] = state." * key)
    end
    println(io, "    end")
    print(io, "    StructArray{SysState{P}}((")
    for (i, key) in pairs(collect(keys(sysstate)))
        if i == length(keys(sysstate))
            print(io, key * "_vec")
        else
            print(io, key * "_vec, ")
        end
        if i % 6 == 0
            print(io, "\n" * " " ^ 30)   
        end
    end
    println(io, "))")
    println(io, "end")
end
HEADER = """
\"\"\"
    mutable struct Logger{P, Q}

Struct to store a simulation log. P is number of points of the tether, segments+1 and 
Q is the number of time steps that will be pre-allocated.

Constructor:
- Logger(P, steps)

Fields:

\$(TYPEDFIELDS)
\"\"\"
@with_kw mutable struct Logger{P, Q}
    points::Int64 = P
    index::Int64 = 1
"""
open(outputfile4,"w") do io
    print(io, HEADER)
    for key in keys(sysstate)
        println(io, "    " * key * "_vec::Vector{" * sysstate[key] * "} = zeros(" * sysstate[key] * ", Q)")
    end
    println(io, "end")
end
HEADER = """
\"\"\"
    log!(logger::Logger, state::SysState)

Log a state in a logger object. Do nothing if the preallocated size would be exceeded.
Returns the current number of elements of the log.
\"\"\"
function log!(logger::Logger, state::SysState)
    i = logger.index
    if i > length(logger.time_vec)
        return length(logger.time_vec)
    end
"""
open(outputfile5,"w") do io
    print(io, HEADER)
    for key in keys(sysstate)
        println(io, "    logger." * key * "_vec[i] = state." * key)
    end
    println(io, "    logger.index+=1")
    println(io, "    return i")
    println(io, "end")
end
HEADER = """
function syslog(logger::Logger)
    l = logger
    StructArray{SysState{l.points}}(("""
open(outputfile6,"w") do io
    print(io, HEADER)
    for (i, key) in pairs(collect(keys(sysstate)))
        if i == length(keys(sysstate))
            print(io, "l." * key * "_vec")
        else
            print(io, "l." * key * "_vec, ")
        end
        if i % 5 == 0
            print(io, "\n" * " " ^ 37)   
        end
    end
    println(io, "))")
    println(io, "end")
end
HEADER = """
\"\"\"
    save_log(logger::Logger, name="sim_log", compress=true;
                path="",
                colmeta = Dict(:var_01 => ["name" => "var_01"],
                               :var_02 => ["name" => "var_02"],
                               :var_03 => ["name" => "var_03"],
                               :var_04 => ["name" => "var_04"],
                               :var_05 => ["name" => "var_05"],
                               :var_06 => ["name" => "var_06"],
                               :var_07 => ["name" => "var_07"],
                               :var_08 => ["name" => "var_08"],
                               :var_09 => ["name" => "var_09"],
                               :var_10 => ["name" => "var_10"],
                               :var_11 => ["name" => "var_11"],
                               :var_12 => ["name" => "var_12"],
                               :var_13 => ["name" => "var_13"],
                               :var_14 => ["name" => "var_14"],
                               :var_15 => ["name" => "var_15"],
                               :var_16 => ["name" => "var_16"]
            ))

Save a fligh log from a logger as .arrow file. By default lz4 compression is used, 
if you use **false** as second parameter no compression is used.
\"\"\"
function save_log(logger::Logger, name="sim_log", compress=true;
    path="",
    colmeta = Dict(:var_01 => ["name" => "var_01"],
                   :var_02 => ["name" => "var_02"],
                   :var_03 => ["name" => "var_03"],
                   :var_04 => ["name" => "var_04"],
                   :var_05 => ["name" => "var_05"],
                   :var_06 => ["name" => "var_06"],
                   :var_07 => ["name" => "var_07"],
                   :var_08 => ["name" => "var_08"],
                   :var_09 => ["name" => "var_09"],
                   :var_10 => ["name" => "var_10"],
                   :var_11 => ["name" => "var_11"],
                   :var_12 => ["name" => "var_12"],
                   :var_13 => ["name" => "var_13"],
                   :var_14 => ["name" => "var_14"],
                   :var_15 => ["name" => "var_15"],
                   :var_16 => ["name" => "var_16"]
                  ))
    nl = length(logger)
"""
open(outputfile7,"w") do io
    print(io, HEADER)
    for key in keys(sysstate)
        println(io, "    resize!(logger." * key * "_vec, nl)")
    end

    println(io, "    flight_log = (sys_log(logger, name; colmeta))")
    println(io, "    save_log(flight_log, compress; path)")
    println(io, "end")
end