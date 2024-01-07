#!/usr/local/bin/julia 

using ArgParse
using Distributed

aps = ArgParseSettings()
@add_arg_table aps begin
    "infile"
        help = "Input file listing games"
        required = true
    "--multi-threading"
        help = "Enable multi-threaded mode (only recommended for large files)."
        action = :store_true
end
parsed_args = parse_args(ARGS, aps)

if parsed_args["multi-threading"]
    println("Multi-threading enabled, using pmap instead of map.")
    pool = CachingPool(workers())
end

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
    if ~isempty(tag)
        merge!(almanac, Dict(tag=>contents))
    end

    return almanac
end

function construct_keylink(almanac)
    keylink = Dict()
    for key in keys(almanac)
        if occursin("map", key)
            _, dest_key = split(replace(key, " map"=>""), "-to-")
            if dest_key == "location"
                keylink[key] = "location"
            else
                for target_key in keys(almanac)
                    if startswith(target_key, dest_key)
                        keylink[key] = target_key
                    end
                end
            end
        elseif key == "seeds"
            for target_key in keys(almanac)
                if startswith("seed", target_key)
                    keylink[key] = target_key
                end
            end
            keylink[key] = "seed-to-soil map"
        end
    end
    return keylink
end

@time almanac = parse_almanac(lines)
println("Almanac constructed")
@time keylink = construct_keylink(almanac)
println("Keylink constructed")


function find_from_record(value, record)

    for relation in record
        dest, source, range = map(i -> parse(Int, i), split(relation, " "))
        if value >= source && value < source + range
            return dest + value - source
        end
    end
    
    return value
end

function locate_seed(value, almanac, keylink)
    key_from = "seeds"
    while ~occursin("location", key_from)
        value = find_from_record(value, almanac[keylink[key_from]])
        key_from = keylink[key_from]
    end
    return value
end

seeds = map(i -> parse(Int, i), filter(i -> i != "", split(almanac["seeds"]..., " ")))
locator(seed) = locate_seed(seed, almanac, keylink)

# Map over all of the seeds
if parsed_args["multi-threading"]
    @time locations = pmap(locator, pool, seeds, distributed=false)
else
    @time locations = map(locator, seeds)
end
minimum = locations[argmin(locations)]

println("Locations found: $locations")
println("Minimum location: $minimum")