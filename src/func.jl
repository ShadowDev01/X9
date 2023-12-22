# Read File and Return Non Empty Lines 
# If File Not Exist, Show Error and Exit
function ReadNonEmptyLines(FilePath::String)
    if isfile(FilePath)
        filter(!isempty, readlines(FilePath))
    else
        @error "Not Such File or Directory: $FilePath"
        exit(0)
    end
end

# Generates Key-Value Pairs in the Format “Key=Value” for Use in Query Strings
function GenerateQueryKeyVal(Keys::Vector{String}, Values::Vector{String})
    result = OrderedSet{String}()
    for (key, value) in Iterators.product(Keys, Values)
        push!(result, "&$key=$value")
    end
    return result
end

function escape(input::AbstractString)
    replace(input, "(" => "\\(", ")" => "\\)", "[" => "\\[", "]" => "\\]", "{" => "\\{", "}" => "\\}")
end

isalphanum(s::String) = startswith(s, r"\w") && endswith(s, r"\w")

function Write(filename::String, mode::String, data::String)
    open(filename, mode) do file
        write(file, data)
    end
end

# Set Given Query Parameters Count In URL
function SetQueryChunk(url::URL, user_keyval_pairs::OrderedSet{String}, chunk::Int; query::String="")
    if chunk < url.parameters_count
        @warn "chunk cant be less than default parameters count \ndefault parameters = $(url.parameters_count)\ninput chunk = $chunk\nurl = $(url._fragment)"
        exit(0)
    end

    # check query is empty
    query = query == "?" ? "" : query

    # Makes Sure => Default Parameters + Input Parameters = Chunk
    k = abs(url.parameters_count - chunk)

    if k >= 1 && !isempty(user_keyval_pairs)
        for item in Iterators.partition(user_keyval_pairs, k)
            if isempty(query)
                if (chunk == 1) || (length(item) == 1)
                    item = replace.(item, "&" => "?")
                else
                    item[1] = replace(item[1], "&" => "?")
                end
            end
            push!(RESULT, replace(url.url, url.query => query * join(item)))
        end
    else
        push!(RESULT, replace(url.url, url.query => query))
    end
end