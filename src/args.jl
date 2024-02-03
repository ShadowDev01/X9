using ArgParse

function ARGUMENTS()
    settings = ArgParseSettings(
        prog="X9",
        description="""
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n
        **** Customize Parameters in URL(s) ***
        \n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        """,
        version="v1.0.1",
        add_version=true
    )
    @add_arg_table settings begin
        "-u", "--url"
        help = "single url"
        arg_type = String

        "-U", "--urls"
        help = "list of urls in file"
        arg_type = String

        "-p", "--parameters"
        help = "list of parameters in file"
        arg_type = String

        "-v", "--values"
        help = "list of values in file"
        arg_type = String

        "--ignore"
        help = "does not change the default parameters, just appends the given parameters with the given values to the end of the URL"
        action = :store_true

        "--rep-all"
        help = "Replaces all default parameter's values with the given values and appends the given parameters with the given values to the end of the URL"
        action = :store_true

        "--rep-alt"
        help = "just replaces the default parameter values with the given values alternately"
        action = :store_true

        "--suf-all"
        help = "append the given values to the end of all the default parameters"
        action = :store_true

        "--suf-alt"
        help = "append the given values to the end of default parameters alternately"
        action = :store_true

        "-A"
        help = "do all --ignore, --replace-all, --replace-alt, --suffix-all, --suffix-alt"
        action = :store_true

        "-c", "--chunk"
        help = "maximum number of parameters in url"
        arg_type = Int
        default = 10000

        "-o", "--output"
        help = "save output in file"
        arg_type = String
    end
    parsed_args = parse_args(ARGS, settings)
    if parsed_args["A"]
        for arg in ["ignore", "rep-all", "rep-alt", "suf-all", "suf-alt"]
            parsed_args[arg] = true
        end
    end
    return parsed_args
end