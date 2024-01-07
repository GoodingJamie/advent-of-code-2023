#!/usr/local/bin/julia 

using ArgParse

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
    filter!(i -> i != "", lines)

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


function decode_almanac(almanac)

    function decode(code)

        dest_start, source_start, range_length = map(i -> parse(Int, i), split(code, " "))
        sources = source_start:(source_start + range_length - 1)
        dests = dest_start:(dest_start + range_length - 1)
    
        return Dict(zip(sources, dests))
    end

    function decode_record(key, record)

        if occursin("map", key)
            return Dict(key=>merge(+, collect(map(decode, record))...))
        elseif key == "seeds"
            return Dict(key=>map(i -> parse(Int, i), filter((i) -> i != "", split(record[1], " "))))
        end
    end

    if parsed_args["multi-threading"]
        return merge(+, collect(pmap((key, record) -> decode_record(key, record), pool, keys(almanac), values(almanac), distributed=false))...)
    else
        return merge(+, collect(map((key, record) -> decode_record(key, record), keys(almanac), values(almanac)))...)
    end

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
@time almanac = decode_almanac(almanac)
println("Almanac decoded")
@time keylink = construct_keylink(almanac)
println("Keylink constructed")



function locate_seed(value, almanac, keylink)
    key_from = "seeds"
    while ~occursin("location", key_from)
        key_to = keylink[key_from]
        if value in keys(almanac[key_to])
            value = almanac[key_to][value]
        end
        key_from = key_to
    end
    return value
end

seeds = almanac["seeds"]
locator(seed) = locate_seed(seed, almanac, keylink)
if parsed_args["multi-threading"]
    @time locations = pmap(locator, pool, seeds, distributed=false)
else
    @time locations = map(locator, seeds)
end
println(locations)