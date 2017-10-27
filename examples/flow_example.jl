using Images, ImageView, ImageDraw, ImageFeatures, TestImages
using SensorFeatureTracking

@show projdir = joinpath(dirname(@__FILE__), "..")
srcdir = joinpath(projdir,"src")
datadir = joinpath(projdir,"Data")
include(joinpath(srcdir, "Common.jl"))
include(joinpath(srcdir, "BlockMatchingFLow.jl"))

##
#read images and convert to UInt8
gray1 = load(joinpath(datadir,"testSequence/image_$(70).jpg"))
im1 = reinterpret(UInt8, gray1)

gray2 = load(joinpath(datadir,"testSequence/image_$(71).jpg"))
im2 = reinterpret(UInt8, gray2)

#crop
px = 1
py = 1
ps = 479
range = px:1:px+ps,py:1:py+ps
im1 = im1[range...]
im2 = im2[range...]
# ps = 250
##


# feats = getapproxbestharris(im1, 20)
feats = getApproxBestShiTomasi(im1,nfeatures=1000, stepguess=0.95)
flow = BlockTracker(ps+1,10,100,10000,Keypoints(feats),compute_ssd_8x8)

oldfeats = deepcopy(flow.features)

@time block_tracker(flow, im1, im2)

##
# draw and mark features
image1 = deepcopy(reinterpret(Gray{N0f8},im1))
map(ft->drawfeatureX!(image1, Feature(ft), length=3),oldfeats)

image2 = deepcopy(reinterpret(Gray{N0f8},im2))
map(ft->drawfeatureX!(image2, Feature(ft), length=3),flow.features)
map(ft->drawfeatureX!(image2, Feature(ft), length=1),oldfeats)
grid = hcat(image1,image2)
grid

##
# draw flow lines
image2 = deepcopy(reinterpret(Gray{N0f8},im2))
map((ft1,ft2)->drawfeatureLine!(image2, Feature(ft1),Feature(ft2)),flow.features, oldfeats)
image2


## Run in loop

gray1 = load(joinpath(datadir,"testSequence/image_$(50).jpg"))
im1 = reinterpret(UInt8, gray1)

gray2 = load(joinpath(datadir,"testSequence/image_$(51).jpg"))
im2 = reinterpret(UInt8, gray2)

px = 1
py = 1
ps = 479
range = px:1:px+ps,py:1:py+ps
im1 = im1[range...]
im2 = im2[range...]


(ro,co) = size(im1)
feats = getApproxBestShiTomasi(im1,nfeatures=300, stepguess=0.95)

flow = BlockTracker(ps+1,10,100,10000,Keypoints(feats),compute_ssd_8x8)

blankImg = zeros(Gray{N0f8},ro,co)

image1 = deepcopy(im1)
oldfeats = deepcopy(flow.features)

@time block_tracker(flow, im1, im2)

blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),oldfeats,flow.features)
#
for frame_idx = 52:99

    im1 = deepcopy(im2)
    gray2 = load(joinpath(datadir,"testSequence/image_$(frame_idx).jpg"))
    im2 = reinterpret(UInt8, gray2)
    im2 = im2[range...]

    @time block_tracker(flow, im1, im2)

    map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),flow.features, oldfeats)
    oldfeats = deepcopy(flow.features)

end

o_img = (reinterpret(UInt8,blankImg)) .| im2
o_img = reinterpret(Gray{N0f8},o_img)
