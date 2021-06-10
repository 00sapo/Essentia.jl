using PaddedViews
export rollup, jj

"""
    function jj(objects::Tuple{Vector{Pair}, V})::Dict where V

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

"""
    function rollup(::Type{T},
                    fn::Function,
                    z::AbstractArray{K},
                    ws::Integer,
                    hs::Integer,
                    padding::String="minimum",
                    padding_fill::K=0.0) where {T, K<:Number}

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

To get custom paddings, consider using the `PaddedViews` package.


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
                padding_fill::K=0.0) where {T, K<:Number}

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
