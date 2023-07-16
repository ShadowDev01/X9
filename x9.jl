using ArgParse


function ARGUMENTS()
    settings = ArgParseSettings(
        prog="X9",
        description="""
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n
        **** Customize Parameters in URL(s) ***
        \n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        """
    )
    @add_arg_table settings begin
        "-u", "--url"
        help = "single url"

        "-U", "--urls"
        help = "list of urls in file"

        "-p", "--parameters"
        help = "list of parameters in file"

        "-v", "--values"
        help = "list of values in file"

        "--ignore"
        help = "does not change the default parameters, just appends the given parameters with the given values to the end of the URL"
        action = :store_true

        "--replace-all"
        help = "Replaces all default parameter's values with the given values and appends the given parameters with the given values to the end of the URL"
        action = :store_true

        "--replace-alt"
        help = "just replaces the default parameter values with the given values alternately"
        action = :store_true

        "--suffix-all"
        help = "append the given values to the end of all the default parameters"
        action = :store_true

        "--suffix-alt"
        help = "append the given values to the end of default parameters alternately"
        action = :store_true

        "--all"
        help = "do all --ignore, --replace-all, --replace-alt, --suffix-all, --suffix-alt"
        action = :store_true

        "-c", "--chunk"
        help = "maximum number of parameters in url"
        arg_type = Int
        default = 10000

        "-o", "--output"
        help = "save output in file"
    end
    parsed_args = parse_args(ARGS, settings)
    if parsed_args["all"]
        for arg in ["ignore", "replace-all", "replace-alt", "suffix-all", "suffix-alt"]
            parsed_args[arg] = true
        end
    end
    return parsed_args
end

res = String[]

function parameters(url::String)
    reg = r"[\?,\&,\;][\w\-]+[\=,\&,\;]?([\w,\-,\%,\.]+)?"
    return [i.captures[1] for i in eachmatch(reg, url)]
end

function custom_parmeters(Values::Vector{String}, Keys::Vector{String})
    keys = filter(!isempty, Keys)
    ress = String[]
    for (k, v) in Iterators.product(Keys, Values)
        if !isempty(k)
            push!(ress, "&$k=$v")
        end
    end
    return unique(ress)
end

function CHUNK(url::String, custom_params::Vector{String}, params_count::Int32, chunk::Int)
    if chunk < params_count
        @warn "chunk cant be less than default parameters count \ndefault parameters = $params_count\nchunk = $chunk"
        exit(0)
    end
    k::Int32 = abs(params_count - chunk)
    if k >= 1 && !isempty(custom_params)
        for item in Iterators.partition(custom_params, k)
            push!(res, url * join(item))
        end
    else
        push!(res, url)
    end
end

function ignore(; urls::Vector{String}, Keys::Vector{String}=[""], Values::Vector{String}, chunk::Int)
    for url in urls
        params = parameters(url)
        params_count::Int32 = length(params)
        for value in Values
            custom = custom_parmeters([value], Keys)
            CHUNK(url, custom, params_count, chunk)
        end
    end
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}=[""], Values::Vector{String}, chunk::Int)
    for url in urls
        params = parameters(url)
        params_count::Int32 = length(params)
        for value in Values
            url1 = url
            custom = custom_parmeters([value], Keys)
            kv = Dict{String,String}()
            for param in params
                get!(kv, param, value)
            end
            for (k, v) in sort([(k, v) for (k, v) in pairs(kv)], by=item -> length(item[1]), rev=true)
                url1 = replace(url1, k => v)
            end
            CHUNK(url1, custom, params_count, chunk)
        end
    end
end

function replace_alternative(; urls::Vector{String}, Values::Vector{String})
    for url in urls
        params = parameters(url)
        for (param, value) in Iterators.product(params, Values)
            reg = startswith(param, r"\w") ? Regex("\\b$param\\b") : Regex(param)
            push!(res, replace(url, reg => value))
        end
    end
end

function suffix_all(; urls::Vector{String}, Values::Vector{String})
    for url in urls
        params = parameters(url)
        for value in Values
            url1::String = url
            for (p, v) in Iterators.product(params, [value])
                reg = startswith(p, r"\w") ? Regex("\\b$p\\b") : Regex(p)
                url1 = replace(url1, reg => join([p, v]))
            end
            push!(res, url1)
        end
    end
end

function suffix_alternative(; urls::Vector{String}, Values::Vector{String})
    for url in urls
        params = parameters(url)
        for (param, value) in Iterators.product(params, Values)
            reg = startswith(param, r"\w") ? Regex("\\b$param\\b") : Regex(param)
            push!(res, replace(url, reg => join([param, value])))
        end
    end
end

function Write(filename::String, mode::String, data::String)
    open(filename, mode) do file
        write(file, data)
    end
end

function main()
    arguments = ARGUMENTS()

    if !isnothing(arguments["url"])
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

    isnothing(arguments["output"]) ? print(join(unique(res), "\n")) : Write(arguments["output"], "w+", join(unique(res), "\n"))
end

main()