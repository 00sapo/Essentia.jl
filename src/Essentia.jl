module Essentia
# disable precompilation
__precompile__(false)
using Cxx
using Libdl
include("Init.jl")
include("Types.jl")

export Algorithm, jj, @jj

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
                return icxx\"\"\"
                $type::AlgorithmFactory& factory = $type::AlgorithmFactory::instance();
                $type::Algorithm* algo = factory.create(\$name $(_params2cppcode(i)));
                return algo;
                \"\"\"
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
    )::Tuple{Vector{Pair{String, T}}, Vector{V}} where T, V

    function (
        self::Algorithm)(inputs::Tuple{Vector{Pair{String, T}}, Vector{V}}
    )::Tuple{Vector{Pair{String, T}}, Vector{V}} where T, V

Executes the algorithm. Note that while this function is running, the garbage-collector is suspended!

## Arguments

* a variadic number of pairs where:
    * keys must be strings with the same name as the Essentia
    [documentation](https://essentia.upf.edu/reference/) 
    * values are C++ or Julia objects

## Returns

* a `Tuple{Vector{Pairs{String, T}}, Vector{V}}` where:
    * pair keys are strings with the same name as Essentia documentation 
    * pair values are C++ objects
    * `V` is a type descriptor

Use `jj` function or macro to get a dictionary of Julia objects
"""
function (self::Algorithm)(
    inputs::Pair{String, T}...)::Tuple{Vector{Pair{String, T}}, Vector{V}} where {T, V}

    # disable GC
    GC.enable(false)
    if length(inputs) != self.ninp
        error("Essentia " * self.name * "algorithm needs $(self.ninp) inputs, but receivs $(length(inputs))")
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
        if typeInfoToStr(inputTypes[i] == "VECTOR_STEREOSAMPLE")
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
        output_type = outputTypes[i]
        v = getCppObjPtr(output_type)
        icxx"$(self.algo)->output($name).set($v);"
        # do we need the pointer here?
        outputs[i] = unsafe_string(name) => (icxx"*$v;", output_type)
    end
    # compute
    icxx"$(self.algo)->compute();"
    # disable GC
    GC.enable(true)
    # return
    return outputs, outputTypes
end

function (self::Algorithm)(inputs::Tuple{Vector{Pair{String, T}}, Vector{V}}) where {T, V}
    return self(inputs[1]...)
end

"""
Takes the output of an Algorithm and converts them to Julia dictionary with:
    * keys are strings with the names in Essentia documentation 
    * values are Julia objects
"""
function jj(objects::Tuple{Vector{Pair{String, T}}, Vector{V}})::Dict{String, T} where {T, V}
    out = Dict{String, T}()
    for i in 1:length(objects[1])
        k, v = objects[1][i]
        type_info = objects[2][i]
        # do we need a pointer here?
        out[k] = es2julia(Ptr(v), typeInfoToStr(type_info))
    end
end

"""
Same as function `jj`, but in macro style
"""
macro jj(expr)
    quote
        jj($expr)
    end
end

end # module
