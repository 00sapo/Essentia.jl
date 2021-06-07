using Cxx
using Libdl
# Open library (~ compiler flags)
essentia_path = joinpath(@__DIR__, "..", "essentia")
Libdl.dlopen(joinpath(essentia_path, "build", "src", "libessentia.so"), Libdl.RTLD_GLOBAL)
Cxx.addHeaderDir(joinpath(essentia_path, "src"), kind=C_System)

# includes
cxxinclude("essentia/algorithmfactory.h")

# using namespaces...
cxx"""
using namespace std;
using namespace essentia;
using namespace essentia::standard;
"""

# register algorithms
# the following is run inside a function...
icxx"""
essentia::init();
"""
