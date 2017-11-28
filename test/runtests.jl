using SensorFeatureTracking
using Base: Test


@testset "SensorFeatureTracking" begin
    # Common
    include("sensorgeometry.jl")
    include("blockflow.jl")

end
