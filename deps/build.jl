# setting JULIA_CXX_RTTI
ENV["JULIA_CXX_RTTI"] = 1

cur_dir = pwd()
cd(joinpath(@__DIR__, ".."))

# update essentia
run(`git submodule update --init`)

# checkout last python release (need to find a way for auto select it...)
cd("essentia")
run(`git checkout ed59cc48`)

# overwrite configuration (need to use `--disable-yasm`
cp("./build_config.sh", "essentia/packaging/")

# cleaning previous configurations (if rebuilding...)
try
    run(`./waf clean`)
catch exc
    println("cannot clean an uncofigured project!")
end

# # downloading and building dependencies
run(`./packaging/build_3rdparty_static_debian.sh`)

# configuring with static dependencies
run(`./waf configure --static-dependencies -v`)

# compiling
run(`./waf -v`)
cd(cur_dir)
