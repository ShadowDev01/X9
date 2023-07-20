res = String[]

function custom_parmeters(Values::Vector{String}, Keys::Vector{String}; Empty::Bool=false)
    ress = String[]
    for (k, v) in Iterators.product(Keys, Values)   # substitution of parameters and values given by the user then save in &parameter=value format
        push!(ress, "&$k=$v")
    end
    Empty && (ress[1] = replace(ress[1], "&" => "?"))
    return unique(ress)
end

function CHUNK(Front::String, custom_params::Vector{String}, params_count::Int32, chunk::Int; edit_params::String="", Tail::String="")
    if chunk < params_count
        @warn "chunk cant be less than default parameters count \ndefault parameters = $params_count\ninput chunk = $chunk\nurl = $url"
        exit(0)
    end
    k::Int32 = abs(params_count - chunk)   # makes sure that the chunk value in each URL is exactly the user input value: default parameters + input parameters = chunk
    if k >= 1 && !isempty(custom_params)
        for item in Iterators.partition(custom_params, k)   # Breaks the input parameters into the given number to make sure chunk be correct
            push!(res, Front * edit_params * join(item) * Tail)
        end
    else
        push!(res, url)
    end
end

function escape(st::AbstractString)
    replace(st, "(" => "\\(", ")" => "\\)", "[" => "\\[", "]" => "\\]", "{" => "\\{", "}" => "\\}")
end

function Write(filename::String, mode::String, data::String)
    open(filename, mode) do file
        write(file, data)
    end
end