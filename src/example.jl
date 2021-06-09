module Example
using Essentia
using Plots

function main()
    # 300 seconds
    dur = 300
    sr = 44100

    # a random vector as audio
    audio = rand(sr*dur)
    ws = 2048
    hs = 1024

    # creating an algorithm
    win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
    spec = Algorithm("Spectrum", "size" => ws)
    mel = Algorithm("MelBands")

    # running on a frame:
    println("Computing Spectrum on a frame...")
    frame = @view audio[1:ws]
    windowed = win(frame)
    spectrum = spec(windowed)
    melbands = mel(spectrum)

    # running composition of algos on a full audio array
    println("Computing Mel-spectrogram...")
    spectrogram = rollup(Vector{Float32}, x -> jj(mel(spec(win(x))))["bands"], audio, ws, hs)
    println("Plotting...")
    gr()
    p1 = Plots.plot(jj(spectrum)["spectrum"])
    p2 = Plots.plot(jj(melbands)["bands"])
    p3 = Plots.heatmap(spectrogram[:, 1:floor(Int64, 10*sr/hs)])
    return p1, p2, p3
end
end # module
