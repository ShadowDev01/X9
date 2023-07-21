res = String[]

function custom_parmeters(Values::Vector{String}, Keys::Vector{String})
    ress = String[]
    for (k, v) in Iterators.product(Keys, Values)   # substitution of parameters and values given by the user then save in &parameter=value format
        push!(ress, "&$k=$v")
    end
    return unique(ress)
end

function CHUNK(url::URL, custom_params::Vector{String}, chunk::Int; edit_params::String="")
    if chunk < url.parameters_count
        @warn "chunk cant be less than default parameters count \ndefault parameters = $(url.parameters_count)\ninput chunk = $chunk\nurl = $(url._fragment)"
        exit(0)
    end
    edit_params = edit_params == "?" ? "" : edit_params
    Empty = isempty(edit_params) ? true : false
    k::Int32 = abs(url.parameters_count - chunk)   # makes sure that the chunk value in each URL is exactly the user input value: default parameters + input parameters = chunk
    if k >= 1 && !isempty(custom_params)
        for item in Iterators.partition(custom_params, k)
            if Empty
                if chunk == 1 || length(item) == 1
                    item = replace.(item, "&" => "?")
                else
                    item[1] = replace(item[1], "&" => "?")
                end
            end
            push!(res, url._path * edit_params * join(item) * url.fragment)
        end
    else
        push!(res, url._path * edit_params * url.fragment)
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