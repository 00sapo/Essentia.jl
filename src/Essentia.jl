module Essentia
include("Init.jl")
include("Types.jl")
using Debugger


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
    for i in 1:n
        code *= ",\$(string(params[$i].first)), \$(julia2es(params[$i].second))"
    end
    return code
end


@inbounds for type in ["standard", "streaming"]
    @simd for i in 0:30
        # $var is interpolated in the code of the function at inclusion time
        # \$var is interpolated at runtime
        fn = Meta.parse("""
        function $(type)_factory(name::String, params::Vararg{Pair{Symbol}, $i})
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
Executes the algorithm. Note that while this function is running, the garbage-collector is suspended!

`inputs` must have the same name as the Essentia [documentation](https://essentia.upf.edu/reference/)

It returns a dictionary where keys are the output names in the documentation
"""
function (self::Algorithm)(inputs::Pair...)
    # disable GC
    GC.enable(false)
    if length(inputs) != self.ninp
        error("Essentia " * self.name * "algorithm needs $(self.ninp) inputs, but receivs $(length(inputs))")
    end
    # connect inputs
    # need inputTypes for StereoSample...
    inputTypes = icxx"vector<const type_info*> inputTypeInfos = $(self.algo)->inputTypes(); inputTypes;"
    inputNames = icxx"vector<string> inputNames = $(self.algo)->inputNames(); inputNames;"
    juliaInputs = Dict(inputs...)
    for (i, name) in enumerate(inputNames)
        # converting julia to C++
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
    outputTypes = icxx"vector<const type_info*> outputTypeInfos = $(self.algo)->outputTypes(); outputTypes;"
    outputNames = icxx"vector<string> outputNames = $(self.algo)->outputNames(); outputNames;"
    outputs = Vector{Pair}(undef, self.nout)
    for (i, name) in enumerate(outputNames)
        # instantiate a pointer to the correct Essentia type
        v = getCppObjPtr(outputTypes[i])
        icxx"$(self.algo)->output($name).set($v);"
        outputs[i] = Symbol(unsafe_string(name)) => icxx"*$v;"
    end
    # compute
    icxx"$(self.algo)->compute();"
    # # convert to julia
    # outputs = Dict(
    #     unsafe_string(outputNames[i-1]) => es2julia(objPtr) for (i, objPtr) in enumerate(outputPtrs))
    # disable GC
    GC.enable(true)
    # return
    return outputs
end

end # module
