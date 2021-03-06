using Documenter
using Essentia

push!(LOAD_PATH,"../src/")
makedocs(sitename="Essentia.jl Documentation",
         pages = [
            "Index" => "index.md",
         ],
         format = Documenter.HTML(prettyurls = false)
)
# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/00sapo/Essentia.jl.git",
    devbranch = "main"
)
