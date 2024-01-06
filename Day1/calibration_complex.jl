#!/usr/local/bin/julia 

using ArgParse
using Distributed

aps = ArgParseSettings()
@add_arg_table aps begin
    "infile"
        help = "Input file for calibration"
        required = true
    "--multi-threading"
        help = "Enable multi-threaded mode (only recommended for large files)."
        action = :store_true
end
parsed_args = parse_args(ARGS, aps)

file = open(parsed_args["infile"], "r")
lines = readlines(file)
close(file)

function get_vals(line::String)
    println(line)
    sanitise = Dict("oneight"=>"oneeight", "threeight"=>"threeeight", "fiveight"=>"fiveeight", "nineight"=>"nineeight", "twone"=>"twoone", "sevenine"=>"sevennine", "eightwo"=>"eighttwo")
    line = replace(line, sanitise...)
    digits = Dict("one"=>"1", "two"=>"2", "three"=>"3", "four"=>"4", "five"=>"5", "six"=>"6", "seven"=>"7", "eight"=>"8", "nine"=>"9")
    line = replace(line, digits...)
    println(line)
    
    first = 0
    for char in line
        if isdigit(char)
            first = parse(Int, char)
            break
        end
    end

    last = 0
    for char in reverse(line)
        if isdigit(char)
            last = parse(Int, char)
            break
        end
    end

    if first == 0 | last == 0
        println("honk")
    end
    println(first * 10 + last)
    return first * 10 + last
end

if parsed_args["multi-threading"]
    println("Multi-threading enabled, using pmap instead of map.")
    pool = CachingPool(workers())
    vals = pmap(get_vals, pool, lines, distributed=false)
else 
    vals = map(get_vals, lines)
end

total = sum(vals)
println("Final calibration value: $total")