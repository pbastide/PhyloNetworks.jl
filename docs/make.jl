using Documenter, PhyloNetworks

makedocs()

deploydocs(
    deps   = Deps.pip("pygments", "mkdocs==0.17.5", "mkdocs-material==2.9.4", "python-markdown-math"),
    repo = "github.com/pbastide/PhyloNetworks.jl.git",
    julia  = "0.6",
    osname = "linux",
    latest = "weave_doc"
)
