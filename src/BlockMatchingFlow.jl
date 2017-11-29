# using ImageFeatures, Images
struct BlockTracker
	search_size::Int
	flow_feature_threshold::Int
	flow_value_threshold::Int
	features::Keypoints
	"Function used for block matching (compute_sad, compute_ssd, compute_ncc)"
	matchFunction::Function
	REGION_SIZE::Int # this is used as a constant for implimentation of BlockTracker and should not be changed
	BlockTracker() = new()
	BlockTracker(search_size,flow_feature_threshold,flow_value_threshold,keypoints,matchFunction,REGION_SIZE) = new(search_size,flow_feature_threshold,flow_value_threshold,keypoints,matchFunction,REGION_SIZE)
end
BlockTracker(keypoints::Keypoints; search_size = 10, flow_feature_threshold = 1000, flow_value_threshold = 50000, matchFunction = compute_ssd,REGION_SIZE = 10) = BlockTracker(search_size,flow_feature_threshold,flow_value_threshold,keypoints,matchFunction,REGION_SIZE)

##

function compute_diff(image, offX::T, offY::T, REGION_SIZE::T) where {T<:Integer}

	im_roi = image[offX:offX+REGION_SIZE-1,offY:offY+REGION_SIZE-1]
	acc = sum(abs.(diff(im_roi,1))) + sum(abs.(diff(im_roi,2)))

	return acc;

end

"""
    compute_sad(image1, image2, off1X, off1Y, off2X, off2Y, REGION_SIZE)

  Compute Sum of Absolute Differences of two regions with size REGION_SIZE.

"""
function compute_sad(image1, image2, off1X::T, off1Y::T, off2X::T, off2Y::T, REGION_SIZE::T) where {T<:Integer}

	im1_r = view(image1,off1X:off1X+REGION_SIZE-1,off1Y:off1Y+REGION_SIZE-1)
	im2_r = view(image2,off2X:off2X+REGION_SIZE-1,off2Y:off2Y+REGION_SIZE-1)

	acc = sum(abs.(im1_r .- im2_r))

	return acc;
end

"""
    compute_ssd(image1, image2, off1X, off1Y, off2X, off2Y, REGION_SIZE)

  Compute Sum of Squared Differences of two regions with REGION_SIZE.

"""
function compute_ssd(image1, image2, off1X::T, off1Y::T, off2X::T, off2Y::T, REGION_SIZE::T) where {T<:Integer}

	im1_r = view(image1,off1X:off1X+REGION_SIZE-1,off1Y:off1Y+REGION_SIZE-1)
	im2_r = view(image2,off2X:off2X+REGION_SIZE-1,off2Y:off2Y+REGION_SIZE-1)

	acc = sum((im1_r .- im2_r).^2)

	return acc;
end

"""
    compute_ncc(image1, image2, off1X, off1Y, off2X, off2Y, REGION_SIZE)

  Compute the normalized cross-correlation of two regions with size REGION_SIZE.

"""
function compute_ncc(image1, image2, off1X::T, off1Y::T, off2X::T, off2Y::T, REGION_SIZE::T) where {T<:Integer}

	im1_r = Float32.(image1[off1X:off1X+REGION_SIZE-1,off1Y:off1Y+REGION_SIZE-1])
	im2_r = Float32.(image2[off2X:off2X+REGION_SIZE-1,off2Y:off2Y+REGION_SIZE-1])

	acc = (1 - ncc(im1_r,im2_r))

	return acc;
end

"""
    block_tracker(tracker::BlockTracker, image1, image2)

  Track features between two images.

"""
function block_tracker!(tracker::BlockTracker, image1::Array{Int32}, image2::Array{Int32})
	REGION_SIZE = tracker.REGION_SIZE # x & y tile size
	#constants
	ro,co = size(image1)
	winmin = -tracker.search_size
	winmax = tracker.search_size

	# hist_size = 2 * (winmax - winmin + 1) + 1

	#variables
	pixLo = tracker.search_size + 1
	pixHiro = ro - (tracker.search_size + 1) - REGION_SIZE
	pixHico = co - (tracker.search_size + 1) - REGION_SIZE

	# return if no features exists
	if (size(tracker.features[:],1) == 0)
		println("no features!")
		return 0
	end

	meanflowx = 0.0
	meanflowy = 0.0
	meancount = 0

	for f_inx = 1:size(tracker.features,1)

		#indexes of upper left corner
		i = tracker.features[f_inx][1] - div(REGION_SIZE,2)
		j = tracker.features[f_inx][2] - div(REGION_SIZE,2)

		#check if feautes is to close to edge
		if !((pixLo < i < pixHiro) && (pixLo < j < pixHico))
			#(trow away by making 0)???
			tracker.features[f_inx] = CartesianIndex(0,0)
			continue;
		end

		#test if pixel is ok for tracking
		if (compute_diff(image1, i, j, REGION_SIZE) < tracker.flow_feature_threshold)
			tracker.features[f_inx] = CartesianIndex(0,0)
			continue;
		end

		dist = tracker.flow_value_threshold*10000  # set initial distance to "infinity"
		sumx = 0
		sumy = 0

		for jj = winmin:winmax
			for ii = winmin:winmax
				temp_dist = tracker.matchFunction(image1, image2, i, j, i + ii, j + jj, REGION_SIZE)

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

function block_tracker!(tracker::BlockTracker, image1::Matrix{Gray{N0f8}}, image2::Matrix{Gray{N0f8}})
	return block_tracker!(tracker, Int32.(reinterpret(UInt8,image1)), Int32.(reinterpret(UInt8,image2)))
end


function grid_features!(tracker::BlockTracker, image_width, image_height; NUM_BLOCKS = 10)

	regionOffset = div(tracker.REGION_SIZE,2)
    pixLo = tracker.search_size + 1
    pixHiro = image_height - (tracker.search_size + 1) - tracker.REGION_SIZE
	pixHico = image_width  - (tracker.search_size + 1) - tracker.REGION_SIZE
    pixStep = div((min(pixHiro,pixHico) - pixLo), NUM_BLOCKS + 1)

    # add block features to existing
    # must be a better way??
    for i = pixLo:pixStep:pixHiro
        for j = pixLo:pixStep:pixHico
            push!(tracker.features, CartesianIndex.(i+regionOffset,j+regionOffset))
        end
    end

end
