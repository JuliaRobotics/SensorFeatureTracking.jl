# camera model

"""
Data structure for a Camera model with parameters.
Use `CameraModel(width,height,fc,cc,skew,kc)` for easy construction.
"""
struct CameraModelandParameters
    width::Int		# image width
    height::Int		# image height
    fc::Vector{Float64}	# focal length in x and y
    cc::Vector{Float64}	# camera center
    skew::Float64	    # skew value
    kc::Vector{Float64} # distortion coefficients up to fifth order
    K::Matrix{Float64} # 3x3 camera calibration matrix (Camera intrinsics)
    Ki::Matrix{Float64} # inverse of a 3x3 camera calibratio matrix
end

"""
    CameraModel(width,height,fc,cc,skew,kc)

Constructor helper for creating a camera model.
"""
function CameraModel(width,height,fc,cc,skew,kc)
    KK = [fc[1]      skew  cc[1];
             0       fc[2] cc[2];
             0		    0     1]
    # KK = [fc[1] skew*fc[1] cc[1];
    #          0       fc[2] cc[2];
    #          0		    0     1]
    Ki = inv(KK)
    CameraModelandParameters(width,height,fc,cc,skew,kc,KK,Ki)
end

# Sensor Model and Geometry
mutable struct PInt64
    i::Int64
end

"""
Data structure for holding time, gyroscope, and accelerometer data.

**Fields**
 - `utime` -- time [μs]
 - `acc`   -- accelerometer data
 - `gyro`  -- gyroscope data
"""
struct IMU_DATA
	utime::Int64
	acc::Vector{Float64}
	gyro::Vector{Float64}
	# mag::Vector{Float64}
    # IMU_DATA() = new()
end

"""
	propR!(R, gyro_sample, delta_time)

Propogate rotation matrix R with gyro data over time dt
"""
function propR!(R::Matrix{Float64}, gyro::Vector{Float64}, dt::Float64)
    # this integration can be done better
    #alpha = 0.5*(gyro + datt.dalpha)*dt
    alpha = gyro*dt
    phi = alpha
    dR = expm(skew(phi))
    R[:] = R * dR
	return nothing
end



"""
    HornAbsoluteOrientation(a::Matrix{Float64},b::Matrix{Float64})
    HornAbsoluteOrientation(a::Vector{Vector{Float64}},b::Vector{Vector{Float64}})

Compute the rotation between rows of (a and b)::Array{Float64,2}.\\
Rotate b into the frame of a\\
Returns a quaternion, aQb
"""
function HornAbsoluteOrientation(a::Matrix{Float64},b::Matrix{Float64})
  # rotate b into the frame of a

  N = zeros(4,4);

  for n = 1:size(a,1)
    li = [0;a[n,:]]
    ri = [0;b[n,:]]

    N = N + linmapR(ri)'*linmapL(li)
  end

  D,v = eig(N);
  d = diagm(D);
  # maxd = maximum(d);
  # maxind = find(maxd==d);
  maxd, maxind = findmax(D)

  q = v[:,maxind]
  if (q[1]<0)
    q = -q;
  end

  return Quaternion(q)
end


function HornAbsoluteOrientation(a::Vector{Vector{Float64}},b::Vector{Vector{Float64}})
  # rotate b into the frame of a

  N = zeros(4,4)
  valid_count = 0

  for n = 1:size(a,1)
    if isnan(a[n][1]) || isnan(b[n][1])
        continue
    end
    li = [0;a[n]]
    ri = [0;b[n]]

    N = N + linmapR(ri)'*linmapL(li)
    valid_count += 1;
  end

  if valid_count < 4
      error("Not enough vectors for a solution!")
      return Quaternion()
  end

  D,v = eig(N)
  d = diagm(D)
  # maxd = maximum(d);
  # maxind = find(maxd==d);
  maxd, maxind = findmax(D)

  q = v[:,maxind]
  if (q[1]<0)
    q = -q;
  end

  return Quaternion(q)
end

"""
    linmapL(p)
"""
function linmapL(p)
    p0 = p[1];
    px = p[2];
    py = p[3];
    pz = p[4];

    P = [p0  -px  -py -pz;
         px   p0  -pz  py;
         py   pz   p0 -px;
         pz  -py   px  p0]

    return P
end

"""
    linmapR(q)
"""
function linmapR(q)
  q0 = q[1];
  qx = q[2];
  qy = q[3];
  qz = q[4];

  Q = [q0  -qx  -qy  -qz;
       qx   q0   qz  -qy;
       qy  -qz   q0   qx;
       qz   qy  -qx   q0];

  return Q
end


"""
    integrateGyroBetweenFrames!(index, current_time, vector_data)

Estimate rotations from IMU data between time stamps.
"""
function integrateGyroBetweenFrames!(index::PInt64, ctime::Int64, imudata::Vector{IMU_DATA})

	R = eye(3)

	n = size(imudata,1)

	#end of imudata
	if (index.i > n)
 		return (false, eye(3))
	end

	#increment index to start at 2 for integration, ignore first
    (index.i < 2)? index.i+=1:nothing

	while (index.i <= n) && (imudata[index.i].utime <= ctime)

		dt = Float64(imudata[index.i].utime - imudata[index.i-1].utime)/1e6

		propR!(R, imudata[index.i].gyro, dt)

		# println("@$(index.i) : $(cR)")
		index.i += 1
	end

	return (true, R)

end


"""
	estimateRotationFromKeypoints(points_a, points_b, cameraModel, [compensate = false])

Estimate the rotation between 2 sets of Keypoints a and b using HornAbsoluteOrientation.\\
It is assumed that only possitive Keypoints are valid.\\
Set compensate to true if rotaion should be around centre off image rather than 0,0
"""
function estimateRotationFromKeypoints(points_a::Keypoints, points_b::Keypoints, cam::CameraModelandParameters; compensate = false)

	focald = cam.fc[1] #assume 1:1 aspect ratio for now TODO
	#create a Vector of 3d vectors for valid keypoints (ie. not 0) else NaN
	nps_a = map(kp -> (kp[1] > 0 < kp[2])? [kp[1], kp[2], focald] : [NaN,NaN,NaN], points_a)
	nps_b = map(kp -> (kp[1] > 0 < kp[2])? [kp[1], kp[2], focald] : [NaN,NaN,NaN], points_b)
    if compensate
        # compensate offset to centre of camera
        nps_a = map(nps -> nps - [cam.cc; 0.], nps_a)
        nps_b = map(nps -> nps - [cam.cc; 0.], nps_b)
    end
	#normalize vectors
	nps_a .= nps_a./norm.(nps_a)
	nps_b .= nps_b./norm.(nps_b)

	return HornAbsoluteOrientation(nps_a,nps_b)

end


"""
    predictHomographyIMU!(index, current_time, vector_data, CameraK, CameraK_inverse)

Estimate camera rotation from IMU data and compute predicted homography
"""
function predictHomographyIMU!(index::PInt64, ctime::Int64, imudata::Vector{IMU_DATA},K::Array{Float64,2},Ki::Array{Float64,2}; cRi::Array{Float64,2} = eye(3))

	R = eye(3)

	n = size(imudata,1)

	#end of imudata
	if (index.i >= n)
 		return (false, eye(3))
	end

	#increment index to start at 2 for integration, ignore first
    (index.i < 2)? index.i+=1:nothing

	while (index.i <= n) && (imudata[index.i].utime  <= ctime)

		dt = Float64(imudata[index.i].utime - imudata[index.i-1].utime)/1e6

		SensorFeatureTracking.propR!(R, cRi * imudata[index.i].gyro, dt)

		# println("@$(index.i) : $(cR)")
		index.i += 1
	end

	#compute homography
	# H = K*R*inv(K)
    R4 = eye(4)
    R4[1:3,1:3] = R
    K4 = eye(4)
    K4[1:2,1:2] = K[1:2,1:2]
    K4[1:2,4] = K[1:2,3]
    H = K4*R4*inv(K4)
# H./H[3,3] ??
    # H[:] ./= H[3,3]
	return (true, H);
end


function predictHomographyIMU(roll::Float64, pitch::Float64, yaw::Float64, K::Array{Float64,2}, Ki::Array{Float64,2})

    R = eye(4)
    R[1:3,1:3] = SO3(Euler(roll,pitch,yaw)).R

    K4 = eye(4)
    K4[1:2,1:2] = K[1:2,1:2]
    K4[1:2,4] = K[1:2,3]
    H = K4*R*inv(K4)
# H./H[3,3] ??
    return  K4*R*inv(K4)
end

function predictAffinity(H::Matrix{Float64})

    return AffineMap(SMatrix{2,2}(H[1:2,1:2]), SVector{2}(H[1:2,:]*[0,0,1,1]))

end
