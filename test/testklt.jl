using SensorFeatureTracking
using Images
using CoordinateTransformations
using StaticArrays
using Base: Test
##
cd(dirname(@__FILE__))

include("../src/KLTTracker.jl")


@testset "KLTTracker" begin
    drawon = false
    range = -25:25
    rangein = -20:20
    centres = [[125, 125], [325, 125], [225, 225], [325, 525], [125, 325], [125, 425]]
    intensities = [120, 180, 100, 200, 120, 150]
    testim = zeros(Gray{N0f8},480,640)
        foreach((c,i) -> testim[c[1] + range, c[2] + range] = i/255, centres, intensities)
        foreach((c,i) -> testim[c[1] + rangein, c[2] + rangein] = (i/2)/255, centres, intensities)
        testim

    rtfm = recenter(RotMatrix(pi/500), SVector{2}(200, 200))
    otfm = AffineMap(MMatrix{2,2}([1.004 0; -0.01 1.004]), MVector{2,Float32}(-1,0))

    im1 = float32.(testim)
    (ro,co) = size(im1)

    kpoints = getApproxBestShiTomasi(im1,nfeatures=20, stepguess=0.8)

    tracker  = KLTTracker(im1, 10, Float32(0.05), kpoints )

    blankImg = zeros(Gray{N0f8},ro,co)

    tfmgrow = AffineMap(MMatrix{2,2}(eye(2)), MVector{2,Float32}(0.,0))
    #
    for frame_idx = 1:50

        tfmgrow = tfmgrow ∘ rtfm ∘ otfm
        im = SensorFeatureTracking.padandcutoffsetImg(warp(testim, tfmgrow), 480, 640)
        im1[:] = float32.(im)
        oldfeats = deepcopy(tracker.features)

        numlost = tracker(im1)
        if numlost > 0
            println("Replacing Lost Feature")
            addBestShiTomasi!(im1, tracker)
        end
        if drawon
            map((ft1,ft2, validcount)-> validcount > 0 && drawfeatureLine!(blankImg,
                                                    Feature(CartesianIndex(round.(Int,ft1.affinity.v[1:2])...)),
                                                    Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),
                                                    oldfeats, tracker.features, tracker.validCounts)
        end
    end

    for frame_idx = 1:51

        tfmgrow = tfmgrow ∘ inv(rtfm) ∘ inv(otfm)
        if frame_idx == 51
            tfmgrow = AffineMap(MMatrix{2,2}(eye(2)), MVector{2,Float32}(0.,0))
        end

        im = SensorFeatureTracking.padandcutoffsetImg(warp(testim, tfmgrow), 480, 640)
        im1[:] = float32.(im)
        oldfeats = deepcopy(tracker.features)

        numlost = tracker(im1)
        if numlost > 0
            println("Replacing Lost Feature")
            addBestShiTomasi!(im1, tracker)
        end
        if drawon
            map((ft1,ft2, validcount)-> validcount > 0 && drawfeatureLine!(blankImg,
                                                    Feature(CartesianIndex(round.(Int,ft1.affinity.v[1:2])...)),
                                                    Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),
                                                    oldfeats, tracker.features, tracker.validCounts)
        end
    end
    #
    if drawon
        o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,im))
        r_img = reinterpret(Gray{N0f8},o_img)
        n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,im))
        n_img = reinterpret(Gray{N0f8},n_img)
        colorview(RGB, r_img, n_img, n_img)
    end
    #

    kltfeatarr = map((ft) -> [ft.affinity.v[1:2]...], tracker.features )
    reffeatarr = map((ft) -> [Float32(ft[1]), Float32(ft[2])], kpoints )
    @show kltfeatarr
    @show reffeatarr

    @test kltfeatarr ≈ reffeatarr

end

##
