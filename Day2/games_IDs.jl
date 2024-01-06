#!/usr/local/bin/julia 

using ArgParse
using Distributed

aps = ArgParseSettings()
@add_arg_table aps begin
    "infile"
        help = "Input file listing games"
        required = true
    "--red"
        help = "Number of red cubes"
        required = true
        arg_type = Int
    "--green"
        help = "Number of green cubes"
        required = true
        arg_type = Int
    "--blue"
        help = "Number of blue cubes"
        required = true
        arg_type = Int
end
parsed_args = parse_args(ARGS, aps)

file = open(parsed_args["infile"], "r")
lines = readlines(file)
close(file)

function update_max(val::Int, max::Int)
    if val > max
        max = val
    end

    return max
end

function test_game(line::String, red::Int=parsed_args["red"], green::Int=parsed_args["green"], blue::Int=parsed_args["blue"])
    ID, results = split(line, ": ")
    ID = parse(Int, replace(ID, "Game "=>""))

    red_max = 0
    green_max = 0
    blue_max = 0

    for set in split(results, "; ")
        for cubes in split(set, ", ")
            value = parse(Int, split(cubes, " ")[1])
            
            if occursin("red", cubes)
                red_max = update_max(value, red_max)
            elseif occursin("green", cubes)
                green_max = update_max(value, green_max)
            elseif occursin("blue", cubes)
                blue_max = update_max(value, blue_max)
            end
        end
    end

    return (red_max <= red && green_max <= green && blue_max <= blue), ID
end

games = map(test_game, lines)
games = filter(p -> first(p) == 1, games)
total = sum([last(p) for p in games])
println(total)