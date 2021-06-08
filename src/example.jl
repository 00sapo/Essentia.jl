module Example
using Essentia

# 300 seconds
dur = 300
sr = 44100

"""
Execute a function a frames

    preallocate array
TODO: add padding, centered and reshaping output
"""
function roll(::Type{T}, fn::Function, z::AbstractArray, ws, hs) where {T}
    L = length(z)-ws+1
    out = Vector{T}(undef, 0)
    for i in 1:hs:L
        e =  (@view z[i:i+ws-1]) 
        # out[i] = fn(e)
        push!(out, fn(e))
    end
    return out
end

# a random vector as audio
audio = rand(sr*dur)
ws = 2048
hs = 1024
spec = Algorithm("Spectrum", "size" => 2048)
mel = Essentia.Algorithm("MelBands")
_spectrogram = roll(Float32, x -> jj(mel(spec("spectrum" => x)))["bands"], audio, ws, hs)
# spectrogram = hcat(_spectrogram...)
end # module
