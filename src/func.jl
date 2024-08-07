using Pkg: Pkg

const colorReset = "\033[0m"
const colorRed = "\033[31m"
const colorLightRed = "\033[91m"
const colorGreen = "\033[32m"
const colorYellow = "\033[33m"
const colorLightYellow = "\033[93m"
const colorBlue = "\033[34m"
const colorLightBlue = "\033[94m"
const colorCyan = "\033[96m"
const colorMagenta = "\033[35m"
const colorLightMagenta = "\033[95m"
const colorWhite = "\033[97m"
const colorBlack = "\033[30m"
const textItalic = "\033[3m"
const textBold = "\033[1m"
const textBox = "\033[7m"
const textBlink = "\033[5m"
const textUnderline = "\033[4m"


# check prerequisites installed
function Check_Dependencies()
	installed_packages = Pkg.project().dependencies
	required_packages  = ("JSON", "ArgParse", "OrderedCollections")
	prepare_to_install = String[]

	for package in required_packages
		haskey(installed_packages, package) || push!(prepare_to_install, package)
	end

	if !isempty(prepare_to_install)
		@info "Installing Prerequisites..."
		Pkg.add(prepare_to_install)
		@info "Prerequisites Installed ✔"
	end
end

# Read File and Return Non Empty Lines 
# If File Not Exist, Show Error and Exit
function ReadNonEmptyLines(FilePath::String)
	if isfile(FilePath)
		filter(!isempty, readlines(FilePath))
	else
		@error "Not Such File or Directory: $colorLightRed$(FilePath)$colorReset"
		exit(0)
	end
end


function Write(filename::String, mode::String, data::String)
	open(filename, mode) do file
		write(file, data)
	end
end


const banner::String = "       ___  \r\n__  __/ _ \\\r\n\\ \\/ / (_) |\r\n >  < \\__, |\r\n/_/\\_\\  /_/\r\n    \n"
