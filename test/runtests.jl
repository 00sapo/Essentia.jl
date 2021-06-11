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

        @testset "algorithms" begin
            @test typeof(win) <: Algorithm
            @test typeof(windowed) <: Tuple
            @test typeof(spectrum) <: Tuple
        end

        jj_spec = jj(spectrum)["spectrum"]
        @testset "jj" begin
            @test all(jj_spec .> 0)
        end

        # @testset "no-copy conversion" begin
        #     jj_spec .= 0
        #     jj_spec_new = jj(spectrum)["spectrum"]
        #     @test all(jj_spec_new .== 0)
        # end

        @testset "Essentia Loader, Writer and Pool" begin
            audio = rand(44100*10)
            Algorithm(
                "MonoWriter", "sampleRate"=>44100, "filename"=>"tmp.flac", "format"=>"flac")(audio)
            @test isfile("tmp.flac")
            out = jj(Algorithm("MusicExtractor")("tmp.flac")) 
            @test typeof(out) <: Dict
            rm("tmp.flac")
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
