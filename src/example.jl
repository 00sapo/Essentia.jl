module Example
using Essentia
using Plots

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

using Infiltrator
function main()
    # a random vector as audio
    audio = rand(sr*dur)
    ws = 2048
    hs = 1024

    # creating an algorithm
    win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
    spec = Algorithm("Spectrum", "size" => ws)
    mel = Algorithm("MelBands")

    # running on a frame:
    frame = @view audio[1:ws]
    windowed = win("frame" => frame)
    spectrum = spec(windowed)
    melbands = mel(spectrum)

    # running composition of algos on a full audio array
    _spectrogram = roll(Vector{Float32}, x -> jj(mel(spec(win("frame" => x))))["bands"], audio, ws, hs)
    spectrogram = hcat(_spectrogram...)
    gr()
    p1 = Plots.plot(jj(spectrum)["spectrum"])
    p2 = Plots.plot(jj(melbands)["bands"])
    p3 = Plots.heatmap(spectrogram[:, 1:floor(Int64, 10*sr/hs)])
    return p1, p2, p3
end
end # module
