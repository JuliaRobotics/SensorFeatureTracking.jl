
struct KLTFeature
    valid::Vector{Bool}
    affinity::AffineMap
    template::Array{Gray{N0f8}}
    xgrad::Array{Float32,2}
    ygrad::Array{Float32,2}
    #jacobian::Array{Float32,2}#TODO move out to KLTTracker since it only depends on width anb number of vars
    steepest::Array{Float32,2}
    invhessian::Array{Float32,2}
end

function KLTFeature(img, keypoint, w = 10)

	N_p = 6
	(ro,co) = size(img)

	#check if too close to edge
	if w < keypoint[1] < (ro - w) && w < keypoint[2] < (co - w)
		template = img[(-w:w) + keypoint[1],(-w:w) + keypoint[2]] #todo boundaries
		Txgrad, Tygrad = imgradients(template, KernelFactors.ando5)
		dW_dp = jacobian(w*2+1) #TODO move out to KLTTracker since it only depends on width anb number of vars
		VT_dW_dp = computesteepest(dW_dp, Txgrad, Tygrad, N_p, w*2+1)
		H = hessian(VT_dW_dp, N_p, w*2+1)
		H_inv = inv(H)

		return KLTFeature(	Vector([true]),
							AffineMap(MMatrix{2,2}(eye(2)), MVector{2,Float32}(keypoint.I)),
							template,
							Txgrad,
							Tygrad,
							# dW_dp,
							VT_dW_dp,
							H_inv)
	else
		return KLTFeature(	Vector([false]),
							AffineMap(MMatrix{2,2}(eye(2)), MVector{2,Float32}([0.,0])),
							zeros(w*2+1,w*2+1),
							zeros(w*2+1,w*2+1),
							zeros(w*2+1,w*2+1),
							# zeros(w*2+1,w*2+1),
							zeros(w*2+1,w*2+1),
							zeros(w*2+1,w*2+1))
	end


end

const KLTFeatures = Vector{KLTFeature}

struct KLTTracker
    image_heigth::Int
	image_width::Int
	window_size::Int
	threshold::Float32#Threshold = 0.05;
	jacobian::Array{Float32,2}
	features::KLTFeatures
	validCounts::Vector{Int}
end


KLTTracker(image::Matrix{T}, window_size::Int, threshold::Float32, kpoints::Array{CartesianIndex{2},1}) where T = KLTTracker(size(image,1),size(image,2), window_size, threshold, jacobian(window_size*2+1), map( kp -> KLTFeature(image, kp, window_size), kpoints), zeros(Int, size(kpoints)))

##

function (tracker::KLTTracker)(img) #template, p_init, n_iters)
	const N_p = 6
	const maxIterations = 50
	const rows = size(img, 1)
    const cols = size(img, 2)
	const windowSize = tracker.window_size
	const printDebug = true

	error_img = zeros(windowSize*2+1, windowSize*2+1)
	sd_delta_p = zeros(N_p, 1)

	invalidcounter = 0

	for f_inx = 1:size(tracker.features,1)

		feat = tracker.features[f_inx]

		i = feat.affinity.v[1]
		j = feat.affinity.v[2]
		valid = feat.valid[1]

		if valid && (i-windowSize > 0 && i+windowSize <= rows && j-windowSize > 0 && j+windowSize < cols)

			template = feat.template

			warp_p_am = feat.affinity
			# warp_p = hcat(eye(2), [feat.keypoint[1]; feat.keypoint[2]])

			twidth = size(template, 2)
			hwidth = div(twidth,2)


			# Pre-computed from struct ---------------------------------------------------
			# 3) gradients
			Tx_grad = feat.xgrad
			Ty_grad = feat.ygrad

			# 4) Jacobian
			dW_dp = tracker.jacobian

			# 5)steepest descent images, VT_dW_dp
			VT_dW_dp = feat.steepest

			# 6) Hessian  inverse
			H_inv = feat.invhessian

			IWxp = nothing
			# Baker-Matthews, Inverse Compositional Algorithm -------------------------
			for counter = 1:maxIterations
				# 1) Warp image
				# warp_p_am = AffineMap(SMatrix{2,2}(warp_p[1:2,1:2]), SVector{2}(warp_p[:,3]))

				if !(hwidth < warp_p_am.v[1] < (rows-hwidth))  || !(hwidth < warp_p_am.v[2] < (cols-hwidth)) || isnan(warp_p_am.v[1])
					printDebug && println("out of frame on feature: $f_inx ", warp_p_am)
					tracker.features[f_inx].valid[1] = false #trow away
					invalidcounter +=1
					tracker.validCounts[f_inx] = 0
					break;
				end

				try
					IWxp = view(warpedview(img, warp_p_am, 0.0),-hwidth:hwidth,-hwidth:hwidth)
				catch
					printDebug && println("out of frame after warp: $f_inx ", warp_p_am)
					tracker.features[f_inx].valid[1] = false #trow away
					invalidcounter +=1
					tracker.validCounts[f_inx] = 0
					break;
				end
				# IWxp = view(warpedview(img, warp_p_am), -hwidth:hwidth,-hwidth:hwidth)

				# 2) Compute the error image
				error_img .= IWxp .- template

				# 7) Compute steepest descent parameter updates
				steepestupdate!(sd_delta_p, VT_dW_dp, error_img, N_p, twidth)

				# 8) Compute gradient descent parameter updates
				delta_p = H_inv * sd_delta_p
				#not everything at once
				delta_p .*= 0.5

				# 9) Update warp parmaters
				# println("sd: ", sd_delta_p, ", warp: ", warp_p, ", delta: ", delta_p)
				# update_warp!(warp_p, delta_p);
				warp_p_am = update_warp(warp_p_am, delta_p)

				# convereged!
				if ( norm(delta_p[5:6]) < 0.05)
					#update featrure to new position
					# println("converged in $counter")# for feature: $f_inx")
					tracker.features[f_inx].affinity.m .= warp_p_am.m
					tracker.features[f_inx].affinity.v .= warp_p_am.v
					tracker.validCounts[f_inx] +=1
					break
				#Break if it is not
				elseif (counter >= maxIterations)
					printDebug && println("failed to converge on feature $f_inx") # Δp = $delta_p; norm(Δp) = $(norm(delta_p))")
					tracker.features[f_inx].valid[1] = false #trow away
					invalidcounter +=1
					tracker.validCounts[f_inx] = 0
					break;
				end
			end
		else
			printDebug && println("original feature to close to edge for $f_inx")
			invalidcounter +=1
			tracker.validCounts[f_inx] = 0
		end
	end
	return invalidcounter
end

###########################################################################

##
"""
Compute Jacobian for affine warp
"""
function jacobian(w)
#	TODO I shaped x and y as a test
	# jac_y = kron((0:w - 1)',ones(w, 1))
	# jac_x = kron((0:w - 1),ones(1, w))
#	TODO recenter x y as test NOTE w must be odd
	half = floor(Int, w/2)
	jac_x = kron((-half:half),ones(1, w))
	jac_y = kron((-half:half)',ones(w, 1))

	jac_zero = zeros(w, w)
	jac_one = ones(w, w)

	return dW_dp = [jac_x jac_zero jac_y jac_zero jac_one jac_zero;
					jac_zero jac_x jac_zero jac_y jac_zero jac_one]
end

##
"""
	jacobian2d(windowSize)
Compute Jacobian for 2d
"""
function jacobian2d(w)
	jac_zero = zeros(w, w)
	jac_one = ones(w, w)

	return dW_dp = [jac_one jac_zero;
					jac_zero jac_one]
end
###
"""
	computesteepest(dW_dp, Tx_grad, Ty_grad, N_p, w)
Compute steepest descent images
"""
function computesteepest(dW_dp, Tx_grad, Ty_grad, N_p, w)

	VI_dW_dp = zeros(w,w*N_p)
	for p=1:N_p
		Tx = Tx_grad .* dW_dp[1:w,((p-1)*w)+1:((p-1)*w)+w]
		Ty = Ty_grad .* dW_dp[w+1:end,((p-1)*w)+1:((p-1)*w)+w]
		VI_dW_dp[:,((p-1)*w)+1:((p-1)*w)+w] = Tx + Ty
	end
	return VI_dW_dp
end


##
"""
	hessian(VI_dW_dp, N_p, w)
Compute Hessian
"""
function hessian(VI_dW_dp, N_p, w)
# Compute Hessian

	H = zeros(N_p, N_p);
	for i=1:N_p
		h1 = VI_dW_dp[:,((i-1)*w)+1:((i-1)*w)+w];
		for j=1:N_p
			h2 = VI_dW_dp[:,((j-1)*w)+1:((j-1)*w)+w];
			# H[j, i] = sum(h1 .* h2);
			H[i, j] = sum(h1 .* h2); #NOTE swapped to see
		end
	end
	return H
end


##
"""
	steepestupdate(VI_dW_dp, error_img, N_p, w)
Steepest update
"""
function steepestupdate(VI_dW_dp, error_img, N_p, w)
# Compute steepest descent parameter updates
	sd_delta_p = zeros(N_p, 1);
	for p=1:N_p
		h1 = view(VI_dW_dp, :, ((p-1)*w)+1:((p-1)*w)+w)
		sd_delta_p[p] = sum(h1 .* error_img);
	end
	return sd_delta_p
end

"""
	steepestupdate!(sd_delta_p, VI_dW_dp, error_img, N_p, w)
Steepest update
"""
function steepestupdate!(sd_delta_p, VI_dW_dp, error_img, N_p, w)
	# Compute steepest descent parameter updates
	for p=1:N_p
		h1 = view(VI_dW_dp, :, ((p-1)*w)+1:((p-1)*w)+w)
		sd_delta_p[p] = sum(h1 .* error_img);
	end
	return nothing
end

##


function  update_warp(warp_p::AffineMap, delta_p)
	d_p = reshape(delta_p, 2, 3)
	d_p[1,1] += 1.
	d_p[2,2] += 1.
	delta_p_am = AffineMap(SMatrix{2,2}(d_p[1:2,1:2]), SVector{2}(d_p[:,3]))
	return warp_p ∘ inv(delta_p_am)
	# return warp_p ∘ (delta_p_am)
end



function  update_warp!(warp_p, delta_p)
	# Compute and apply the update
	# @show delta_p
	delta_p = reshape(delta_p, 2, 3)

	# Convert affine notation into usual Matrix form - NB transposed
	delta_M = [delta_p; 0 0 1]
	delta_M[1,1] = delta_M[1,1] + 1
	delta_M[2,2] = delta_M[2,2] + 1

	# Invert compositional warp
	delta_M = inv(delta_M)
	# delta_M = (delta_M)
	# Current warp
	warp_M = [warp_p; 0 0 1]
	warp_M[1,1] = warp_M[1,1] + 1
	warp_M[2,2] = warp_M[2,2] + 1

	# Compose
	comp_M = warp_M * delta_M
	warp_p[:] = comp_M[1:2,:]
	warp_p[1,1] = warp_p[1,1] - 1
	warp_p[2,2] = warp_p[2,2] - 1

	return nothing
end

##
function addBestShiTomasi!(img, tracker::KLTTracker; threshold = 1e-4)

	halfwindow = tracker.window_size
	windowSize = halfwindow * 2 + 1
	(ro,co) = size(img)

	shi_tomasi_response = zeros(img)
	blankmask = zeros(windowSize, windowSize)

	shi_tomasi_response[halfwindow:ro-halfwindow, halfwindow:co-halfwindow] .=
		shi_tomasi(view(img,halfwindow:ro-halfwindow, halfwindow:co-halfwindow))

	#find and blank all valid features
	validfeatures = find(map(ft -> ft.valid[1], tracker.features))
	for fidx = validfeatures
		i, j = round.(Int, tracker.features[fidx].affinity.v)
		shi_tomasi_response[i-halfwindow:i+halfwindow, j-halfwindow:j+halfwindow] .= blankmask[:,:]
	end

	# img = im2
	mth = maximum(shi_tomasi_response)

	keypoints = Keypoints(shi_tomasi_response .== mth)

	invalidfeatures = find(map(ft -> !ft.valid[1], tracker.features))

	tracker.features[invalidfeatures[1]] = KLTFeature(img, keypoints[1], halfwindow)
end
