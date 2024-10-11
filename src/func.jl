using StyledStrings


# Read File and Return Non Empty Lines 
# If File Not Exist, Show Error and Exit
function ReadNonEmptyLines(FilePath::String)
	if isfile(FilePath)
		filter(!isempty, readlines(FilePath))
	else
		@error styled"{warning:No Such File or Directory: $FilePath}"
		exit(0)
	end
end


function Write(filename::String, mode::String, data::AbstractString)
	open(filename, mode) do file
		write(file, data)
	end
end


const banner::String = "       ___  \r\n__  __/ _ \\\r\n\\ \\/ / (_) |\r\n >  < \\__, |\r\n/_/\\_\\  /_/\r\n    \n"
