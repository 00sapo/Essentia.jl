# setting JULIA_CXX_RTTI
ENV["JULIA_CXX_RTTI"] = 1

cur_dir = pwd()
cd(joinpath(@__DIR__, ".."))
run(`git submodule update --init`)
cd("essentia")
run(`./waf clean`)

# downloading and building dependencies
run(`./packaging/build_3rdparty_static_debian.sh`)

# configuring with static dependencies
run(`./waf configure --static-dependencies`)

# compiling
run(`./waf -v`)
cd(cur_dir)
