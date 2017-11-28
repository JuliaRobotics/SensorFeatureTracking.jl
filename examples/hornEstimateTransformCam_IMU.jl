## Script to estimate the rotational transform between camera and IMU

using SensorFeatureTracking, TransformUtils, FixedPointNumbers, Colors, Plots
using ProfileView

projdir = joinpath(dirname(@__FILE__), "..")
# srcdir = joinpath(projdir,"src")
datadir = joinpath(projdir,"Data")

## Extract example data
# Extract example imu data
cd(dirname(@__FILE__))

imudata = Vector{IMU_DATA}()

imu_data,imu_fields = readcsv("../Data/testSequence_IMU.csv",header=true)

for i = 1:size(imu_data,1)
	push!(imudata,IMU_DATA(Int64(imu_data[i,1]),imu_data[i,9:11],imu_data[i,3:5]))
end

# read image log file and get timestaps
timestamps = readcsv("../Data/testSequence_CAM.csv", Int64, skipstart=4)[:,2]
N = size(timestamps,1)

## Set up camera model
focald = 524.040
cu = 319.254
cv = 251.227
cam = CameraModel(640,480,[focald, focald],[cv, cu], 0., [0])

##
# go through frames and calculate delta rotations and save as Quaternion
index = PInt64(1)
ΔQ_s = Vector{Quaternion}(N)
trackAX = Vector{Vector{Float64}}(N)
gyroAX = Vector{Vector{Float64}}(N)

for i = 1:(N)#length(timestamps)
	(valid, R) = integrateGyroBetweenFrames!(index,timestamps[i],imudata)
	ΔQ_s[i] = convert(Quaternion,SO3(R))

	gyroAX[i]  = ΔQ_s[i].v ./ norm(ΔQ_s[i].v)
	trackAX[i] = [NaN, NaN, NaN]
end

## Track features and save delta rotations between frames, Block trakcer for now
startFrame = 50
numFrames = 50

im1 = load(joinpath(datadir,"testSequence/image_$(startFrame).jpg"))
im2 = load(joinpath(datadir,"testSequence/image_$(startFrame+1).jpg"))

(ro,co) = size(im1)
feats = getApproxBestShiTomasi(im1,nfeatures=100, stepguess=0.95)

flow = BlockTracker(feats, matchFunction = compute_ssd)#flow_value_threshold = 50000

image1 = deepcopy(im1)
oldfeats = deepcopy(flow.features)

block_tracker!(flow, im1, im2)


# blank image for feature overlay
blankImg = zeros(Gray{N0f8},ro,co)
map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),oldfeats,flow.features)

# there must be at least 4 valid keypoints to track
q = estimateRotationFromKeypoints(oldfeats,flow.features, cam)


trackAX[startFrame+1] = q.v./norm(q.v)

#
for frame_idx = startFrame+2:startFrame+numFrames -1
    println("Processing Frame: ", frame_idx)
    im1 = deepcopy(im2)
    im2 = load(joinpath(datadir,"testSequence/image_$(frame_idx).jpg"))

    # im2 = im2[range...]
    block_tracker!(flow, im1, im2)

    map((ft1,ft2)->drawfeatureLine!(blankImg, Feature(ft1),Feature(ft2)),flow.features, oldfeats)

	q = estimateRotationFromKeypoints(oldfeats,flow.features, cam)
	trackAX[frame_idx] = q.v./norm(q.v)

    oldfeats = deepcopy(flow.features)
end


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


## finally compute angle between camera frame and imu frame using HornAbsoluteOrientation

# Compute best fit alignment between all these vectors
oQc = HornAbsoluteOrientation(gyroAX, trackAX)


## Rotate trackAX into alignment with IMU Axis to test
# TODO: does not seem to be working
# iQc = Quaternion()
# 	iQc.s = 0.697815224446998;
# 	iQc.v = [0.715977169639074, 0.014522897934957, 0.014821960773685]

trackAX_b = TransformUtils.rotate.(oQc, trackAX)

# repack in matrix for plotting TODO: I'm sure Vectors can somehow be plotted?
trackAX_b_m = zeros(N,3)
gyroAX_m = zeros(N,3)
trackAX_m = zeros(N,3)
for i = 1:N
	trackAX_b_m[i,:] = trackAX_b[i]
	gyroAX_m[i,:] = gyroAX[i]
	trackAX_m[i,:] = trackAX[i]
end
##
p1 = plot(gyroAX_m[startFrame:startFrame+numFrames,:] - trackAX_b_m[startFrame:startFrame+numFrames,:])
##
# p2 = plot(trackAX_b_m[startFrame:startFrame+numFrames,:])
##
p2 = plot(gyroAX_m[startFrame:startFrame+numFrames,:] - trackAX_m[startFrame:startFrame+numFrames,:])
##
plot(p1,p2,layout=(2,1))
