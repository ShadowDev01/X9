const help = """
 \r\n__  __/ _ \\\r\n\\ \\/ / (_) |\r\n >  < \\__, |\r\n/_/\\_\\  /_/\r\n

# optional arguments:

*  -h                    Display this help message and exit
*  -u                    Process a single URL
*  -ul                   Process URLs from a file (one per line)
*  -p                    Use parameters from a file (one per line)
*  -v                    Use values from a file (one per line)
*  -c                    Limit parameters per URL (default: 10000)
*  -ignore               Keep default parameters; append new ones
*  -rep-all              Replace all default values and append new parameters
*  -rep-alt              Replace default values alternately
*  -suf-all              Append values to all default parameters
*  -suf-alt              Append values to default parameters alternately
*  -A                    Apply all -ignore, -rep-all, -rep-alt, -suf-all , -suf-alt
*  -o                    Save results to a file
"""


function single_pass(param::String)
	idx = findfirst(==(param), ARGS) + 1
	if isassigned(ARGS, idx) && !startswith(ARGS[idx], "-")
		return ARGS[idx]
	else
		return ""
	end
end

function multi_pass(param::String)
	res = String[]
	idx1 = findfirst(==(param), ARGS)
	for i in ARGS[idx1+1:end]
		startswith(i, "-") && break
		push!(res, i)
	end
	return res
end

function ARGUMENTS()
	args = Dict{String, Any}(
		"source" => String[],
		"params" => String[],
		"values" => String[],
		"u" => "",
		"ul" => "",
		"p" => "",
		"v" => "",
		"c" => "1000",
		"o" => "",
		"ignore" => false,
		"rep-all" => false,
		"rep-alt" => false,
		"suf-all" => false,
		"suf-alt" => false,
	)

	("-h" ∈ ARGS) && (print(help), exit(0))
	("-ignore" ∈ ARGS) && (args["ignore"] = true)
	("-rep-all" ∈ ARGS) && (args["rep-all"] = true)
	("-rep-alt" ∈ ARGS) && (args["rep-alt"] = true)
	("-suf-all" ∈ ARGS) && (args["suf-all"] = true)
	("-suf-alt" ∈ ARGS) && (args["suf-alt"] = true)

	if "-A" ∈ ARGS
		for i in ("ignore", "rep-all", "rep-alt", "suf-all", "suf-alt")
			args[i] = true
		end
	end

	for itm in ("-u", "-ul", "-p", "-v", "-c", "-o")
		if itm ∈ ARGS
			res = single_pass(itm)
			!isempty(res) && (args[chopprefix(itm, "-")] = res)
		end
	end

	args["c"] = parse(Int, args["c"])


	if !isempty(args["u"])
		push!(args["source"], args["u"])
	end

	if !isempty(args["ul"])
		file = args["ul"]
		if isfile(file)
			lines = filter(!isempty, readlines(file))
			append!(args["source"], lines)
		end
	end

	isempty(args["source"]) && (@warn "Provide some URLs please! 😕"; exit(0))

	if !isempty(args["p"])
		file = args["p"]
		if isfile(file)
			lines = filter(!isempty, readlines(file))
			append!(args["params"], lines)
		end
	end

	if !isempty(args["v"])
		file = args["v"]
		if isfile(file)
			lines = filter(!isempty, readlines(file))
			append!(args["values"], lines)
		end
	end

	if !any([
		args["ignore"],
		args["rep-all"],
		args["rep-alt"],
		args["suf-all"],
		args["suf-alt"],
	])
		@warn styled"Select an option: --ignore / ..."
		exit(0)
	end

	return args
end
