include("src/func.jl")
ensure_package()
include("src/args.jl")
include("src/URL.jl")


function ignore(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String}, chunk::Int)
	result = OrderedSet{Base.AnnotatedString{String}}()

	Threads.@threads for u in urls
		# make URL obj
		url = URL(u)
		fragment = isempty(url.fragment) ? "" : "#" * url.fragment

		# drop all parameters
		if chunk == 0
			str = url._path * fragment
			push!(result, str)
			continue
		end

		# check chunk size
		L = length(QueryParams(url.query))
		if chunk <= L
			@warn "[--ignore]: The given chunk must be larger than the default URL parameters.\nurl = $(url.raw_url)"
			continue
		end

		# possible combination of parameters
		pairs = OrderedSet{Base.AnnotatedString{String}}()

		# make user custom parameters
		for (k, v) in Iterators.product(Keys, Values)
			str = styled"{bold,tip:$k}" * styled"={bright_blue:$v}"
			push!(pairs, str)
		end

		# count of parmas to add in url
		k = chunk - L

		# generate custom urls based on c
		for item in Iterators.partition(pairs, k)
			# make sure url chunk is correct
			if length(item) < k
				params = join(last(pairs, k), "&")
			else
				params = join(item, "&")
			end

			if isempty(url.query)
				str = chopsuffix(url._path, "?") * "?" * params * fragment
			else
				str = chopsuffix(url._query, "&") * "&" * params * fragment
			end

			push!(result, str)
		end
	end
	return result
end

function replace_all(; urls::Vector{String}, Keys::Vector{String}, Values::Vector{String}, chunk::Int)
	result = OrderedSet{Base.AnnotatedString{String}}()

	Threads.@threads for u in urls
		# make URL obj
		url = URL(u)
		fragment = isempty(url.fragment) ? "" : "#" * url.fragment

		# drop all parameters
		if chunk == 0
			str = url._path * fragment
			push!(result, str)
			continue
		end

		# check chunk size
		L = length(QueryParams(url.query))
		if chunk <= L
			@warn "[--rep-all]: The given chunk must be larger than the default URL parameters.\nurl = $(url.raw_url)"
			continue
		end

		# possible combination of parameters
		pairs = OrderedSet{Base.AnnotatedString{String}}()

		# make user custom parameters
		for value in Values
			params = vcat(QueryParams(url.query), Keys)
			for param in params
				str = styled"{tip:$param}" .* styled"={bold,bright_blue:$value}"
				push!(pairs, str)
			end
		end

		# generate custom urls based on chunk
		for item in Iterators.partition(pairs, chunk)
			params = join(item, "&")
			str = url._path * "?" * params * fragment
			push!(result, str)
		end
	end
	return result
end

function replace_alternative(; urls::Vector{String}, Values::Vector{String})
	result = OrderedSet{Base.AnnotatedString{String}}()

	Threads.@threads for u in urls
		url = URL(u) # make URL obj

		if isempty(url.query)
			@warn "[-rep-alt]: url has no query part\nurl = $(url.decoded_url)"
			continue
		end

		# generate custom urls
		for value in Values
			for param in QueryParams(url.query)
				key = param * "=" * value
				custom_url = replace(url.decoded_url, Regex("$(param)(\\=[^\\&]*)?") => key)
				idxp = findfirst(param, custom_url)
				idxv = findfirst(value, custom_url)
				push!(
					result,
					Base.AnnotatedString(custom_url,
						[
							(region = idxp, label = :face, value = :tip),
							(region = idxv, label = :face, value = :bright_blue),
						],
					),
				)
			end
		end
	end
	return result
end

function suffix_all(; urls::Vector{String}, Values::Vector{String})
	result = OrderedSet{Base.AnnotatedString{String}}()

	Threads.@threads for u in urls
		url = URL(u) # make URL obj
		fragment = isempty(url.fragment) ? "" : "#" * u.fragment

		if isempty(url.query)
			@warn "[-suf-all]: url has no query part\nurl = $(url.decoded_url)"
			continue
		end

		# possible combination of parameters
		pairs = OrderedSet{Base.AnnotatedString{String}}()

		# make possible parameters
		for value in Values
			params = OrderedSet{Base.AnnotatedString{String}}()
			for (k, v) in QueryPairs(url.query)
				str = styled"{tip:$k}" * "=" * v * styled"{bold,bright_blue:$value}"
				push!(params, str)
			end
			push!(pairs, join(params, "&"))
		end

		# generate custom urls
		for pair in pairs
			str = url._path * "?" * pair * fragment
			push!(result, str)
		end
	end
	return result
end

function suffix_alternative(; urls::Vector{String}, Values::Vector{String})
	result = OrderedSet{Base.AnnotatedString{String}}()

	Threads.@threads for u in urls
		url = URL(u)
		fragment = isempty(url.fragment) ? "" : "#" * url.fragment

		if isempty(url.query)
			@warn "[-suf-alt]: url has no query part\nurl = $(url.decoded_url)"
			continue
		end

		# generate custom urls
		for value in Values
			for (k, v) in QueryPairs(url.query)
				param = k * "=" * v * value
				custom_url = replace(url.decoded_url, Regex("$(k)(\\=[^\\&]*)?") => param)
				idxp = findfirst(k, custom_url)
				idxv = findfirst(value, custom_url)
				push!(
					result,
					Base.AnnotatedString(custom_url, [
						(region = idxp, label = :face, value = :tip),
						(region = idxv, label = :face, value = :bright_blue),
					]),
				)
			end
		end

	end
	return result
end

function main()
	RESULT = OrderedSet{Base.AnnotatedString{String}}()

	# cli argsuments
	args = ARGUMENTS()

	printstyled(banner, color = :light_red)

	try
		if args["ignore"]
			push!(RESULT, ignore(
				urls = args["source"],
				Keys = args["params"],
				Values = args["values"],
				chunk = args["c"],
			)...)
		end

		if args["rep-all"]
			push!(RESULT, replace_all(
				urls = args["source"],
				Keys = args["params"],
				Values = args["values"],
				chunk = args["c"],
			)...)
		end

		if args["rep-alt"]
			push!(RESULT, replace_alternative(
				urls = args["source"],
				Values = args["values"],
			)...)
		end

		if args["suf-all"]
			push!(RESULT, suffix_all(
				urls = args["source"],
				Values = args["values"],
			)...)
		end

		if args["suf-alt"]
			push!(RESULT, suffix_alternative(
				urls = args["source"],
				Values = args["values"],
			)...)
		end

	catch
	end

	if isempty(args["o"])
		print(join(RESULT, "\n"))
	else
		Write(args["o"], "w+", join(RESULT, "\n"))   # if was not given -o, then print in terminal
		@info styled"""urls saved in {bold,region:$(args["o"])} ✅"""
	end
end

main()
