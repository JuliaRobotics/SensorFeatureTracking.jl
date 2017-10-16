
function topoint2d(ift::ImageFeatures.Feature)
    return Point(ift.keypoint.I[2],ift.keypoint.I[1])
end

function drawfeaturecircle2d!(im, ift::Feature; radius=5, boundary=6)
    h,w = size(im)
    pt = topoint2d(ift)
    boundr = radius < boundary ? boundary : radius
    checkboun = (0 <= pt.x-radius-boundr && pt.x+radius+boundr <= w && 0 < pt.y-radius-boundr && pt.y+radius+boundr <= h)
    # rad = T ? radius : 0
    if checkboun
      draw!(im, CirclePointRadius(pt,radius))
    end
end

function getharriscorners(iml;fracmax=0.5, k=0.04)
  harris_response = harris(iml,k=k)
  mth = fracmax*Base.maximum(harris_response)
  map(i -> i > mth, harris_response);
end
# using BenchmarkTools
# @btime mth = 0.9*maximum(harris_response)
# @btime mth = 100*Base.median(harris_response)

function getapproxbestharris(iml,nfeatures=100;k=0.04, stepguess=0.4)
    harris_response = harris(iml, k=k);
    # mth = 100*Base.mean(harris_response)
    mth = maximum(harris_response)
    # mnth = minimum(harris_response)
    # get top 100 features
    nfea = 0
    targnfea = nfeatures
    ftsl = nothing
    while nfea < targnfea
        mth *= stepguess
        resp = map(i -> i > mth, harris_response);
        ftsl = Features(resp)
        nfea = length(ftsl)
    end
    return ftsl
end
