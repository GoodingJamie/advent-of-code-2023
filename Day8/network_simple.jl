#!/usr/local/bin/julia 

using ArgParse
using DataStructures

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

function process_input(line)
    if occursin("=", line)
        key, dests = split(line, " = ")
        left, right = split(replace(dests, "(" => "", ")" => ""), ", ")
        return Dict(key => Dict(
            'L' => left,
            'R' => right
        ))
    elseif ~isempty(line)
        return line
    end
    return ""
end

processed_lines = map(process_input, lines)
instructions, _, nodes... = processed_lines
network = merge(+, collect(nodes)...)

n = 0
key = "AAA"
while key != "ZZZ"
    global key = network[key][instructions[n % length(instructions) + 1]]
    global n += 1
end
println("Reached ZZZ after $n steps")
