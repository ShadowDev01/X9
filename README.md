
# Intro
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# help Customize Parameters in URL(s) - X9
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Install
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                            *** julia ***

# install julia: https://julialang.org/downloads/
# then run this commands in terminal:

* 1. julia -e 'using Pkg; Pkg.add("ArgParse")'
* 2. git clone https://github.com/mrmeeseeks01/BackupX.git
* 3. cd BackupX/
* 4. julia BackupX.jl -h


# or you can use docker:

* 1. git clone https://github.com/mrmeeseeks01/BackupX.git
* 2. cd BackupX/
* 3. docker build -t backupx .
* 4. docker run -it backupx
* 5. press ; to enabled shell mode
* 6. julia BackupX.jl -h
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Switches
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# optional arguments:

*  -h, --help            show this help message and exit
*  -u, --url             single url
*  -U, --urls            list of urls in file
*  -p, --parameters      list of parameters in file
*  -v, --values          list of values in file
*  -c, --chunk           maximum number of parameters in url (type: Int64, default: 10000)
*  --ignore              does not change the default parameters, just appends the given parameters with the given values to the end of the URL
*  --replace-all         Replaces all default parameter's values with the given values and appends the given parameters with the given values to the end of the URL
*  --replace-alt         just replaces the default parameter values with the given values alternately
*  --suffix-all          append the given values to the end of all the default parameters
*  --suffix-alt          append the given values to the end of default parameters alternately
*  --all                 do all --ignore, --replace-all, --replace-alt, --suffix-all, --suffix-alt
*  -o, --output          save output in file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Examples

url = 

* for custom threads, should pass -t [int] to julia
~~~
> julia -t 2 BackupX.jl [switches]
~~~
* generate wordlist by your custom input
~~~
> julia BackupX.jl -U [file] -p [file] -w [file] -e [file] -n [min-max] -y [min-max] -m [min-max] -d [min-max]
~~~
* for example generate wordlist by single url with this pattern: $subdomain.$domain.$ext$num.$y-$m-$d
~~~
> julia BackupX.jl -u https://sub1-sub2.sub3.domain.tld -p pattern.json  -w wordlist.txt -e extensions.txt -n 1-100 -y 2021-2023 -m 1-12 -d 1-30
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~