include("src/deps.jl")
include("src/args.jl")
include("src/URL.jl")
include("src/func.jl")




# user cli argsuments
const args = ARGUMENTS()

# final results to print
RESULT = OrderedSet{Base.AnnotatedString{String}}()


function ignore(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String})
	Threads.@threads for url in urls
		u = URL(url) # make URL obj
		fragment = isempty(u.fragment) ? "" : "#" * u.fragment

		# drop all parameters
		if args["chunk"] == 0
			str = u._path * fragment
			push!(RESULT, str)
			continue
		end

		# check chunk size
		if args["chunk"] <= u.query_params_count
			@warn "[--ignore]: The given chunk must be larger than the default URL parameters.\nurl = $(u.raw_url)"
			continue
		end

		# possible combination of parameters
		pairs = OrderedSet{Base.AnnotatedString{String}}()

		# make user custom parameters
		for value in Values
			for k in Keys
				str = styled"{bold,tip:$k}" * styled"={bright_blue:$value}"
				push!(pairs, str)
			end
		end

		# count of parmas to add in url
		k = args["chunk"] - u.query_params_count

		# generate custom urls based on chunk
		for item in Iterators.partition(pairs, k)
			# make sure url chunk be correct
			if length(item) < k
				params = join(last(pairs, k), "&")
			else
				params = join(item, "&")
			end

			if isempty(u.query)
				str = chopsuffix(u._path, "?") * "?" * params * fragment
			else
				str = chopsuffix(u._query, "&") * "&" * params * fragment
			end

			push!(RESULT, str)
		end
	end
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String})
	Threads.@threads for url in urls
		u = URL(url) # make URL obj
		fragment = isempty(u.fragment) ? "" : "#" * u.fragment

		# drop all parameters
		if args["chunk"] == 0
			str = u._path * fragment
			push!(RESULT, str)
			continue
		end

		# check chunk size
		if args["chunk"] <= u.query_params_count
			@warn "[--rep-all]: The given chunk must be larger than the default URL parameters.\nurl = $(u.raw_url)"
			continue
		end

		# possible combination of parameters
		pairs = OrderedSet{Base.AnnotatedString{String}}()

		# make user custom parameters
		for value in Values
			params = vcat(u.query_params, Keys)
			for param in params
				str = styled"{tip:$param}" .* styled"={bold,bright_blue:$value}"
				push!(pairs, str)
			end
		end

		# generate custom urls based on chunk
		for item in Iterators.partition(pairs, args["chunk"])
			params = join(item, "&")
			str = u._path * "?" * params * fragment
			push!(RESULT, str)
		end

	end
end

function replace_alternative(; urls::Vector{String}, Values::Vector{String})
	Threads.@threads for url in urls
		u = URL(url) # make URL obj

		if isempty(u.query)
			@warn "[--rep-alt]: url has no query part\nurl = $(u.decoded_url)"
			continue
		end

		# generate custom urls
		for value in Values
			for param in u.query_params
				key = param * "=" * value
				custom_url = replace(u.decoded_url, Regex("$(param)(\\=[^\\&]*)?") => key)
				idxp = findfirst(param, custom_url)
				idxv = findfirst(value, custom_url)
				push!(
					RESULT,
					Base.AnnotatedString(custom_url, [
						(idxp, :face => :tip),
						(idxv, :face => :bright_blue),
					]),
				)
			end
		end

	end
end

function suffix_all(; urls::Vector{String}, Values::Vector{String})
	Threads.@threads for url in urls
		u = URL(url) # make URL obj
		fragment = isempty(u.fragment) ? "" : "#" * u.fragment

		if isempty(u.query)
			@warn "[--suf-all]: url has no query part\nurl = $(u.decoded_url)"
			continue
		end

		# possible combination of parameters
		pairs = OrderedSet{Base.AnnotatedString{String}}()

		# make possible parameters
		for value in Values
			params = OrderedSet{Base.AnnotatedString{String}}()
			for (k, v) in u.query_paires
				str = styled"{tip:$k}" * "=" * v * styled"{bold,bright_blue:$value}"
				push!(params, str)
			end
			push!(pairs, join(params, "&"))
		end

		# generate custom urls
		for pair in pairs
			str = u._path * "?" * pair * fragment
			push!(RESULT, str)
		end
	end
end

function suffix_alternative(; urls::Vector{String}, Values::Vector{String})
	Threads.@threads for url in urls
		u = URL(url)
		fragment = isempty(u.fragment) ? "" : "#" * u.fragment

		if isempty(u.query)
			@warn "[--suf-alt]: url has no query part\nurl = $(u.decoded_url)"
			continue
		end

		# generate custom urls
		for value in Values
			for (k, v) in u.query_paires
				param = k * "=" * v * value
				custom_url = replace(u.decoded_url, Regex("$(k)(\\=[^\\&]*)?") => param)
				idxp = findfirst(k, custom_url)
				idxv = findfirst(value, custom_url)
				push!(
					RESULT,
					Base.AnnotatedString(custom_url, [
						(idxp, :face => :tip),
						(idxv, :face => :bright_blue),
					]),
				)
			end
		end

	end
end

function main()
	printstyled(banner, color = :light_red)

	# Extract args
	URLS = String[]
	KEYS = !isnothing(args["parameters"]) ? ReadNonEmptyLines(args["parameters"]) : String[]
	VALUES = !isnothing(args["values"]) ? ReadNonEmptyLines(args["values"]) : String[]


	# in order not to interfere with the switches -u / -U
	if !isnothing(args["url"])
		URLS = isempty(args["url"]) ? String[] : [args["url"]]
	elseif !isnothing(args["urls"])
		URLS = args["urls"] |> ReadNonEmptyLines
	end

	if isempty(URLS)
		@warn "provide some url(s) please! 😕"
		exit(0)
	end

	@info styled"{yellow:$(length(URLS))} url(s) detected ✅"

	if !any([
		args["ignore"],
		args["rep-all"],
		args["rep-alt"],
		args["suf-all"],
		args["suf-alt"],
	])
		@warn styled"choose any switch options: {region:--ignore / ...}"
		exit(0)
	end

	@info "Generating urls 🛠️"

	# Call When --ignore passed
	args["ignore"] && ignore(
		urls = URLS,
		Keys = KEYS,
		Values = VALUES,
	)

	args["rep-all"] && replace_all(
		urls = URLS,
		Keys = KEYS,
		Values = VALUES,
	)

	args["rep-alt"] && replace_alternative(
		urls = URLS,
		Values = VALUES,
	)

	args["suf-all"] && suffix_all(
		urls = URLS,
		Values = VALUES,
	)

	args["suf-alt"] && suffix_alternative(
		urls = URLS,
		Values = VALUES,
	)

	@info styled"{yellow:$(length(RESULT))} urls generated ✅"

	if isnothing(args["output"])
		print(join(RESULT, "\n"))
	else
		Write(args["output"], "w+", join(RESULT, "\n"))   # if was not given -o, then print in terminal
		@info styled"""urls saved in {bold,region:$(args["output"])} ✅"""
	end
end

main()
