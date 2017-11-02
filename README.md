# SensorFeatureTracking

[![Build Status](https://travis-ci.org/dehann/SensorFeatureTracking.jl.svg?branch=master)](https://travis-ci.org/dehann/SensorFeatureTracking.jl)
[![codecov.io](https://codecov.io/github/dehann/SensorFeatureTracking.jl/coverage.svg?branch=master)](https://codecov.io/github/dehann/SensorFeatureTracking.jl?branch=master)

Algorithms to track features of interest, such as KLT.

## Installing

This is an unregistered Julia package, but can be readily installed from a Julia console:
```julia
Pkg.clone("https://github.com/<YOURFORKEDREPO>/SensorFeatureTracking.jl.git")
```

Upstream master is at: `https://github.com/dehann/SensorFeatureTracking.jl.git`


## Examples

Please see, as part of the development, two cases in the `examples` folder. These examples currently extract corner features from either an image file, or a webcam image sequence.

Please note this code is not yet optimized in any way. Performance can be improved.

## Unit Test

Basic unit tests are currently under development in the `test` folder. Unit tests can be run by typing:
```julia
Pkg.test("SensorFeatureTracking")
```
