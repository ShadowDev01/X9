FROM julia:1.11
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("ArgParse"); Pkg.add("OrderedCollections")'
RUN mkdir /X9
WORKDIR /X9/
COPY . /X9/
ENTRYPOINT [ "julia", "/X9/x9.jl" ]
CMD [ "-h" ]