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
        img = SensorFeatureTracking.padandcutoffsetImg(warp(testim, tfmgrow), 480, 640)
        im1[:] = float32.(img)
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

        img = SensorFeatureTracking.padandcutoffsetImg(warp(testim, tfmgrow), 480, 640)
        im1[:] = float32.(img)
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
        o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,testim))
        r_img = reinterpret(Gray{N0f8},o_img)
        n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,testim))
        n_img = reinterpret(Gray{N0f8},n_img)
        colorview(RGB, r_img, n_img, n_img)
    end
    #

    kltfeatarr = map((ft) -> [ft.affinity.v[1:2]...], tracker.features )
    reffeatarr = map((ft) -> [Float32(ft[1]), Float32(ft[2])], kpoints )

    @test kltfeatarr ≈ reffeatarr

    #test out of range on constructor and new addBestShiTomasi
    im1 = float32.(testim[50:200,5:160])
    kpoints = getApproxBestShiTomasi(im1,nfeatures=4, stepguess=0.8)
    track  = KLTTracker(im1, 10, Float32(0.05), kpoints )

    addBestShiTomasi!(im1, track)
    addBestShiTomasi!(im1, track)

    @test CartesianIndex.([(51,96),(101,96),(56,141),(96,141)]) == map((ft) ->  CartesianIndex(round.(Int,ft.affinity.v[1:2])...), track.features )
    # image1 = deepcopy(im1)
    # map(ft->drawfeatureX!(image1, Feature(ft.keypoint), length=3),track.features)
    # image1


end


##
# drawon = true
# range = -25:25
# rangein = -20:20
# centres = [[125, 125], [325, 125], [225, 225], [325, 525], [125, 325], [125, 425]]
# intensities = [120, 180, 100, 200, 120, 150]
# testim = zeros(Gray{N0f8},480,640)
#     foreach((c,i) -> testim[c[1] + range, c[2] + range] = i/255, centres, intensities)
#     foreach((c,i) -> testim[c[1] + rangein, c[2] + rangein] = (i/2)/255, centres, intensities)
#     testim
#
# rtfm = recenter(RotMatrix(pi/300), SVector{2}(200, 200))
# otfm = AffineMap(MMatrix{2,2}([1.004 0; -0.01 1.004]), MVector{2,Float32}(-1.,-0.5))
#
# im1 = float32.(testim)
# (ro,co) = size(im1)
#
# kpoints = getApproxBestShiTomasi(im1,nfeatures=20, stepguess=0.9)
#
# tracker  = KLTTracker(im1, 10, Float32(0.05), kpoints )
#
# blankImg = zeros(Gray{N0f8},ro,co)
#
# tfmgrow = AffineMap(MMatrix{2,2}(eye(2)), MVector{2,Float32}(0.,0))
# #
# img = nothing
# for frame_idx = 1:50
#
#     tfmgrow = tfmgrow ∘ rtfm ∘ otfm
#     img = SensorFeatureTracking.padandcutoffsetImg(warp(testim, tfmgrow), 480, 640)
#     im1[:] = float32.(img)
#     oldfeats = deepcopy(tracker.features)
#
#     numlost = tracker(im1)
#     while numlost > 0
#         println("Replacing Lost Feature $frame_idx")
#         addBestShiTomasi!(im1, tracker)
#         numlost -= 1
#     end
#     if drawon
#         map((ft1,ft2, validcount)-> validcount > 0 && drawfeatureLine!(blankImg,
#                                                 Feature(CartesianIndex(round.(Int,ft1.affinity.v[1:2])...)),
#                                                 Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),
#                                                 oldfeats, tracker.features, tracker.validCounts)
#     end
# end
#
# o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,img))
# r_img = reinterpret(Gray{N0f8},o_img)
# n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,img))
# n_img = reinterpret(Gray{N0f8},n_img)
# colorview(RGB, r_img, n_img, n_img)
# #
# for frame_idx = 1:51
#
#     tfmgrow = tfmgrow ∘ inv(rtfm) ∘ inv(otfm)
#     if frame_idx == 51
#         tfmgrow = AffineMap(MMatrix{2,2}(eye(2)), MVector{2,Float32}(0.,0))
#     end
#
#     img = SensorFeatureTracking.padandcutoffsetImg(warp(testim, tfmgrow), 480, 640)
#     im1[:] = float32.(img)
#     oldfeats = deepcopy(tracker.features)
#
#     numlost = tracker(im1)
#     if numlost > 0
#         println("Replacing Lost Feature")
#         addBestShiTomasi!(im1, tracker)
#     end
#     if drawon
#         map((ft1,ft2, validcount)-> validcount > 0 && drawfeatureLine!(blankImg,
#                                                 Feature(CartesianIndex(round.(Int,ft1.affinity.v[1:2])...)),
#                                                 Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),
#                                                 oldfeats, tracker.features, tracker.validCounts)
#     end
# end
# #
# if drawon
#     o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,testim))
#     r_img = reinterpret(Gray{N0f8},o_img)
#     n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,testim))
#     n_img = reinterpret(Gray{N0f8},n_img)
#     colorview(RGB, r_img, n_img, n_img)
# end
# #
#
# kltfeatarr = map((ft) -> [ft.affinity.v[1:2]...], tracker.features )
# reffeatarr = map((ft) -> [Float32(ft[1]), Float32(ft[2])], kpoints )
#
#
# @test kltfeatarr ≈ reffeatarr
# colorview(RGB, r_img, n_img, n_img)
