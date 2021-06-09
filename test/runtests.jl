using Test
using Essentia


@testset "Essentia" begin
    ws = 2048
    hs = 1024
    win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
    spec = Algorithm("Spectrum", "size" => ws)

    @testset "Essentia Core" begin
        audio = rand(ws)
        windowed = win(audio)
        spectrum = spec(windowed)
        @test typeof(win) <: Algorithm
        @test typeof(windowed) <: Tuple
        @test typeof(spectrum) <: Tuple
        @testset "Essentia jj" begin
            @test all(jj(spectrum)["spectrum"] .> 0)
        end
    end

    @testset "Essentia rollup" begin
        audio = rand(11025*10)
        function spectrogram(ws, hs, padding)  
            win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
            spec = Algorithm("Spectrum", "size" => ws)
            rollup(
                Vector{Float32}, x -> jj(spec(win(x)))["spectrum"], audio, ws, hs, padding)
        end
        @test ndims(spectrogram(2048, 1024, "minimum")) == 2
        # test padding "none"
        @test ndims(spectrogram(2048, 1024, "none")) == 2
        # some tests with random ws and hs
        audio = rand(34)
        @test ndims(spectrogram(12, 8, "none")) == 2
        @test ndims(spectrogram(12, 8, "none")) == 2
        @test ndims(spectrogram(8, 1, "none")) == 2
    end
end
