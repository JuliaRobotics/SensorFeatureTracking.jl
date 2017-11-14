using SensorFeatureTracking
using TransformUtils
using Base: Test


@testset begin
  TU = TransformUtils

  aQb = convert(Quaternion, so3(randn(3)))

  bX = randn(10,3)
  aX = zeros(size(bX))

  for i in 1:size(bX,1)
    aX[i,:] = TU.rotate(aQb, bX[i,:])
  end

  est_aQb = HornAbsoluteOrientation(aX, bX)

  @test compare(est_aQb, aQb)


  # Test integrateGyroBetweenFrames!
  index = PInt64(1)
  imudata = Vector{IMU_DATA}()

  push!(imudata, IMU_DATA(Int64(0),[0.0, 0.0, 0.0],[0.0, 0.0, 0.0]))
  for time = 10000:10000:100000
    push!(imudata, IMU_DATA(time,[0.0, 0.0, 0.0],[-0.1, 0.1, 0.2]))
  end
  (valid, R) = integrateGyroBetweenFrames!(index,100000,imudata)
  # TODO: check that this accually is correct
  Rref =  [0.99975   -0.02        0.01;
           0.02       0.99975     0.01;
          -0.01      -0.01        0.9999]

  @test R ≈ Rref atol=0.001



  # Test estimateRotationFromKeypoints
  focald = 520.0
  cu = 320.0
  cv = 240.0
  cam = CameraModel(640,480,[focald, focald],[cv, cu], 0., [0])

  points_a = Keypoints()
  # push!(points_a, CartesianIndex(319,239), CartesianIndex(321,239), CartesianIndex(321,241),  CartesianIndex(319,241))
  push!(points_a, CartesianIndex(239,319), CartesianIndex(239,321), CartesianIndex(241,321),  CartesianIndex(241,319))
  points_b = Keypoints()
  push!(points_b, CartesianIndex(239,321), CartesianIndex(241,321),  CartesianIndex(241,319), CartesianIndex(239,319))
  # there must be at least 4 valid keypoints to track
  q = estimateRotationFromKeypoints(points_a,points_b, cam, compensate = true)
  qref = convert(Quaternion, Euler(0.,0.,pi/2.))
  @test compare(q, qref, tol = 1e-4)

end
