# Open library (~ compiler flags)
essentia_path = joinpath(@__DIR__, "..", "essentia")
Libdl.dlopen(joinpath(essentia_path, "build", "src", "libessentia.so"), Libdl.RTLD_GLOBAL)
Cxx.addHeaderDir(joinpath(essentia_path, "src"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "eigen3"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "lame"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "libavcodec"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "libavformat"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "libavresample"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "libavutil"), kind=C_System)
Cxx.addHeaderDir(joinpath(essentia_path, "packaging", "debian_3rdparty", "include", "taglib"), kind=C_System)

# includes
cxxinclude("essentia/algorithmfactory.h")
cxxinclude("essentia/pool.h")

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
