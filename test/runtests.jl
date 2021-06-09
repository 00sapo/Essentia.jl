using Test
using Essentia


ws = 2048
win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
spec = Algorithm("Spectrum", "size" => ws)
audio = rand(ws)
@test all(jj(spec(win(audio)))["spectrum"] .> 0)
