Essentia.jl
===========

Julia bindings around Essentia C++ library for Music Information Retrieval

## Done

* Standard algorithms
* Streaming algorithms (not tested, though)
* Audio in stereo are converted to and from Matrices with 2 columns
* C++ to Julia vectors of numbers with no-copy (the inverse is not possible
    because of C++ vector implementation)
* You can still create and pass C++ data by using `icxx` and `cxx` macros to
    avoid data copy

## Missing

* Functions in `essentia` namespace; however you can do:
    ```julia
    using Cxx
    using Essentia
    mel = 24.5
    hz = icxx"essentia::mel2hz($a)"
    ```
* Algorithms which need the `Tensor` and `Pool` types

## Installing

* This package is based on `Cxx.jl`, and as consequence, it currently supports Julia from 1.0.x to 1.3.x.
* Julia `libstdc++.so` is not up-to-date with some OS (e.g. Manjaro Linux); you
    will need to symlink the Julia library (`<julia_dir>/lib/julia/libstdc++.so.6`) to the system one.
    This could be avoided if I manage to let Essentia compile with a specific
    `libstdc++.so`
* `export JULIA_CXX_RTTI="1"` must be set before compiling Cxx...

# TODO

* build script
* tests and examples
* release
