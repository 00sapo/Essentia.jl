# setting JULIA_CXX_RTTI
ENV["JULIA_CXX_RTTI"] = 1

cur_dir = pwd()
cd(joinpath(@__DIR__, ".."))

if !isdir("essentia")
    run(`git submodule update --init`)
end

# checkout last python release (need to find a way for auto select it...)
cd("essentia")
# commit 13 january 2021 (2.1-b6)
run(`git reset --hard 554502a06a39ebbe0de1b4797e3456ba18a090b1`)
# commit 2019 (2.1-b5)
# run(`git reset --hard ed59cc48`)

# overwrite configuration (need to use `--disable-yasm`)
cp("../build_config.sh", "./packaging/build_config.sh"; force=true)

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
