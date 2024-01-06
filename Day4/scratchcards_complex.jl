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
    #ID_long
    _, numbers_long = split(card, ":")
    #ID = parse(Int, replace(ID_long, "Card "=>""))
    numbers = map(i -> parse(Int, i), filter((i) -> i != "", split(numbers_long, " ")))
    legend = map(i -> parse(Int, i), filter((i) -> i != "", split(legend_long, " ")))
    count = sum(map(i -> i in legend, numbers))

    return count
end

cards = map(process_card, lines)


final_card = length(cards)
multipliers = Dict(c => 1 for c = 1:length(cards))

for (card, count) in enumerate(cards)

    maximum = (card + count < final_card) ? card + count : final_card
    println("Card $card: count $count, maximum $maximum")
    extra_cards = maximum - card
    for extra_card in (card+1):maximum
        println("ex: $extra_card")
        multipliers[extra_card] += 1 * multipliers[card]
    end
end

total = sum(values(multipliers))
println("Total: $total")