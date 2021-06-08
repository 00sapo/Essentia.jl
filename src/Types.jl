export EssentiaTuple, EssentiaVector, EssentiaFactory, EssentiaComplex, EssentiaMatrix

const EssentiaVector{T, N} = cxxt"vector<$T>"{N} where {T, N}
const EssentiaTuple{T, N} = cxxt"Tuple2<$T>"{N} where {T, N}
const EssentiaMatrix{T, N} = cxxt"TNT::Array2D<$T>"{N} where {T, N}
const EssentiaComplex{T, N} = cxxt"complex<$T>"{N} where {T, N}


"""
Given a `type_info *` C++ structure, returns a string which describes it (as Essentia Python bindings)
"""
function typeInfoToStr(type_info_ptr)::String
    # the following is copied from https://github.com/MTG/essentia/blob/master/src/python/typedefs.h#L62
    tp = icxx"*$type_info_ptr;"
    v = icxx"""
      if (essentia::sameType($tp, typeid(essentia::Real)))return $("REAL");
      if (essentia::sameType($tp, typeid(std::string)))return $("STRING");
      if (essentia::sameType($tp, typeid(int)))return $("INTEGER");
      if (essentia::sameType($tp, typeid(bool)))return $("BOOL");
      if (essentia::sameType($tp, typeid(essentia::StereoSample)))return $("STEREOSAMPLE");
      if (essentia::sameType($tp, typeid(std::vector<essentia::Real>)))return $("VECTOR_REAL");
      if (essentia::sameType($tp, typeid(std::vector<std::string>)))return $("VECTOR_STRING");
      if (essentia::sameType($tp, typeid(std::vector<std::complex<essentia::Real> >)))return $("VECTOR_COMPLEX");
      if (essentia::sameType($tp, typeid(std::vector<int>)))return $("VECTOR_INTEGER");
      if (essentia::sameType($tp, typeid(std::vector<essentia::StereoSample>)))return $("VECTOR_STEREOSAMPLE");
      if (essentia::sameType($tp, typeid(std::vector<std::vector<essentia::Real> >)))return $("VECTOR_VECTOR_REAL");
      if (essentia::sameType($tp, typeid(std::vector<std::vector<std::complex<essentia::Real> > >)))return $("VECTOR_VECTOR_COMPLEX");
      if (essentia::sameType($tp, typeid(std::vector<std::vector<std::string> >)))return $("VECTOR_VECTOR_STRING");
      if (essentia::sameType($tp, typeid(std::vector<std::vector<essentia::StereoSample> >)))return $("VECTOR_VECTOR_STEREOSAMPLE");
      // if (essentia::sameType($tp, typeid(essentia::Tensor<essentia::Real>)))return $("TENSOR_REAL");
      // if (essentia::sameType($tp, typeid(std::vector<essentia::Tensor<essentia::Real> >)))return $("VECTOR_TENSOR_REAL");
      if (essentia::sameType($tp, typeid(TNT::Array2D<essentia::Real>)))return $("MATRIX_REAL");
      if (essentia::sameType($tp, typeid(std::vector<TNT::Array2D<essentia::Real> >)))return $("VECTOR_MATRIX_REAL");
      // if (essentia::sameType($tp, typeid(essentia::Pool)))return $("POOL");
     return $("UNDEFINED");
    """
    # at now, Cxx cannot return strings... so creating the string in Julia and
    # makes it converting to `char*` and when it comes back it's still a
    # `Ptr{UInt8}`. So we now need to convert back to string.
    return unsafe_string(v)
end

"""
Given a `type_info` C++ structure, allocates the corresponding object and return a pointer to it

This function is NOT type-coherent!
"""
function getCppObjPtr(type_info)
    type_str = typeInfoToStr(type_info)
    # almost copied from
    # https://github.com/MTG/essentia/blob/master/src/python/pyalgorithm.cpp#L284
    if type_str == "REAL" return icxx"new Real;"
    elseif type_str == "STRING" return icxx"new string;"
    elseif type_str == "BOOL" return icxx"new bool;"
    elseif type_str == "INTEGER" return icxx"new int;"
    elseif type_str == "STEREOSAMPLE" return icxx"new StereoSample;"
    elseif type_str == "VECTOR_REAL" return icxx"new vector<Real>;"
    elseif type_str == "VECTOR_INTEGER" return icxx"new vector<int>;"
    elseif type_str == "VECTOR_COMPLEX" return icxx"new vector<complex<Real> >;"
    elseif type_str == "VECTOR_STRING" return icxx"new vector<string>;"
    elseif type_str == "VECTOR_STEREOSAMPLE" return icxx"new vector<StereoSample>;"
    elseif type_str == "VECTOR_VECTOR_REAL" return icxx"new vector<vector<Real> >;"
    elseif type_str == "VECTOR_VECTOR_COMPLEX" return icxx"new vector<vector<complex<Real> > >;"
    elseif type_str == "VECTOR_VECTOR_STRING" return icxx"new vector<vector<string> >;"
    # elseif type_str == "TENSOR_REAL" return icxx"new Tensor<Real>();"
    elseif type_str == "MATRIX_REAL" return icxx"new TNT::Array2D<Real>;"
    # elseif type_str == "POOL" return icxx"new Pool;"
    end
end

"""
Perform conversion from a C+ pointer to Julia according to the description in
`type_str` (returned by `typeInfoToStr`)

The return type changes according to `type_str`, so this function is NOT
guaranteed to be type coherent, even though it should be so.
"""
function es2julia(d::T, type_str::String) where T
    if type_str == "REAL" return unsafe_load(d)
    elseif type_str == "STRING" return unsafe_string(d)
    elseif type_str == "BOOL" return unsafe_load(d)
    elseif type_str == "INTEGER" return unsafe_load(d)
    elseif type_str == "STEREOSAMPLE" return convert(Tuple{Float32, Float32}, icxx"*$d;")
    elseif type_str == "VECTOR_REAL" return convert(Vector{Float32}, icxx"*$d;")
    elseif type_str == "VECTOR_INTEGER" return convert(Vector{Int32}, icxx"*$d;")
    elseif type_str == "VECTOR_COMPLEX" return convert(Vector{ComplexF32}, icxx"*$d;")
    elseif type_str == "VECTOR_STRING" return convert(Vector{String}, icxx"*$d;")
    elseif type_str == "VECTOR_STEREOSAMPLE" return convert(Matrix{Float32}, icxx"*$d;")
    elseif type_str == "VECTOR_REAL" return convert(Vector{Vector{Float32}}, icxx"*$d;")
    elseif type_str == "VECTOR_COMPLEX" return convert(Vector{Vector{ComplexF32}}, icxx"*$d;")
    elseif type_str == "VECTOR_STRING" return convert(Vector{Vector{String}}, icxx"*$d;")
    elseif type_str == "MATRIX_REAL" return convert(Matrix{Float32}, icxx"*$d;")
    else
        # @warn "Cannot convert from type $type_str to Julia!"
        return d
    end
end

"""
Perform conversion from Julia to Essentia types

The return type changes according to `T`, so this function is type coherent
"""
function julia2es_number(n::Type)
    if n <: Integer
        return Int32
    elseif n <: Real
        return Float32
    end
end
function julia2es(d::T) where T
    if T <: Number
        return convert(julia2es_number(T), d)
    elseif T <: Tuple
        return convert(EssentiaTuple{T.parameters[1]}, d)
    elseif T <: Array
        L = T.parameters[1]
        if L <: Number
            # a vector
            K = julia2es_number(L)
        elseif L <: Tuple
            # a vector of tuples
            V = julia2es_number(L.parameters[1])
            return convert(EssentiaVector{EssentiaTuple{V}}, d)
        else
            # a vector of vector
            V = julia2es_number(L.parameters[1])
            return convert(EssentiaVector{EssentiaVector{V}}, d)
        end
        if T.parameters[2] == 1
            return convert(EssentiaVector{K}, d)
        elseif T.parameters[2] == 2
            return convert(EssentiaMatrix{K}, d)
        end
    else
        return d
    end
end

"""
Convert Julia's `Vector{Vector{T}}` to Essentia's `std::vector<std::vector<T>>`
and vice-versa

Used internally.
"""
function Base.convert(
    ::Type{EssentiaVector{EssentiaVector{T, L}, N}}, x::Vector{Vector{K}}) where {T, L, N, K}
    resvec = [julia2es(x[i]) for xᵢ in x]
    return julia2es(resvec)
end

"""
Convert Julia's `Tuple{T}` to Essentia's `Tuple2<T>` and vice-versa

Used internally.

E.g. `StereoSample` typedef
"""
function Base.convert(::Type{EssentiaTuple{K}}, x::Tuple{T, T}) where {T, K}
    a = convert(K, x[1])
    b = convert(K, x[2])
    result = icxx"""
        Tuple2<$K> v = Tuple2<$K>();
        v.first = $a;
        v.second = $b;
        return v;
    """
    return result
end

function Base.convert(::Type{Tuple{T, T}}, x::EssentiaTuple{K}) where {T, K}
    a = convert(T, icxx"$x.first;")
    b = convert(T, icxx"$x.second;")
    return (a, b)
end

"""
Convert Julia's `Complex{T}` to C++'s `complex<T>` and vice-versa

Used internally.
"""
function Base.convert(::Type{EssentiaComplex{K}}, x::Complex{T}) where {T, K}
    re = convert(K, x.re)
    im = convert(K, x.im)
    return icxx"complex<$K>($re, $im);"
end
function Base.convert(::Type{Complex{K}}, x::EssentiaComplex{T, V}) where {T, K, V}
    re = convert(K, icxx"$x.real;")
    im = convert(K, icxx"$x.imag;")
    return Complex{K}(re, im)
end

"""
Convert Julia's `Matrix{T}` to Essentia's `vector<Tuple2<T>>` and vice-versa

Used internally.

"""
function Base.convert(::Type{Matrix{V}}, x::EssentiaVector{EssentiaTuple{K, T}}) where {V, K, T}
    res = convert(Vector{Tuple{V, V}}, x)
    if VERSION >= v"1.6"
        return reinterpret(reshape, V, res)
    else
        return reshape(reinterpret(V, res), 2, :)
    end
end

function Base.convert(::Type{EssentiaVector{EssentiaTuple{K, T}}}, x::Matrix{V}) where {V, K, T}
    res = [Tuple(row) for row in eachrow(x)]
    return convert(EssentiaVector{EssentiaTuple{K, V}}, res)
end

"""
Convert Julia's `Matrix{T}` to Essentia's `Matrix` (aka `TNT::Array2D`) and
vice-versa

Used internally.

N.B. The C++ object is not garbage-collected and some reference to `x` must
exist so that C++ can use the output array. If `x` doesn't exist, the data are
lost.
"""
function Base.convert(::Type{cxxt"TNT::Array2D<$K>"}, x::Matrix{T}) where {T, K}
    _x = convert(Matrix{K}, x)
    m = size(_x, 1)
    n = size(_x, 2)
    p = pointer(permutedims(_x))
    result = icxx"""
        TNT::Array2D<$K> v = TNT::Array2D<$K>($m, $n, $p);
        return v;
    """
    return result
end

function Base.convert(::Type{Matrix{K}}, x::EssentiaMatrix{K, T}) where {K, T}
    # TNT::Array2D can be automatically converted to C double pointers
    pointer = icxx"$K** v = $x; v;"
    m = icxx"$x.dim1();"
    n = icxx"$x.dim2();"
    result = Matrix{V}(undef, m, n)
    rows = Base.unsafe_wrap(Vector{Ptr{V}}, pointer, m)
    @inbounds @simd for i in 1:length(rows)
        result[i, :] = Base.unsafe_wrap(Vector{V}, rows[i], n)
    end
    return result
end

"""
Convert C++ vector of numbers (not tuples and strings) to Julia vectors in-place

Used internally.
"""
function Base.convert(::Type{Vector{T}}, x::EssentiaVector{T, K}) where {T<:Number, K}
    return unsafe_wrap(Vector{T}, icxx"$x.data();", icxx"$x.size();", own=true)
end
