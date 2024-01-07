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

function parse_line(line::String)
    hand, bid = split(line, " ")
    return hand, parse(Int, bid)
end



struct Hand
    hand::String    # Hand as per the string
    bid::Int        # Bid
    classification::Int
end

function classify_hand(hand)
    counts = values(counter(hand))
    if maximum(counts) == 1
        return 0
    elseif maximum(counts) == 2
        if length(counts) == 4
            return 1
        end
        return 2
    elseif maximum(counts) == 3
        if length(counts) == 3
            return 3
        end # Full house
        return 4
    elseif maximum(counts) == 4
        return 5
    end
    return 6
end

Hand(hand, bid) = Hand(hand, bid, classify_hand(hand))
Hand(line::String) = Hand(parse_line(line)...)

hands = map(Hand, lines)

KEY = Dict(
    'T'=>10,
    'J'=>11,
    'Q'=>12,
    'K'=>13,
    'A'=>14
)

function convert_char(char::Char)
    if isnumeric(char)
        return parse(Int, char)
    else
        return KEY[char]
    end
end

for pos in 5:-1:1
    sort!(hands, by = h -> convert_char(h.hand[pos]))
end
sort!(hands, by = h -> h.classification)
result = sum(map((n, h) -> n * h.bid, (1:length(hands)), hands))
println("Result: $result")