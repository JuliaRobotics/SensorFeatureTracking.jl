using SensorFeatureTracking
using Base: Test

@testset "blockMatchingFlow" begin
##
	im1 = zeros(Int32,41,61)
	im1[16:26,16:26] = 100
	im1[16:26,36:46] = 200


	reffeats = map(CartesianIndex{2}, [(16, 36), (26, 36), (16, 46), (26, 46)])

	im2 = zeros(Int32,41,61)
	im2[14:24,14:24] = 70
	im2[18:28,38:48] = 200

	feats = getApproxBestShiTomasi(im1,nfeatures=4, stepguess=0.8)
	@test feats == reffeats

	feats = getApproxBestShiTomasi(im1,nfeatures=8, stepguess=0.8)
	reffeats_im2 = map(CartesianIndex{2},[(14, 14),(24, 14),(14, 24),(24, 24),(18, 38),(28, 38),(18, 48),(28, 48)])

	trackerssd = BlockTracker(deepcopy(feats), search_size = 6)
	block_tracker!(trackerssd, im1, im2)
	@test reffeats_im2 == trackerssd.features

	trackersad = BlockTracker(deepcopy(feats), search_size = 6, matchFunction = compute_sad)
	block_tracker!(trackersad, im1, im2)
	@test reffeats_im2 == trackersad.features

	trackerncc = BlockTracker(deepcopy(feats), search_size = 6, matchFunction = compute_ncc)
	block_tracker!(trackerncc, im1, im2)
	@test reffeats_im2 == trackersad.features
##
end


##
