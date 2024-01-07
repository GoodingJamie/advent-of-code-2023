#!/usr/local/bin/julia 

using ArgParse
using Distributed

aps = ArgParseSettings()
@add_arg_table aps begin
    "infile"
        help = "Input file listing games"
        required = true
end
parsed_args = parse_args(ARGS, aps)

file = open(parsed_args["infile"], "r")
lines = readlines(file)
close(file)

ACCELERATION = 1 # To-do: move to arguments

function parse_race(time, distance)
    
    discriminant = sqrt(time^2 - 4 * distance / ACCELERATION) 
    time_min = floor((time - discriminant) / 2)
    time_max = ceil((time + discriminant) / 2)

    return Int(time_max - time_min - 1) # -1 = +1 for counting from 0, -2 for each end (0 distance)
end

distances = []
times = []
for line in lines
    if occursin("Time", line)
        global times = map(i -> parse(Int, i), filter!(i -> isa(tryparse(Int, i), Number), split(line, " ")))
    elseif occursin("Distance", line)
        global distances = map(i -> parse(Int, i), filter!(i -> isa(tryparse(Int, i), Number), split(line, " ")))
    end
end

options = map(parse_race, times, distances)
println("Result: $(prod(options))")
