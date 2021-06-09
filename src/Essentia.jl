module Essentia
# disable precompilation
__precompile__(false)
using Cxx
using Libdl
include("Init.jl")
include("Types.jl")

export Algorithm, jj

"""
    function standard_factory(name::String, params::Vararg{Pair{Symbol}, i})
    function streaming_factory(name::String, params::Vararg{Pair{Symbol}, i})

* 1 ≤ i ≤ 30

This function returns the algorithm `name` using `essentia::standard` or
`essentia::streaming` depending on the name. Other arguments can
be passed in a key-value fashion.

## Example
```julia
Essentia.standard_factory("MFCC", :dctType=>3, :logType="natural")
```
"""

function _params2cppcode(n::Integer)
    # params is here but it's actually an argument of the various factory
    # functions
    code = ""
    for k in 1:n
        code *= ",\$(params[$k].first), \$(julia2es(params[$k].second))"
    end
    return code
end


for type in ["standard", "streaming"]
    for i in 0:30
        # $var is interpolated in the code of the function at inclusion time
        # \$var is interpolated at runtime
        fn = Meta.parse("""
            function $(type)_factory(name::String, params::Vararg{Pair{String}, $i})
                try
                    return icxx\"\"\"
                        $type::AlgorithmFactory& factory = $type::AlgorithmFactory::instance();
                        $type::Algorithm* algo = factory.create(\$name $(_params2cppcode(i)));
                        return algo;
                    \"\"\"
                catch exception
                    throw(EssentiaException("Cannot create Algorithm \$name"))
                end
            end
        """)
        eval(fn)
    end
end

struct Algorithm{T}
    name::String
    type::String
    algo::T
    ninp::Int32
    nout::Int32
    function Algorithm(name, params...; type="standard")
        if type == "standard"
            algo = standard_factory(name, params...)
        elseif type == "streaming"
            algo = streaming_factory(name, params...)
        else 
            error("Only `streaming` or `standard` accepted as Algorithm types")
        end
        ninp = icxx"""$algo->inputs().size();"""
        nout = icxx"""$algo->outputs().size();"""
        new{typeof(algo)}(name, type, algo, ninp, nout)
    end
end

"""
    function (
        self::Algorithm)(inputs::Pair{String, T}...
    ) where T

    function (self::Algorithm)(inputs::T...) where T

    function (
        self::Algorithm)(inputs::Tuple{Vector{Pair{String, T}}, Vector{V}}
    ) where T

Executes the algorithm. Note that while this function is running, the garbage-collector is suspended!

## Arguments

* a variadic number of pairs where:
    * keys must be strings with the same name as the Essentia
    [documentation](https://essentia.upf.edu/reference/) 
    * values are C++ or Julia objects

OR

* a variadic number of C++ or Julia objects in the same order as Essentia documentation

OR

* [meant to be used internally] a `Tuple{Vector{Pairs{String, T}}, Vector{V}}` where:
    * pair keys are strings with the same name as Essentia documentation 
    * pair values are C++ objects
    * `V` is a type descriptor

## Returns

* a `Tuple{Vector{Pairs{String, T}}, Vector{V}}` where:
    * pair keys are strings with the same name as Essentia documentation 
    * pair values are C++ objects
    * `V` is a type descriptor

Use `jj` function or macro to get a dictionary of Julia objects
"""
function (self::Algorithm)(
    inputs::Pair{String, T}...) where T

    # disable GC
    GC.enable(false)
    if length(inputs) != self.ninp
        throw(EssentiaException(
            "Essentia " *
                self.name *
                    "algorithm needs $(self.ninp) inputs, but received $(length(inputs))"))
    end
    # connect inputs
    # need inputTypes for StereoSample...
    inputTypes = icxx"vector<const type_info*> inputTypes = $(self.algo)->inputTypes(); inputTypes;"
    inputNames = icxx"vector<string> inputNames = $(self.algo)->inputNames(); inputNames;"
    juliaInputs = Dict(inputs...)
    for (i, name) in enumerate(inputNames)
        # converting julia to C++
        # if inputs are already C++, they're left untouched
        k = unsafe_string(name)
        v = juliaInputs[k]
        if typeInfoToStr(inputTypes[i - 1]) == "VECTOR_STEREOSAMPLE"
            _v = convert(EssentiaVector{EssentiaTuple}, v)
        else
            _v = julia2es(v)
        end
        icxx"$(self.algo)->input($k).set($_v);"
    end
    # allocate outputs
    outputTypes = icxx"vector<const type_info*> outputTypes = $(self.algo)->outputTypes(); outputTypes;"
    outputNames = icxx"vector<string> outputNames = $(self.algo)->outputNames(); outputNames;"
    outputs = Vector{Pair}(undef, self.nout)
    for (i, name) in enumerate(outputNames)
        # instantiate a pointer to the correct Essentia type
        output_type = outputTypes[i - 1]
        setCppOutput!(outputs, self.algo, name, output_type, i)
    end
    # compute
    # catch Essentia exception and rethrow them in our structure
    exc = unsafe_string(icxx"""try {
        $(self.algo)->compute();
    } catch (const std::exception &exc) {
        return std::string(exc.what());
    }
    return std::string("");
    """)

    # disable GC
    GC.enable(true)

    if exc != ""
        # throw the exception
        throw(EssentiaException(exc))
    end
    # return
    return outputs, outputTypes
end

function (self::Algorithm)(inputs::Tuple{Vector{Pair}, V}) where V
    return self(inputs[1]...)
end

function (self::Algorithm)(inputs::Union{AbstractArray{T}, K}...) where {K <: Number, T}
    inputNames = icxx"vector<string> inputNames = $(self.algo)->inputNames(); inputNames;"
    self((unsafe_string(n) => inputs[i] for (i, n) in enumerate(inputNames))...)
end

"""
Takes the output of an Algorithm and converts them to Julia dictionary so that:
    * keys are strings with the names in Essentia documentation 
    * values are Julia objects
"""
function jj(objects::Tuple{Vector{Pair}, V})::Dict where V
    out = Dict{String, Any}()
    for i in 1:length(objects[1])
        k, v = objects[1][i]
        type_info = objects[2][i-1]
        # do we need a pointer here? yes
        out[k] = es2julia(icxx"&$v;", typeInfoToStr(type_info))
    end
    return out
end

end # module
