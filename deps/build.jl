using ZipFile
# setting JULIA_CXX_RTTI
ENV["JULIA_CXX_RTTI"] = 1

function unzip(file,exdir="")
    fileFullPath = isabspath(file) ?  file : joinpath(pwd(),file)
    basePath = dirname(fileFullPath)
    outPath = (exdir == "" ? basePath : (isabspath(exdir) ? exdir : joinpath(pwd(),exdir)))
    isdir(outPath) ? "" : mkdir(outPath)
    zarchive = ZipFile.Reader(fileFullPath)
    for f in zarchive.files
        fullFilePath = joinpath(outPath,f.name)
        if (endswith(f.name,"/") || endswith(f.name,"\\"))
            mkdir(fullFilePath)
        else
            write(fullFilePath, read(f))
        end
    end
    close(zarchive)
end

# entering root dir of the package
cur_dir = pwd()
cd(joinpath(@__DIR__, ".."))

# removing old build
if isdir("essentia")
    run(`rm -rf essentia`)
end

# downloading essentia
# commit 13 january 2021 (2.1-b6)
commit = "554502a06a39ebbe0de1b4797e3456ba18a090b1"
zippath = download("https://github.com/MTG/essentia/archive/$commit.zip")
unzip(zippath, ".")
run(`mv essentia-$commit essentia`)

cd("essentia")

# overwrite configuration (need to use `--disable-yasm`)
cp("../build_config.sh", "./packaging/build_config.sh"; force=true)

# recursively search .sh file and add execution permission
for (root, dirs, files) in walkdir(".")
    for file in files
        if endswith(file, ".sh")
            chmod(joinpath(root, file), 0o777)
        end
    end
end

# cleaning previous configurations (if rebuilding...)
try
    run(`python ./waf clean`)
catch exc
    println("cannot clean an unconfigured project!")
end

# downloading and building dependencies
run(`./packaging/build_3rdparty_static_debian.sh`)

# configuring with static dependencies
run(`python ./waf configure --static-dependencies -v`)

# compiling
run(`python ./waf -v`)
cd(cur_dir)
