include("src/args.jl")
include("src/URL.jl")
include("src/func.jl")

RESULT = OrderedSet{String}()

function ignore(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String}, chunk::Int)
    Threads.@threads for url in urls
        Url = URL(url)
        for value in Values
            UserKeyValPaires = GenerateQueryKeyVal(Keys, [value])
            SetQueryChunk(Url, UserKeyValPaires, chunk, query=Url.query)
        end
    end
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String}, chunk::Int)
    Threads.@threads for url in urls
        Url = URL(url)
        for value in Values
            UserKeyValPaires = GenerateQueryKeyVal(Keys, [value])
            # Save Parameters With New Values to Replace in URL
            kv = Dict{String,String}()
            for param in filter(!isnothing, Url.parameters_value)
                get!(kv, param, value)
            end
            params::String = Url.query
            for (k, v) in sort(kv, by=length, rev=true)
                reg::Regex = isalphanum(k) ? Regex("\\b$(escape(k))\\b") : Regex(k)
                params = replace(params, reg => v)
            end
            SetQueryChunk(Url, UserKeyValPaires, chunk, query=params)
        end
    end
end

function replace_alternative(; urls::Vector{String}, Values::Vector{String})
    Threads.@threads for url in urls
        Url = URL(url)
        params = Url.query
        for (param, value) in Iterators.product(Url.parameters_value, Values)
            reg::Regex = isalphanum(param) ? Regex("\\=\\b$(escape(param))\\b") : Regex("\\=$param")
            push!(RESULT, replace(Url.url, Url.query => replace(params, reg => "=$value")))
        end
    end
end

function suffix_all(; urls::Vector{String}, Values::Vector{String})
    Threads.@threads for url in urls
        Url = URL(url)
        for value in Values
            params = Url.query
            for (p, v) in Iterators.product(Url.parameters_value, [value])
                reg::Regex = isalphanum(p) ? Regex("\\=\\b$(escape(p))\\b") : Regex("\\=$p")
                params = replace(params, reg => join(["=", p, v]))
            end
            !isempty(params) && push!(RESULT, replace(Url.url, Url.query => params))
        end
    end
end

function suffix_alternative(; urls::Vector{String}, Values::Vector{String})
    Threads.@threads for url in urls
        Url = URL(url)
        params = Url.query
        for (param, value) in Iterators.product(Url.parameters_value, Values)
            reg::Regex = isalphanum(param) ? Regex("\\=\\b$(escape(param))\\b") : Regex("\\=$param")
            push!(
                RESULT,
                replace(Url.url, Url.query => replace(params, reg => join(["=", param, value])))
            )
        end
    end
end

function main()
    # Get User Passed CLI Argument
    arguments = ARGUMENTS()

    # Extract Arguments
    Url = arguments["url"]
    Urls = arguments["urls"] |> ReadNonEmptyLines
    KEYS = arguments["parameters"] |> ReadNonEmptyLines
    VALUES = arguments["values"] |> ReadNonEmptyLines
    CHUNK = arguments["chunk"]
    OUTPUT = arguments["output"]

    # in order not to interfere with the switches -u / -U
    if !isnothing(Url)
        url = [Url]
    elseif !isnothing(Urls)
        url = Urls
    end

    # Call When --ignore passed
    arguments["ignore"] && ignore(
        urls=url,
        Keys=KEYS,
        Values=VALUES,
        chunk=CHUNK
    )

    arguments["replace-all"] && replace_all(
        urls=url,
        Keys=KEYS,
        Values=VALUES,
        chunk=CHUNK
    )

    arguments["replace-alt"] && replace_alternative(
        urls=url,
        Values=VALUES
    )

    arguments["suffix-all"] && suffix_all(
        urls=url,
        Values=VALUES
    )

    arguments["suffix-alt"] && suffix_alternative(
        urls=url,
        Values=VALUES
    )

    if isnothing(OUTPUT)
        print(join(unique(RESULT), "\n"))
    else
        Write(OUTPUT, "w+", join(unique(RESULT), "\n"))   # if was not given -o, then print in terminal
    end
end

main()