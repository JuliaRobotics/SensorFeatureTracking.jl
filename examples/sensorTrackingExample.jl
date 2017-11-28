using TransformUtils
using SensorFeatureTracking
using CoordinateTransformations
using Images
using FixedPointNumbers
using Colors
using StaticArrays

cd(dirname(@__FILE__))

function warpKeypoint(keypoints::Keypoints, At::AffineMap)
	# convert CartesianIndex to SVector, applie affine map At to it and round and convert result back to CartesianIndex (keypoints)
	map(kp -> (kp[1] > 0 < kp[2])? CartesianIndex(round.(Int32,[At(SVector(kp[1],kp[2]))...])...) : CartesianIndex(0,0), keypoints )

# CartesianIndex(round.(Int32,b[1])...)
end

function invwarpKeypoint(keypoints::Keypoints, At::AffineMap)
	At = inv(At)
	# convert CartesianIndex to SVector, applie affine map At to it and round and convert result back to CartesianIndex (keypoints)
	map(kp -> (kp[1] > 0 < kp[2])? CartesianIndex(round.(Int32,[At(SVector(kp[1],kp[2]))...])...) : CartesianIndex(0,0), keypoints )

# CartesianIndex(round.(Int32,b[1])...)
end


function padandcutoffsetImg(img, ro, co)
	blankImg = zeros(Gray{N0f8},ro,co)

	ro_start =  max(indices(img)[1].start, 1)
	ro_stop  = 	min(indices(img)[1].stop, ro)

	co_start =  max(indices(img)[2].start, 1)
	co_stop  = 	min(indices(img)[2].stop, co)

	return blankImg[ro_start:ro_stop,co_start:co_stop] = img[ro_start:ro_stop,co_start:co_stop]

end

## Extract example data
# Extract example imu data
imudata = Vector{IMU_DATA}()

imu_data,imu_fields = readcsv("../Data/testSequence_IMU.csv",header=true)

for i = 1:size(imu_data,1)
	push!(imudata,IMU_DATA(Int64(imu_data[i,1]),imu_data[i,9:11],imu_data[i,3:5]))
end

# read image log file and get timestaps
timestamps = readcsv("../Data/testSequence_CAM.csv", Int64, skipstart=4)[:,2]
N = size(timestamps,1)

# constants setup
index = PInt64(1)

fx = 524.040
	fy = 524.040
	cy = 319.254
	cx = 251.227
	cam = CameraModel(640,480,[fx, fy],[cx, cy], 0., [0])
# this was calculated using HornAbsoluteOrientation, see hornEstimateTransformCam_IMU example
# iQc = Quaternion()
# 	iQc.s = 0.620782
# 	iQc.v = [-0.26786, 0.454148, 0.580198]
# 	iRc = convert(SO3,iQc).R
# 	cRi = iRc'

iQc = Quaternion()
	iQc.s = 0.6475888324459562
	iQc.v = [-0.261166, 0.533419, 0.477373]
	iRc = convert(SO3,iQc).R
	cRi = iRc'

# calculate delta affinities

predAffineMaps = Vector{AffineMap}(N)

for i = 1:N#length(timestamps)
	ctime = timestamps[i]
	(valid, H) = predictHomographyIMU!(index,ctime,imudata,cam.K,cam.Ki, cRi = cRi)
	At = predictAffinity(H)

	#add all predicted affinities to matrix
	predAffineMaps[i] = At
end

# spot check if images line up
i = 65
At = predAffineMaps[i]
im1 = load("../Data/testSequence/image_$(i-1).jpg")
im2 = load("../Data/testSequence/image_$(i).jpg")
range = 10:470,10:630#200:250,330:380
@show At
colorview(RGB, paddedviews(0,im2,warpedview(im1,At),zeroarray)...)


## Feature tracking compensated with the predicted affinity maps
imu_only = false
startFrame = 50
numFrames = 50
# joinpath(datadir,
im1 = load("../Data/testSequence/image_$(startFrame).jpg")
im2 = load("../Data/testSequence/image_$(startFrame+1).jpg")

(ro,co) = size(im1)
feats = getApproxBestShiTomasi(im1,nfeatures=200, stepguess=0.95)

flow = BlockTracker(feats, search_size = 5, matchFunction = compute_ssd)
# grid_features!(flow,co,ro)

image1 = deepcopy(im1)
oldfeats = deepcopy(flow.features)

# warp keypoints and image
flow.features[:] = invwarpKeypoint(flow.features, predAffineMaps[startFrame+1])
im1_w = warp(im1, predAffineMaps[startFrame+1])

!imu_only && @time block_tracker!(flow, padandcutoffsetImg(im1_w, ro, co), im2)

blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),oldfeats,flow.features)

colorview(RGB, paddedviews(0,im2,(im1_w),blankImg)...)

#
tic()
for frame_idx = startFrame+2:startFrame+numFrames -1
    println("Processing Frame: ", frame_idx)
    im1 = deepcopy(im2)
    im2 = load("../Data/testSequence/image_$(frame_idx).jpg")

	oldfeats = deepcopy(flow.features)
	# warp keypoints and image
	flow.features[:] = invwarpKeypoint(flow.features, predAffineMaps[frame_idx])
	im1_w = warp(im1, predAffineMaps[frame_idx])

	!imu_only && block_tracker!(flow, padandcutoffsetImg(im1_w, ro, co), im2)

    map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),flow.features, oldfeats)

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


##
