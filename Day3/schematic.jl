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

line_length = length(lines[1])
num_lines = length(lines)
schematic = reduce(*, lines)

function calculate_position(n::Int, x_length::Int=line_length)
    i = n % x_length
    i = i > 0 ? i : x_length
    j = (n - i + 1) ÷ x_length
    return i, j
end

function scan(string::String, n::Int, x_length::Int=line_length, y_length::Int=num_lines)
    hit = false
    position = calculate_position(n, x_length)
    for (di, dj) in Iterators.product((-1, 0, 1), (-1, 0, 1))
        if ~(di == 0 && dj == 0) # Rule out original character
            test_i = position[1] + di
            test_j = position[2] + dj
            if test_i > 0 && test_i < line_length && test_j > 0 && test_j < num_lines
                if occursin(string[test_i + test_j * x_length], "@%&#*\$+=-/")
                    hit = true
                end
            end
        end
    end
    return hit
end

function find_numbers(schematic::String, x_length::Int)
    numbers = Dict{String,Vector{Int}}()
    last_numeric = true

    number = ""
    positions = Vector{Int}()
    for (n, char) in enumerate(schematic)
        if isdigit(char)
            last_numeric = true
            number *= char
            push!(positions, n)
        end
        
        if (n + 1) % x_length == 0 || ~isdigit(char)
            if last_numeric
                merge!(numbers, Dict(number=>positions))
                number = ""
                positions = Vector{Int}()
            end
            last_numeric = false
        end
    end

    return numbers
end

function find_hits(schematic::String)

    pos_scan(pos) = scan(schematic, pos)
    return filter(pos_scan, 1:length(schematic))
end

hits = find_hits(schematic)
numbers = find_numbers(schematic, line_length)

total = 0
for (number, number_positions) in numbers
    hit = false
    for position in number_positions
        if position in hits
            hit = true
        end
    end
    if hit
        global total += parse(Int, number)
    end
end

println("Total: $total")
        