
struct CameraModelandParameters
    width::Integer		# image width
    height::Integer		# image height
    fc::Vector{Float64}	# focal length in x and y
    cc::Vector{Float64}	# camera center
    skew::Float64	    # skew value
    kc::Vector{Float64} # distortion coefficients up to fifth order
    K::Matrix{Float64} # 3x3 camera calibration matrix (Camera intrinsics)
    Ki::Matrix{Float64} # inverse of a 3x3 camera calibratio matrix
end

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
    HornAbsoluteOrientation(⊽a, ⊽b)

Compute the rotation between array of row vectors (a and b).
Rotate b into the frame of a
Returns a quaternion, aQb?
"""
function HornAbsoluteOrientation(a::Matrix{Float64},b::Matrix{Float64})
  # rotate b into the frame of a

  N = zeros(4,4);

  for n = 1:size(a,1);
    li = [0;a[n,:]];
    ri = [0;b[n,:]];

    N = N + linmapR(ri)'*linmapL(li);
  end

  D,v = eig(N);
  d = diagm(D);
  # maxd = maximum(d);
  # maxind = find(maxd==d);
  maxd, maxind = findmax(d)

  q = v[:,div(maxind,4)]
  if (q[1]<0)
    q = -q;
  end

  return Quaternion(q), v, d
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
