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