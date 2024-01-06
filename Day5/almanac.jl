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

function parse_almanac(lines::Vector{String})

    lines = collect(Iterators.flatten(map(line -> split(line, ":"), lines)))
    filter!((i) -> i != "", lines)

    tag = ""
    contents = Vector{String}()
    almanac = Dict{String, Vector{String}}()
    for line in lines
        if any(isletter, line)
            if ~isempty(tag)
                merge!(almanac, Dict(tag=>contents))
            end
            tag = line
            contents = Vector{String}()
        else
            push!(contents, line)
        end
    end

    return almanac
end

function decode(code)

    dest_start, source_start, range_length = map(i -> parse(Int, i), split(code, " "))

    sources = source_start:(source_start + range_length - 1)
    dests = dest_start:(dest_start + range_length - 1)

    return Dict(zip(sources, dests))
end

function decode_almanac(almanac)
    decoded_almanac = Dict()
    for (key, record) in almanac
        if occursin("map", key)
            decoded_almanac[key] = merge(+, collect(map(decode, record))...)
        elseif key == "seeds"
            decoded_almanac[key] = map(i -> parse(Int, i), filter((i) -> i != "", split(record[1], " ")))
        end
    end

    return decoded_almanac
end

function construct_keylink(almanac)
    keylink = Dict()
    for key in keys(almanac)
        if occursin("map", key)
            _, dest_key = split(replace(key, " map"=>""), "-to-")
            for target_key in keys(almanac)
                if startswith(target_key, dest_key)
                    keylink[key] = target_key
                end
            end
        end
        
    end
    return keylink
end


almanac = parse_almanac(lines)
#println(almanac)
almanac = decode_almanac(almanac)
#println(almanac)
keylink = construct_keylink(almanac)
println(keylink)