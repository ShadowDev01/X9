include("src/args.jl")
include("src/URL.jl")
include("src/func.jl")


# user cli arguments
const arg = ARGUMENTS()

# final results to print
RESULT = OrderedSet{String}()


function ignore(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String}, chunk::Int)
	Threads.@threads for url in urls
		Url = URL(url)
		for value in Values
			UserKeyValPaires = GenerateQueryKeyVal(Keys, [value])
			SetQueryChunk(Url, UserKeyValPaires, chunk, query = Url.query)
		end
	end
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String}, chunk::Int)
	Threads.@threads for url in urls
		Url = URL(url)
		for value in Values
			UserKeyValPaires = GenerateQueryKeyVal(Keys, [value])
			# Save Parameters With New Values to Replace in URL
			kv = Dict{String, String}()
			for param in filter(!isnothing, Url.parameters_value)
				get!(kv, param, value)
			end
			params::String = Url.query
			for (k, v) in sort(kv, by = length, rev = true)
				reg::Regex = isalphanum(k) ? Regex("\\b$(escape(k))\\b") : Regex(k)
				params = replace(params, reg => v)
			end
			SetQueryChunk(Url, UserKeyValPaires, chunk, query = params)
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
				replace(Url.url, Url.query => replace(params, reg => join(["=", param, value]))),
			)
		end
	end
end

function main()
	Check_Dependencies()
	printstyled(banner, color = :light_red)

	# Extract arg
	URLS = String[]
	CHUNK = arg["chunk"]
	OUTPUT = arg["output"]
	KEYS = !isnothing(arg["parameters"]) ? ReadNonEmptyLines(arg["parameters"]) : String[]
	VALUES = !isnothing(arg["values"]) ? ReadNonEmptyLines(arg["values"]) : String[]


	# in order not to interfere with the switches -u / -U
	if !isnothing(arg["url"])
		URLS = isempty(arg["url"]) ? String[] : [arg["url"]]
	elseif !isnothing(arg["urls"])
		URLS = arg["urls"] |> ReadNonEmptyLines
	end

	if isempty(URLS)
		@warn "provide some url(s) please! 😕"
		exit(0)
	end

	@info "$colorYellow$(length(URLS))$colorReset candidate url(s) detected ✅"

	if !any([
		arg["ignore"],
		arg["rep-all"],
		arg["rep-alt"],
		arg["suf-all"],
		arg["suf-alt"],
	])
		@warn "choose any switch options ex: --ignore / ..."
		exit(0)
	end

	@info "Generating urls 🛠️"
	# Call When --ignore passed
	arg["ignore"] && ignore(
		urls = URLS,
		Keys = KEYS,
		Values = VALUES,
		chunk = CHUNK,
	)

	arg["rep-all"] && replace_all(
		urls = URLS,
		Keys = KEYS,
		Values = VALUES,
		chunk = CHUNK,
	)

	arg["rep-alt"] && replace_alternative(
		urls = URLS,
		Values = VALUES,
	)

	arg["suf-all"] && suffix_all(
		urls = URLS,
		Values = VALUES,
	)

	arg["suf-alt"] && suffix_alternative(
		urls = URLS,
		Values = VALUES,
	)

	@info "$colorYellow$(length(RESULT))$colorReset urls generated ✅"

	if isnothing(OUTPUT)
		print(join(RESULT, "\n"))
	else
		Write(OUTPUT, "w+", join(RESULT, "\n"))   # if was not given -o, then print in terminal
		@info "urls saved in $colorGreen$textBold$(arg["output"])$colorReset ✅"
	end
end

main()
