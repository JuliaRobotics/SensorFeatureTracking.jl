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
    repo   = "github.com/JuliaRobotics/SensorFeatureTracking.jl.git",
    target = "build"
)




# deploydocs(
#     deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-material"),
#     repo   = "github.com/JuliaRobotics/SensorFeatureTracking.jl.git",
#     julia  = "release",
# )
