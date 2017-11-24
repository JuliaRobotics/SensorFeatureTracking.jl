using Images, ImageView, ImageDraw, ImageFeatures, TestImages
using SensorFeatureTracking
using StaticArrays, CoordinateTransformations

cd(dirname(@__FILE__))

include("../src/KLTTracker.jl")
datadir = "../Data"

## track a lot of features between 2 frames
startFrame = 50

im1 = float32.(load("../Data/testSequence/image_$(startFrame).jpg"))
im2g = load("../Data/testSequence/image_$(startFrame+1).jpg")
im2 = float32.(im2g)


(ro,co) = size(im1)

kpoints = getApproxBestShiTomasi(im1,nfeatures=200, stepguess=0.95)
# feats = map( kp -> KLTFeature(im1, kp, 15), kpoints)
oldfeats = deepcopy(kpoints)


tracker  = KLTTracker(im1, 10, Float32(0.05), kpoints )
@time tracker(im2)


@profile tracker(im2)

#
blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),oldfeats,tracker.features)

o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,im2g))
r_img = reinterpret(Gray{N0f8},o_img)

n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,im2g))
n_img = reinterpret(Gray{N0f8},n_img)
#
# colorview(RGB, n_img, n_img, b_img)
# colorview(RGB, n_img, g_img, n_img)
colorview(RGB, r_img, n_img, n_img)

## #################################################################################################

#Track features in for loop
startFrame = 50
numFrames = 50
# function trackKLTinLoop(startFrame::Int64, numFrames::Int64)

img1 = load(joinpath(datadir,"testSequence/image_$(startFrame).jpg"))
im1 = float32.(img1)
img2 = load(joinpath(datadir,"testSequence/image_$(startFrame+1).jpg"))
im2 = float32.(img2)

(ro,co) = size(im1)

kpoints = getApproxBestShiTomasi(im1,nfeatures=20, stepguess=0.95)

oldfeats = deepcopy(kpoints)
firstFeats = deepcopy(kpoints)
firstImg = deepcopy(img1)

tracker  = KLTTracker(im1, 10, Float32(0.05), kpoints )
@time tracker(im2)

blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),oldfeats,tracker.features)

#
tic()
for frame_idx = startFrame+2:(numFrames + startFrame - 2)

    img2[:] = load(joinpath(datadir,"testSequence/image_$(frame_idx).jpg"))
    im2[:] = float32.(img2)


    oldfeats = deepcopy(tracker.features)

    numlost = tracker(im2)
    if numlost > 0
        println("Replacing Lost Feature")
        addBestShiTomasi!(im2, tracker)
    end

    map((ft1,ft2, validcount)-> validcount > 0 && drawfeatureLine!(blankImg,
                                            Feature(CartesianIndex(round.(Int,ft1.affinity.v[1:2])...)),
                                            Feature(CartesianIndex(round.(Int,ft2.affinity.v[1:2])...))),
                                            oldfeats, tracker.features, tracker.validCounts)

end
toc()
#
o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,img2))
r_img = reinterpret(Gray{N0f8},o_img)
n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,img2))
n_img = reinterpret(Gray{N0f8},n_img)
colorview(RGB, r_img, n_img, n_img)




# @time trackKLTinLoop(startFrame,numFrames)

#
