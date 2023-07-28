include("src/args.jl")
include("src/URL.jl")
include("src/func.jl")


function ignore(; urls::Vector{String}, Keys::Vector{String}=[""], Values::Vector{String}, chunk::Int)
    Values = filter(!isempty, Values)
    Keys = filter(!isempty, Keys)
    Threads.@threads for url in urls
        Url = URL(url)
        for value in Values
            custom::Vector{String} = custom_parmeters([value], Keys)
            CHUNK(Url, custom, chunk, edit_params=Url.query)
        end
    end
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}=[""], Values::Vector{String}, chunk::Int)
    Values = filter(!isempty, Values)
    Keys = filter(!isempty, Keys)
    Threads.@threads for url in urls
        Url = URL(url)
        for value in Values
            custom::Vector{String} = custom_parmeters([value], Keys)
            kv = Dict{String,String}()   # use a custom dictionary to save parameters with new values to replace in url
            for param in filter(!isnothing, Url.parameters_value)
                get!(kv, param, value)
            end
            kv = sort([(k, v) for (k, v) in pairs(kv)], by=item -> length(item[1]), rev=true)
            params::String = Url.query
            for (k, v) in kv
                reg::Regex = isalphanum(k) ? Regex("\\b$(escape(k))\\b") : Regex(k)
                params = replace(params, reg => v)
            end
            CHUNK(Url, custom, chunk, edit_params=params)
        end
    end
end

function replace_alternative(; urls::Vector{String}, Values::Vector{String})
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        Url = URL(url)
        params = Url.query
        for (param, value) in Iterators.product(Url.parameters_value, Values)
            reg::Regex = isalphanum(param) ? Regex("\\=\\b$(escape(param))\\b") : Regex("\\=$param")   # use regex to make sure that values replace correctly
            push!(res, Url._path * replace(params, reg => "=$value") * Url.fragment)
        end
    end
end

function suffix_all(; urls::Vector{String}, Values::Vector{String})
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        Url = URL(url)
        for value in Values
            params = Url.query
            for (p, v) in Iterators.product(Url.parameters_value, [value])
                reg::Regex = isalphanum(p) ? Regex("\\=\\b$(escape(p))\\b") : Regex("\\=$p")
                params = replace(params, reg => join(["=", p, v]))
            end
            !isempty(params) && push!(res, join([Url._path, params, Url.fragment]))
        end
    end
end

function suffix_alternative(; urls::Vector{String}, Values::Vector{String})
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        Url = URL(url)
        params = Url.query
        for (param, value) in Iterators.product(Url.parameters_value, Values)
            reg::Regex = isalphanum(param) ? Regex("\\=\\b$(escape(param))\\b") : Regex("\\=$param")
            push!(res, join([Url._path, replace(params, reg => join(["=", param, value])), Url.fragment]))
        end
    end
end

function main()
    arguments = ARGUMENTS()

    if !isnothing(arguments["url"])   # in order not to interfere with the switches -u / -U
        url = [arguments["url"]]
    elseif !isnothing(arguments["urls"])
        url = readlines(arguments["urls"])
    end

    arguments["ignore"] && ignore(
        urls=url,
        Keys=readlines(arguments["parameters"]),
        Values=readlines(arguments["values"]),
        chunk=arguments["chunk"]
    )

    arguments["replace-all"] && replace_all(
        urls=url,
        Keys=readlines(arguments["parameters"]),
        Values=readlines(arguments["values"]),
        chunk=arguments["chunk"]
    )

    arguments["replace-alt"] && replace_alternative(
        urls=url,
        Values=readlines(arguments["values"])
    )

    arguments["suffix-all"] && suffix_all(
        urls=url,
        Values=readlines(arguments["values"])
    )

    arguments["suffix-alt"] && suffix_alternative(
        urls=url,
        Values=readlines(arguments["values"])
    )

    isnothing(arguments["output"]) ? print(join(unique(res), "\n")) : Write(arguments["output"], "w+", join(unique(res), "\n"))   # if was not given -o, then print in terminal
end

main()