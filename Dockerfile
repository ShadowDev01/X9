FROM julia:1.9.2
RUN julia -e 'using Pkg; Pkg.add("ArgParse");'
RUN mkdir /X9
WORKDIR /X9/
COPY . /X9/
CMD [ "julia" ]