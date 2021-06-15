Essentia.jl
===========

Julia bindings around Essentia C++ library for Music Information Retrieval

* [Documentation of Julia API](https://00sapo.github.io/Essentia.jl/build/)
* [Documentation of Python API (for Algorithms)](https://essentia.upf.edu/reference//)
* [Documentation of C++ API](https://essentia.upf.edu/doxygen/)


## Tutorial

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
windowed = windowing_algo(a_vector_of_real)
# adding another algorithm without copy
spectrum = spec(windowed) 
# spectrum is still a tuple of C++ objects
```

To get the output inside a Julia object, just use the function `jj`:

```julia
spectrum = jj(spectrum)
# now spectrum is a Dict...
output = spectrum["spectrum"]
# this is the output (Vector{Float32} in this case)
```

Or, to make it more conveniente composing algorithms, you can use the `@es` macro and `EssentiaComp`
functor; the former is actually anoter way to use the latter, which is itself a
functor for using `∘` Julia operator + `jj` function. Since it's a functor, it's
a performant way to create composition of algorithms and to pass them as
argument of functions.

```julia
# using ∘
fn = x -> jj(∘(spec, windowing_algo)(audio))["spectrum"]
# you see that the syntax is complex and the fn is not of concrete type

# using EssentiaComp
fn = EssentiaComp([spec, windowing_algo], "spectrum")
# it's a concrete type, bu the syntax is ugly

# using @es macro
fn = @es windowing_algo spec "spectrum"
# it's concrete and with a clean syntax

# execute:
fn(audio)
```

For computing spectrograms, a `rollup` function is provided, which executes a
custom function on all the frames extracted from an array:
```julia
ws = 2048
hs = 1024
win = Algorithm("Windowing", "type" => "hamming", "size" => ws)
spec = Algorithm("Spectrum", "size" => ws)

spectrogram = rollup(
    Vector{Float32},
    @es win spec "spectrum",
    audio, ws, hs, padding="minimum", padding_fill=0)
```

You can get more custom paddings by using the `PaddedViews` package, or you can use
the "FrameCutter" algorithm provided by Essentia...

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
| Matrix         | Vector_StereoSample  |

## Installing

* This package is based on `Cxx.jl`, and as consequence, it currently supports
    Julia from 1.0.x to 1.3.x.

* Julia 1.3.1 provides a `libstdc++.so` that is not up-to-date with some updated OS
    To avoid this problem, you can use `LD_PRELOAD=$(cc -print-file-name=libstdc++.so)`
    before of starting Julia, e.g.

    ```shell
    alias julia LD_PRELOAD=$(cc -print-file-name=libstdc++.so)
    # or just start with
    LD_PRELOAD=$(cc -print-file-name=libstdc++.so) julia
    # export in the current session
    export LD_PRELOAD=$(cc -print-file-name=libstdc++.so)
    # or put the above in your startup file
    ```

* Because of the above issue, you have to install the package using the github
    link:

    ```julia
    Using Pkg
    Pkg.add("https://github.com/00sapo/Essentia.jl.git")
    ```

* For systems other than Linux (e.g. Mac OS and Windows) you have a few options:
    1. Try to install this package and... finger crossed
    2. If it doesn't work, try to change `deps/build.jl` making it use the
        correct Essentia build script (you find them in `essentia/packaging/`);
        if you succeed, make a pull request, please.
    3. Use Linux -- it's free
    4. Really, try Linux, it's better

## Notes

* this package turns on RTTI by setting the environment variable
    `JULIA_CXX_RTTI=1` when imported
* if you use the Cxx import, import it *after* the Essentia module, 
    or set `ENV["JULIA_CXX_RTTI"] = 1` before of importing Cxx

## Done

* Standard algorithms (except for `TensorFlow`-based)
* Audio in stereo are converted to and from Matrices with 2 columns
* You can still create and pass C++ data by using `icxx` and `cxx` macros to
    avoid data copy
* Composition of functions with no-copy except for input/output of each call
* Support for algorithms returning `Pool` objects

## Missing

* Functions in `essentia` namespace; however you can do:
    ```julia
    using Essentia
    using Cxx
    a = 24.5
    hz = icxx"essentia::mel2hz($a)"
    ```
* Algorithms which need the `Tensor` type
* Streaming algorithms (do we really need them?)

## Issues

* The package cannot be pre-compiled. As such, it is compiled at the first
    import in your code.
* Cannot register the module on JuliaHub because of the linking problem.

# TODO

* Fix the linking to libstdc++.so
