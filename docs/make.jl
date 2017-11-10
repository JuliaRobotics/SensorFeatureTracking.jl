using Documenter, SensorFeatureTracking

makedocs(
    modules = [SensorFeatureTracking],
    format = :html,
    sitename = "SensorFeatureTracking.jl",
    pages = Any[
        "Home" => "index.md",
        "Functions" => "func_ref.md"
    ]
    # html_prettyurls = !("local" in ARGS),
    )


deploydocs(
    repo   = "github.com/Affie/SensorFeatureTracking.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
    julia  = "release"

)



# deploydocs(
#     deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-material"),
#     repo   = "github.com/dehann/SensorFeatureTracking.jl.git",
#     julia  = "release",
# )
