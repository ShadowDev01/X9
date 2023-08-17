FROM julia:1.9.2
RUN julia -e 'using Pkg; Pkg.add("JSON"); Pkg.add("ArgParse"); Pkg.add("OrderedCollections")'
RUN mkdir /X9
WORKDIR /X9/
COPY . /X9/
CMD [ "julia" ]