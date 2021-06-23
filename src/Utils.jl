using PaddedViews
export rollup, jj, EssentiaComp, @es

"""
    function jj(objects::Tuple{Vector{Pair}, V})::Dict where V

Takes the output of an Algorithm and converts them to Julia dictionary so that:
    * keys are strings with the names in Essentia documentation 
    * values are Julia objects

If no conversion is implemented, then the Cxx object wrapping the C++ type is
returned. When working with `Pool`, expect to receive a Cxx object and to work
with `icxx` macro.
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

"""
    struct EssentiaComp {T}
        algos::Vector{T}
        output::Union{Nothing, String}
    end

A functor for composing `Algorithm` instances.

## Arguments
* `algos` should be a `Vector{Algorithm}` in the order of composition (outer function first)
* `output` is the key of the output you want to get

When you call, a boolean key `force` allows to match non-corresponding algorithms (see `Algorithm` docs).
"""
struct EssentiaComp{T}
    algos::Vector{T}
    output::Union{Nothing, String}
end

function (self::EssentiaComp)(x...; force=true)
    if !force
        fn = ∘(self.algos...)
    else
        fn = ∘([x::Vararg -> a(x...; force=true) for a in self.algos]...)
    end
    if self.output === nothing
        return jj(fn(x...))
    else
        return jj(fn(x...))[self.output]
    end
end

"""
A simple macro which expands this:

    @es algo1 algo2 "output"
    @es algo1 algo2

into this:

    EssentiaComp([algo2, algo1], "output")
    EssentiaComp([algo2, algo1], nothing)

Note the inverse order of the algorithms, that is:
* In `EssentiaComp`, the algorithms appear in the same order you would write them to compose functions (i.e. outer function first)
* In `es` algorithms appear in the order they are computed (i.e. outer function last)

For now, `force=true` always here
"""
macro es(expr...)
    local L = length(expr)
    if typeof(expr[end]) === String
        local output = expr[end]
        local algos = expr[1:end-1]
    else
        local output = nothing
        local algos = expr
    end
    quote
        EssentiaComp([$(esc.(reverse(algos))...)], $output)
    end
end


"""
    function rollup(::Type{T},
                    fn::Function,
                    z::AbstractArray{K},
                    ws::Integer,
                    hs::Integer,
                    padding::String="minimum",
                    padding_fill::Real=0.0) where {T, K<:Number}

Execute a function over frames extracted as views of an array

## Arguments

* `T`: the type returned by `fn`
* `fn`: a function accepting a frame -- i.e. an n-dimensional Array -- e.g. an `Algorithm`
* `z`: a n-dimensional Array from which each frame is extracted; frames are extracted along rows.
    For instance, let `A` be a 5×2 array (5 samples and 2 features), and `ws=3`, `hs=2`;
    this function extracts frames in this way:
        ```julia
        julia> A = reshape(collect(1:10), 5, 2)
        5×2 Array{Int64,2}:
         1   6
         2   7
         3   8
         4   9
         5  10

        julia> selectdim(A, 1, 1:3)
        3×2 view(::Array{Int64,2}, 1:3, :) with eltype Int64:
         1  6
         2  7
         3  8

        julia> selectdim(A, 1, 3:5)
        3×2 view(::Array{Int64,2}, 3:5, :) with eltype Int64:
         3   8
         4   9
         5  10
        ```
* `ws`: window size
* `hs`: hop-size
* `padding`: a string with the following possible values:
    * `none`: no padding is added and `z` is shortened to the biggest number
        multiple of `ws` and ≤ `length(z)`
    * `minimum`: `z` is padded both left and right with the minimum size needed to 
        toll over all the samples

* `padding_fill`: a value of type `K` with which `z` is padded

To get custom paddings, consider using the `PaddedViews` package or the
`FrameCutter` algorithm


## Returns

* if `T <: AbstractArray`, an `Array{T}` with one more dimension than the output of `fn`. 
* else `Vector{T}`

Each row is the output of a frame.
"""
function rollup(::Type{T},
                fn::Function,
                z::AbstractArray{K},
                ws::Integer,
                hs::Integer,
                padding::String="minimum",
                padding_fill::Real=0.0) where {T, K<:Number}

    # padding
    L = length(z)
    if padding === "none"
        _z = selectdim(z, 1, 1:floor(Int64, L / ws) * ws)
    elseif padding === "minimum"
        m = ceil(Int64, L / ws) * ws - L
        s1 = size(z, 1)
        s2 = size(z)[2:end]
        _z = PaddedView(padding_fill, 
                        z,
                        (s1 + m, s2...),
                        (ceil(Int64, m / 2) + 1, ones(Int64, length(s2))...))
    else 
        throw(EssentiaException("Unknown padding type"))
    end

    # instantiate output
    last_idx = length(_z)-ws
    out_len = floor(Int64, last_idx / hs)
    out = Vector{T}(undef, out_len)

    # rolling
    for i in 1:out_len
        # extract view
        start = i * hs
        stop = start + ws - 1
        e = selectdim(_z, 1, start:stop)

        # compute fn
        out[i] = fn(e)
    end

    if T <: AbstractArray
        # convert to Array with one more dim 
        if ndims(out[1]) == 1
            return hcat(out...)
        else
            return cat(out...; dims=ndims(out[1]) + 1)
        end
    else
        return out
    end
end
