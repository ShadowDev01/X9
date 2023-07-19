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
    reg = r"\=([\w\-\%\.\:\~\,\"\'\<\>\=\(\)\`\{\}\$\+\/\;]+)?"   # extract the value of default parameters in url
    return [i.captures[1] for i in eachmatch(reg, "?$url")]
end

function chunks_count(url::String)
    reg = r"[\?\&\;]([\w\-\~\+]+)"
    return length(collect(eachmatch(reg, url)))
end

function custom_parmeters(Values::Vector{String}, Keys::Vector{String})
    Keys = filter(!isempty, Keys)
    ress = String[]
    for (k, v) in Iterators.product(Keys, Values)   # substitution of parameters and values given by the user then save in &parameter=value format
        push!(ress, "&$k=$v")
    end
    return unique(ress)
end

function CHUNK(url::String, custom_params::Vector{String}, params_count::Int32, chunk::Int)
    if chunk < params_count
        @warn "chunk cant be less than default parameters count \ndefault parameters = $params_count\nchunk = $chunk"
        exit(0)
    end
    k::Int32 = abs(params_count - chunk)   # makes sure that the chunk value in each URL is exactly the user input value: default parameters + input parameters = chunk
    if k >= 1 && !isempty(custom_params)
        for item in Iterators.partition(custom_params, k)   # Breaks the input parameters into the given number to make sure chunk be correct
            push!(res, url * join(item))
        end
    else
        push!(res, url)
    end
end

function escape(st::AbstractString)
    replace(st, "(" => "\\(", ")" => "\\)", "[" => "\\[", "]" => "\\]", "{" => "\\{", "}" => "\\}")
end

function ignore(; urls::Vector{String}, Keys::Vector{String}=[""], Values::Vector{String}, chunk::Int)
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        url1::String, url2::String = split(url, "?", limit=2)
        params = parameters(url2)
        params_count::Int32 = chunks_count(url2)
        for value in Values
            custom::Vector{String} = custom_parmeters([value], Keys)
            CHUNK(url, custom, params_count, chunk)
        end
    end
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}=[""], Values::Vector{String}, chunk::Int)
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        url1::String, url2::String = split(url, "?", limit=2)
        params = parameters(url2)
        params_count::Int32 = chunks_count(url2)
        for value in Values
            url3 = url2
            custom::Vector{String} = custom_parmeters([value], Keys)
            kv = Dict{String,String}()   # use a custom dictionary to save parameters with new values to replace in url
            for param in filter(!isnothing, params)
                get!(kv, param, value)
            end
            kv = sort([(k, v) for (k, v) in pairs(kv)], by=item -> length(item[1]), rev=true)
            for (k, v) in kv
                reg::Regex = startswith(k, r"\w") ? Regex("\\b$(escape(k))\\b") : Regex(k)
                url3 = replace(url3, reg => v)
            end
            CHUNK(join([url1, "?", url3]), custom, params_count, chunk)
        end
    end
end

function replace_alternative(; urls::Vector{String}, Values::Vector{String})
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        url1::String, url2::String = split(url, "?", limit=2)
        params = filter(!isnothing, parameters(url2))
        for (param, value) in Iterators.product(params, Values)
            reg::Regex = startswith(param, r"\w") ? Regex("\\=\\b$(escape(param))\\b") : Regex("\\=$param")   # use regex to make sure that values replace correctly
            push!(res, join([url1, "?", replace(url2, reg => join(["=", value]))]))
        end
    end
end

function suffix_all(; urls::Vector{String}, Values::Vector{String})
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        url1::String, url2::String = split(url, "?", limit=2)
        params = sort(filter(!isnothing, parameters(url2)), rev=true)
        for value in Values
            url3 = url2
            for (p, v) in Iterators.product(params, [value])
                reg::Regex = startswith(p, r"\w") ? Regex("\\=\\b$(escape(p))\\b") : Regex("\\=$p")
                url3 = replace(url3, reg => join(["=", p, v]))
            end
            push!(res, join([url1, "?", url3]))
        end
    end
end

function suffix_alternative(; urls::Vector{String}, Values::Vector{String})
    Values = filter(!isempty, Values)
    Threads.@threads for url in urls
        url1::String, url2::String = split(url, "?", limit=2)
        params = filter(!isnothing, parameters(url2))
        for (param, value) in Iterators.product(params, Values)
            reg::Regex = startswith(param, r"\w") ? Regex("\\=\\b$(escape(param))\\b") : Regex("\\=$param")
            push!(res, join([url1, "?", replace(url2, reg => join(["=", param, value]))]))
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