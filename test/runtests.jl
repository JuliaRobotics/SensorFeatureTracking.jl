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

end
