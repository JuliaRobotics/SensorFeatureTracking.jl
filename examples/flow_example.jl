using SensorFeatureTracking, FixedPointNumbers, Colors
using ProfileView

projdir = joinpath(dirname(@__FILE__), "..")
# srcdir = joinpath(projdir,"src")
datadir = joinpath(projdir,"Data")
##
#read images
im1 = load(joinpath(datadir,"testSequence/image_$(70).jpg"))
im2 = load(joinpath(datadir,"testSequence/image_$(71).jpg"))

# feats = getapproxbestharris(im1, 20)
feats = getApproxBestShiTomasi(im1,nfeatures=1000, stepguess=0.95)

flow = BlockTracker(feats)

#Profile---
# flwtest = deepcopy(flow)
# @profile block_tracker!(flwtest, im1, im2) # JIT compiling
# Profile.clear()
# @profile block_tracker!(flwtest, im1, im2)
# ProfileView.view()

oldfeats = deepcopy(flow.features)

@time block_tracker!(flow, im1, im2)

# draw flow lines
image2 = deepcopy(im2)
map((ft1,ft2)->drawfeatureLine!(image2, Feature(ft1),Feature(ft2)),flow.features, oldfeats)
image2

##
# draw and mark features
image1 = deepcopy(im1)
map(ft->drawfeatureX!(image1, Feature(ft), length=3),oldfeats)

image2 = deepcopy(im2)
map(ft->drawfeatureX!(image2, Feature(ft), length=3),flow.features)
map(ft->drawfeatureX!(image2, Feature(ft), length=1),oldfeats)
grid = hcat(image1,image2)
grid


## ---------- Run in loop -------------------------------------------------------
startFrame = 50
numFrames = 50

im1 = load(joinpath(datadir,"testSequence/image_$(startFrame).jpg"))
im2 = load(joinpath(datadir,"testSequence/image_$(startFrame+1).jpg"))

(ro,co) = size(im1)
feats = getApproxBestShiTomasi(im1,nfeatures=200, stepguess=0.95)

flow = BlockTracker(feats, matchFunction = compute_ssd)
# grid_features!(flow,co,ro)

image1 = deepcopy(im1)
oldfeats = deepcopy(flow.features)
# @time block_tracker!(flow, im1, im2)
@time block_tracker!(flow, im1, im2)

blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),oldfeats,flow.features)


#
tic()
for frame_idx = startFrame+2:startFrame+numFrames -1
    println("Processing Frame: ", frame_idx)
    im1 = deepcopy(im2)
    im2 = load(joinpath(datadir,"testSequence/image_$(frame_idx).jpg"))

    # im2 = im2[range...]
    block_tracker!(flow, im1, im2)

    map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),flow.features, oldfeats)
    oldfeats = deepcopy(flow.features)
end
toc()

# overlay tracking traces with image
# o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,im2))
# b_img = reinterpret(Gray{N0f8},o_img)
o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,im2))
r_img = reinterpret(Gray{N0f8},o_img)
n_img = .~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,im2))
n_img = reinterpret(Gray{N0f8},n_img)
#
# colorview(RGB, n_img, n_img, b_img)
# colorview(RGB, n_img, g_img, n_img)
colorview(RGB, r_img, n_img, n_img)
