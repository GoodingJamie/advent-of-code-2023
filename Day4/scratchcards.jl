#!/usr/local/bin/julia 

using ArgParse

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

function process_card(line::String)

    card, legend_long = split(line, "|")
    _, numbers_long = split(card, ":")
    numbers = map(i -> parse(Int, i), filter((i) -> i != "", split(numbers_long, " ")))
    legend = map(i -> parse(Int, i), filter((i) -> i != "", split(legend_long, " ")))
    count = sum(map(i -> i in legend, numbers))

    return (count > 0) ? 2 ^ (count - 1) : 0
end

total = sum(map(process_card, lines))
println("Total: $total")
