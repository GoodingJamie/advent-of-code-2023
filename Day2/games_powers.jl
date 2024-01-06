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

function update_min(val::Int, min::Int)
    if val > min
        min = val
    end

    return min
end

function calculate_power(line::String)
    _, results = split(line, ": ")

    red_min = 1
    green_min = 1
    blue_min = 1

    for set in split(results, "; ")
        for cubes in split(set, ", ")
            value = parse(Int, split(cubes, " ")[1])
            
            if occursin("red", cubes)
                red_min = update_min(value, red_min)
            elseif occursin("green", cubes)
                green_min = update_min(value, green_min)
            elseif occursin("blue", cubes)
                blue_min = update_min(value, blue_min)
            end
        end
    end

    return red_min * green_min * blue_min
end

powers = map(calculate_power, lines)
total = sum(powers)
println(total)
