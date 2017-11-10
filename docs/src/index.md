# SensorFeatureTracking.jl
*Feature Tracking Algorithms for Julia.*

Algorithms to track features of interest, such as KLT and Block Matching.
Feature tracking with inertial sensor aiding, such as gyroscope aided feature tracking.
Utilities to aid in alignment of camera and other sensors.
Camera geomitry utilities such as camera models and projection.

## Package Features

- Tracking Algorithms
- Feature Detection
- IMU Tracking Utilities
- Supports Julia `0.6`

## Installing

This is an unregistered Julia package, but can be readily installed from a Julia console:
```julia
Pkg.clone("https://github.com/<YOURFORKEDREPO>/SensorFeatureTracking.jl.git")
```

Upstream master is at: `https://github.com/dehann/SensorFeatureTracking.jl.git`


## Examples

Please see, as part of the development, the `examples` folder.

Please note this code is not yet optimized in any way. Performance can be improved.

## Manual Outline

```@contents
Pages = [
    "index.md"
    "func_ref.md"
]
```
