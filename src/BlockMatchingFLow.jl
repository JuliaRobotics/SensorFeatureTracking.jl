using ImageFeatures

type BlockTracker
	image_width::Int64
	search_size::Int64
	flow_feature_threshold::Int64
	flow_value_threshold::Int64
	features::Keypoints
	matchFunction::Function
	BlockTracker() = new()
	BlockTracker(image_width,search_size,flow_feature_threshold,flow_value_threshold,keypoints,matchFunction) = new(image_width,search_size,flow_feature_threshold,flow_value_threshold,keypoints,matchFunction)
end

##

function compute_diff(image, offX, offY, row_size)

	im_roi = image[offX:offX+3,offY:offY+3]
	acc = sum(abs.(diff(im_roi,1))) + sum(abs.(diff(im_roi,2)))

	return acc;

end

"""
    compute_sad_8x8(image1, image2, off1X, off1Y, off2X, off2Y)

  Compute Sum of Absolute Differences of two 8x8 pixel windows.

"""
function compute_sad_8x8(image1, image2, off1X, off1Y, off2X, off2Y)

	im1_r = image1[off1X:off1X+7,off1Y:off1Y+7]
	im2_r = image2[off2X:off2X+7,off2Y:off2Y+7]

	acc = sum(abs.(im1_r - im2_r))

	return acc;
end

"""
    compute_ssd_8x8(image1, image2, off1X, off1Y, off2X, off2Y)

  Compute Sum of Squared Differences of two 8x8 pixel windows.

"""
function compute_ssd_8x8(image1, image2, off1X, off1Y, off2X, off2Y)

	im1_r = image1[off1X:off1X+7,off1Y:off1Y+7]
	im2_r = image2[off2X:off2X+7,off2Y:off2Y+7]

	acc = sum((im1_r - im2_r).^2)

	return acc;
end

"""
    block_tracker(tracker::BlockTracker, image1, image2)

  Track features between two images.

"""
function block_tracker(tracker::BlockTracker, image1, image2)
	TILE_SIZE =	8 # x & y tile size
	#constants
	winmin = -tracker.search_size
	winmax = tracker.search_size

	# hist_size = 2 * (winmax - winmin + 1) + 1

	#variables
	pixLo = tracker.search_size + 1
	pixHi = tracker.image_width - (tracker.search_size + 1) - TILE_SIZE

	# return if no features exists
	if (size(tracker.features[:],1) == 0)
		println("no features!")
		return 0
	end

	meanflowx = 0.0
	meanflowy = 0.0
	meancount = 0

	for f_inx = 1:size(tracker.features,1)

		i = tracker.features[f_inx][1]
		j = tracker.features[f_inx][2]

		#check if feautes is to close to edge
		if !((pixLo < i < pixHi) && (pixLo < j < pixHi))
			#(trow away by making 0)???
			tracker.features[f_inx] = CartesianIndex(0,0)
			continue;
		end

		#test if pixel is ok for tracking
		if (compute_diff(image1, i, j, tracker.image_width) < tracker.flow_feature_threshold)
			tracker.features[f_inx] = CartesianIndex(0,0)
			continue;
		end

		dist = tracker.flow_value_threshold*10000  # set initial distance to "infinity"
		sumx = 0
		sumy = 0

		for jj = winmin:winmax
			for ii = winmin:winmax
				temp_dist = tracker.matchFunction(image1, image2, i, j, i + ii, j + jj)

				if (temp_dist < dist)
					sumx = ii;
					sumy = jj;
					dist = temp_dist;
				end
			end
		end

		#= acceptance SAD distance threshhold =#
		if (dist < tracker.flow_value_threshold)
			meanflowx += sumx;
			meanflowy += sumy;
			meancount+=1

			#update feature positions
			tracker.features[f_inx] += CartesianIndex(sumx,sumy)
		else
			# (trow away by making 0)?????
			tracker.features[f_inx] = CartesianIndex(0,0)
		end
	end

	#return number of features under threshold
	return meancount
end

function draw_dots(features::Keypoints,image)
    for f_idx = 1:size(features,1)
        if features[f_idx][1] > 0
            image[features[f_idx][1],features[f_idx][2]] = 0
        end
    end
    return reinterpret(Gray{N0f8},image)
end

# function grid_features(flow::SADTracker)
# 	NUM_BLOCKS = 15 # x & y number of tiles to check
#     winmin = -tracker.search_size
#     winmax = tracker.search_size
#     pixLo = tracker.search_size + 1
#     pixHi = tracker.image_width - (tracker.search_size + 1) - TILE_SIZE
#     pixStep = floor(Integer,(pixHi - pixLo) / NUM_BLOCKS + 1)
#
#     # create all features if none exists
#     if (size(tracker.features[:],1) == 0)
#         # must be a better way??
#         for j = pixLo:pixStep:pixHi
#             for i = pixLo:pixStep:pixHi
#                 push!(tracker.features, CartesianIndex.(i,j))
#             end
#         end
#     end
# end
