Essentia.jl
===========

Julia bindings around Essentia C++ library for Music Information Retrieval

[Docs](https://00sapo.github.io/Essentia.jl/build/) are temporarily built
off-line until issues with linking against Julia's libstdc++ are fixed.


## Usage

To create an algorithm, just call `Algorithm` functor with parameters in Pair
fashion:
```julia
windowing_algo = Algorithm("Windowing", "type" => "hamming", "size" => ws)
```

To run it, you have two options:

* key-value definition of inputs:
    ```julia 
    windowed = windowing_algo("frame" => a_vector_of_real)
    ```
* just the inputs in the same order as Essentia docs:
    ```julia 
    windowed = windowing_algo(a_vector_of_real)
    ```

Actually, there's a third way of passing inputs, but it's meant to be used
internally to avoid copies while composing algorithms. In the examples above,
`windowed` is a `Tuple` containing two C++ objects, the first being the output
and the second being a type descriptor. You can call an algorithm with this
tuple as input:
```julia
windowing_algo = Algorithm("Windowing", "type" => "hamming", "size" => ws)
spec = Algorithm("Spectrum", "size" => ws)
windowed = windowing_algo(a_vector_of_real)
spectrum = spec(windowed)
```

To get the output inside a Julia object, just use the function `jj`.

For computing spectrograms, a `rollup` function is provided, which executes a
custom function on all the frames extracted from an array:
```julia
ws = 2048
hs = 1024
win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
spec = Algorithm("Spectrum", "size" => ws)

spectrogram = rollup(
    Vector{Float32}, x -> jj(spec(win(x)))["spectrum"], audio, ws, hs, padding="minimum", padding_fill=0)
```

You can get more custom paddings by using the `PaddedViews` package.

See `src/example.jl` and [docs](https://00sapo.github.io/Essentia.jl/build/) for more info.


## Type Conversion table

You can simply use the Essentia
[documentation](https://essentia.upf.edu/reference/) and refer to this table for
type conversion.

| Julia          | Essentia Docs        |
|----------------|----------------------|
| Float32        | Real                 |
| Int32          | Integer              |
| Complex        | Complex              |
| String         | String               |
| Bool           | Bool                 |
| Vector         | Vector               |
| Vector{Vector} | Vector_Vector        |
| Matrix         | Matrix               |
| Tuple          | StereoSample         |
| Matrix         | Vector{StereoSample} |

## Installing

* This package is based on `Cxx.jl`, and as consequence, it currently supports
    Julia from 1.0.x to 1.3.x.

* Julia 1.3.1 provides a `libstdc++.so` that is not up-to-date with some updated OS
    To avoid this problem, you can `export LD_PRELOAD=$(cc -print-file-name=libstdc++.so)`
    before of starting Julia.

* To build Essentia, it is recommended to [install the dependencies by
    yourself](https://essentia.upf.edu/installing.html#installing-dependencies-on-linux)

    Note for contributor: the build script provides a way to download and
    statically compile the dependencies, but `AudioLoader` and similar
    algorithms do not work...

```julia
Using Pkg
Pkg.add("https://github.com/00sapo/Essentia.jl.git")
```

## Notes

* this package turns on RTTI by setting the environment variable
    `JULIA_CXX_RTTI="1"` at when imported

## Done

* Standard algorithms
* Audio in stereo are converted to and from Matrices with 2 columns
* Conversion C++ vectors -> Julia vectors of numbers with no-copy (the inverse
    is not possible because of C++ vector implementation)
* You can still create and pass C++ data by using `icxx` and `cxx` macros to
    avoid data copy
* Composition of functions with no-copy except for input/output of each call
* Algorithms which return `Pool` objects now work, but user still needs to
    interface using Cxx...

## Missing

* Functions in `essentia` namespace; however you can do:
    ```julia
    using Cxx
    using Essentia
    mel = 24.5
    hz = icxx"essentia::mel2hz($a)"
    ```
* Algorithms which need the `Tensor` type
* Streaming algorithms (do we really need them?)

## Issues

* The package cannot be pre-compiled. As such, it is compiled at the first
    import in your code.
* Cannot automatically compile the module because of the linking problem; as
    consequence, cannot use github actions or CI systems

# TODO

* Fix the linking to libstdc++.so
