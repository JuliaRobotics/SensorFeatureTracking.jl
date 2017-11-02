using SensorFeatureTracking, FixedPointNumbers, Colors
using ProfileView

@show projdir = joinpath(dirname(@__FILE__), "..")
srcdir = joinpath(projdir,"src")
datadir = joinpath(projdir,"Data")

##
#read images
im1 = load(joinpath(datadir,"testSequence/image_$(70).jpg"))
# im1 = reinterpret(UInt8, gray1)

im2 = load(joinpath(datadir,"testSequence/image_$(71).jpg"))
# im2 = reinterpret(UInt8, gray2)

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

flow = BlockTracker(ps+1,10,10,10000,Keypoints(feats),compute_ncc)

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
##


## Run in loop

im1 = load(joinpath(datadir,"testSequence/image_$(50).jpg"))
# im1 = reinterpret(UInt8, im1) #already gray

im2 = load(joinpath(datadir,"testSequence/image_$(51).jpg"))
# im2 = reinterpret(UInt8, im2)

px = 1
py = 1
ps = 479
range = px:1:px+ps,py:1:py+ps
im1 = im1[range...]
im2 = im2[range...]


(ro,co) = size(im1)
feats = getApproxBestShiTomasi(im1,nfeatures=500, stepguess=0.95)

flow = BlockTracker(ps+1,10,10,10000,Keypoints(feats),compute_ncc)
flwtest = deepcopy(flow)
# grid_features!(flow)

image1 = deepcopy(im1)
oldfeats = deepcopy(flow.features)

# @time block_tracker!(flow, im1, im2)
@time block_tracker!(flow, im1, im2)

@profile block_tracker!(flwtest, im1, im2) # JIT compiling
Profile.clear()
@profile block_tracker!(flwtest, im1, im2)


ProfileView.view()


blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),oldfeats,flow.features)
#

for frame_idx = 52:99

    im1 = deepcopy(im2)
    im2 = load(joinpath(datadir,"testSequence/image_$(frame_idx).jpg"))

    im2 = im2[range...]

    @time block_tracker!(flow, im1, im2)

    map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),flow.features, oldfeats)
    oldfeats = deepcopy(flow.features)

end


# overlay tracking traces with image
# o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,im2))
# b_img = reinterpret(Gray{N0f8},o_img)

o_img = (reinterpret(UInt8,blankImg)) .| (reinterpret(UInt8,im2))
r_img = reinterpret(Gray{N0f8},o_img)

n_img = ~(reinterpret(UInt8,blankImg)) .& (reinterpret(UInt8,im2))

n_img = reinterpret(Gray{N0f8},n_img)
#
# colorview(RGB, n_img, n_img, b_img)
# colorview(RGB, n_img, g_img, n_img)
colorview(RGB, r_img, n_img, n_img)
