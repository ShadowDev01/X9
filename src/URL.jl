using JSON
using OrderedCollections
using LibCURL


"""
USE TO PARSE DIFFERENT PARTS OF URL

for example:
	
https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C#justfortest

"""
struct URL
	raw_url::String                         # raw url without decode
	decoded_url::String                     # decoded url
	scheme::String                          # https
	username::String                        # admin
	password::String                        # test1234
	auth::String                   # admin:test1234
	host::String                            # login.admin-auth.company.co.com 
	subdomain::String                       # login.admin-auth
	domain::String                          # company
	tld::String                             # co.com
	port::String                            # 443
	path::String                            # /admin/desk/master.js
	directory::String                       # /admin/desk
	file::String                            # master.js
	file_name::String                       # master
	file_ext::String                  # js
	query::String                           # A=line+25&B=#12&C
	query_params::Vector{String}            # ["A", "B", "C"]
	query_values::Vector{String}       # ["line+25", "#12"]
	query_paires::OrderedDict{String, Any}# {"A":"line+25", "B":"#12", "C":null}
	query_params_count::Int32               # 3
	query_values_count::Int32           # 2
	fragment::String                        # justfortest

	# From the beginning of URL to the given section
	_scheme::String                         # https://
	_auth::String                           # https://admin:test1234@
	_host::String                           # https://admin:test1234@login.admin-auth.company.co.com:
	_port::String                           # https://admin:test1234@login.admin-auth.company.co.com:443
	_path::String                           # https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js
	_query::String                          # https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C
	_fragment::String                       # https://admin:test1234@login.admin-auth.company.co.com:443/admin/desk/master.js?A=line+25&B=#12&C#justfortest
end

function URL_Decode(url::AbstractString)
	while occursin(r"(\%[0-9a-fA-F]{2})", url)                    # As long as the %hex exists, it will continue to url docode
		curl = curl_easy_init()
		output_ptr = C_NULL
		output_len = Ref{Cint}()
		output_ptr = curl_easy_unescape(curl, url, 0, output_len)
		url = unsafe_string(output_ptr)
		curl_free(output_ptr)
		curl_easy_cleanup(curl)
	end
	return url
end

function HTML_Decode(url::AbstractString)
	# HTML HEX, DEC Decode
	while occursin(r"&#(?<number>[a-zA-Z0-9]+);", url)                  # As long as the &#(hex|dec) exists, it will continue to url docode
		for encoded in eachmatch(r"&#(?<number>[a-zA-Z0-9]+);", url)
			n = encoded["number"]
			num = parse(Int, startswith(n, "x") ? "0$n" : n)
			url = replace(url, encoded.match => Char(num))
		end
	end

	# HTML Symbol Decode
	while occursin(r"&(gt|lt|quot|apos|amp);"i, url)
		url = replace(
			url,
			r"&gt;"i => ">",
			r"&lt;"i => "<",
			r"&quot;"i => "\"",
			r"&apos;"i => "'",
			r"&amp;"i => "&",
		)
	end
	return url
end

# replace nothing type with ""
function check_str(input::Union{AbstractString, Nothing})
	!isnothing(input) ? input : ""
end

# extract subdomain, domain & tld from host
function split_domain(host::String)
	# extract tld
	file = isfile("tlds.txt") ? "tlds.txt" : "src/tlds.txt"
	tlds = Set{AbstractString}()
	for line in eachline(file)
		occursin(Regex("\\b$line\\b\\Z"), host) && push!(tlds, line)
	end
	tld = argmax(length, tlds)[2:end]

	# extract subdomain & domain
	host = replace(host, ".$tld" => "")
	rest = rsplit(host, ".", limit = 2)
	if length(rest) > 1
		subdomain, domain = rest
	else
		subdomain = ""
		domain = rest[1]
	end

	return (subdomain, domain, tld)
end


"""
make combination of subdomain 

login.admin-auth => ["login.admin-auth", "login", "admin", "auth", "admin-auth"]
"""
function SubCombination(url::URL)
	subdomain::String = url.subdomain
	unique(vcat(
		[subdomain],
		split(subdomain, r"[\.\-]"),
		split(subdomain, "."))
	)
end

# split name & extension of file
function split_file(file::String)
	if occursin(".", file)
		split(file, ".", limit = 2, keepempty = true)
	else
		split(file * ".", ".", limit = 2, keepempty = true)
	end
end

# Extract Query Parameters
function QueryParams(query::AbstractString)
	result = String[]
	regex::Regex = r"[\?\&\;]([\w\-\~\+\%]+)"
	for param in eachmatch(regex, query)
		append!(result, param.captures)
	end
	return unique(result)
end

# Extract Query Parameters Values
function QueryParamsValues(query::AbstractString)
	result = String[]
	regex::Regex = r"\=([\w\-\%\.\:\~\,\"\'\<\>\=\(\)\`\{\}\$\+\/\;\#]*)?"
	for param in eachmatch(regex, query)
		append!(result, param.captures)
	end
	return unique(filter(!isempty, result))
end

# extract Query parameters - values in key:value pairs
function QueryPairs(query::AbstractString)
	d = OrderedDict{String, Any}()
	query = chopprefix(query, "?")

	for item in eachsplit(query, "&")
		if !occursin("=", item)
			item *= "="
		end
		k, v = split(item, "=")
		v == "null" && (v = nothing)
		d[k] = v
	end
	return d
end

function URL(input_url::AbstractString)
	url::String = input_url |> URL_Decode |> HTML_Decode
	url = chopprefix(url, "*.")
	regex::Regex = r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?(?<port>(\d+))?(?<path>([\/\w\-\.\%\,\"\'\<\>\=\(\)]+))?(?<query>\?(.*?))?(?<fragment>(?<!\=)\#([^\#]*?))?$"
	parts = match(regex, url)

	raw_url::String = input_url
	decoded_url::String = url
	scheme::String = check_str(parts["scheme"])
	username::String = check_str(parts["username"])
	password::String = check_str(parts["password"])
	auth::String = chopsuffix(check_str(parts[4]), "@")
	host::String = chopprefix(check_str(parts["host"]), "www.")
	subdomain::String, domain::String, tld::String = split_domain(host)
	port::String = check_str(parts["port"])
	path::String = check_str(parts["path"])
	directory::String = dirname(path)
	file::String = basename(path)
	file_name::String, file_ext::String = split_file(file)
	query::String = check_str(parts["query"])
	query_params::Vector{String} = QueryParams(query)
	query_values::Vector{String} = QueryParamsValues(query)
	query_paires::OrderedDict{String, Any} = QueryPairs(query)
	query_params_count::Int32 = length(query_params)
	query_values_count::Int32 = length(query_values)
	fragment::String = check_str(parts[18])

	_scheme::String = check_str(parts[1])
	_auth::String = _scheme * check_str(parts[4])
	_host::String = match(r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?", url).match
	_port::String = _host * port
	_path::String = _port * path
	_query::String = _path * query
	_fragment::String = url

	return URL(
		raw_url,
		decoded_url,
		scheme,
		username,
		password,
		auth,
		host,
		subdomain,
		domain,
		tld,
		port,
		path,
		directory,
		file,
		file_name,
		file_ext,
		query,
		query_params,
		query_values,
		query_paires,
		query_params_count,
		query_values_count,
		fragment,
		_scheme,
		_auth,
		_host,
		_port,
		_path,
		_query,
		_fragment,
	)
end

# JSON output of URL sections
function Json(url::URL)
	custom_json = OrderedDict{String, Any}(
		"raw_url" => url.raw_url,
		"decoded_url" => url.decoded_url,
		"scheme" => url.scheme,
		"username" => url.username,
		"password" => url.password,
		"auth" => url.auth,
		"host" => url.host,
		"subdomain" => url.subdomain,
		"subdomain_combination" => SubCombination(url),
		"domain" => url.domain,
		"tld" => url.tld,
		"port" => url.port,
		"path" => url.path,
		"directory" => url.directory,
		"file" => url.file,
		"file_name" => url.file_name,
		"file_ext" => url.file_ext,
		"query" => chopprefix(url.query, "?"),
		"query_params" => url.query_params,
		"query_values" => url.query_values,
		"query_paires" => url.query_paires,
		"query_params_count" => url.query_params_count,
		"query_values_count" => url.query_values_count,
		"fragment" => url.fragment,
	)
	for (key, value) in pairs(custom_json)
		if isempty(value) || value == [""] || value == 0
			pop!(custom_json, key)
		end
	end
	push!(JSON_DATA, custom_json)
end