
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

"""
    drawfeatureX!(image,feature [,crosslength = 2])

Draw a + on a feature.

# Examples
```julia-repl
julia> map(ft->drawfeatureX!(image, ft, length=5),features)
```
"""
function drawfeatureX!(im, pt::Keypoint; length = 2)
    h,w = size(im)
    boundr = 2
    checkboun = (length < pt[2] < w-length) && (length < pt[1] < h-length)
    # rad = T ? radius : 0
    if checkboun
      draw!(im, LineSegment( pt- CartesianIndex(0,length), pt + CartesianIndex(0,length)))
      draw!(im, LineSegment( pt- CartesianIndex(length,0), pt + CartesianIndex(length,0)))
    end
end

drawfeatureX!(im, ift::Feature; length = 2) = drawfeatureX!(im, Keypoint(ift), length = length)


"""
    drawfeatureLine!(image,feature1, feature2)

Draw a line between 2 features.
"""
function drawfeatureLine!(im, ift1::Feature, ift2::Feature)
    h,w = size(im)
    pt1 = Keypoint(ift1)
    pt2 = Keypoint(ift2)

    checkboun = (0 < pt1[2] <= w) && (0 < pt1[1] <= h) && (0 < pt2[2] <= w) && (0 < pt2[1] <= h)
    # rad = T ? radius : 0
    if checkboun
      draw!(im, LineSegment( pt1, pt2 ))
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

"""
    getApproxBestHarrisInWindow(image,[n=100, windowSize = 9, k=0.04, stepguess=0.4])

Return the n best Harris features in a window
"""
function getApproxBestHarrisInWindow(iml;nfeatures=100, window = 9, k=0.04, stepguess=0.9,threshold = 0.0)
    harris_response = harris(iml)

    maxima = mapwindow(maximum,harris_response,(window,window))
    window_max = (harris_response .== maxima).*harris_response

    mth = maximum(window_max)

    nfea = 0
    targnfea = nfeatures
    ftsl = nothing
    while nfea < targnfea
        mth *= stepguess
        resp = map(i -> i > mth, window_max);
        ftsl = Features(resp)
        nfea = length(ftsl)
        if mth < threshold break end
    end
    return ftsl[1: min(nfeatures, nfea)]
end

"""
    getApproxBestShiTomasi(image,[n=100, windowSize = 9, k=0.04, stepguess=0.4, threshold = 1e-4])

Return the n aproxamate best Shi Tomasi features in a window
"""
function getApproxBestShiTomasi(iml; nfeatures=100, window = 9, k=0.04, stepguess=0.7, threshold = 1e-4)
    shi_tomasi_response = shi_tomasi(iml)

    # maxima = mapwindow(maximum,shi_tomasi_response,(window,window))
    #the mapwindow extrema function is faster, but returns a tuple, the map slows it down again
    maxima = map(tu -> tu[2], mapwindow(extrema,shi_tomasi_response,(window,window)))

    shi_tomasi_response .*= (shi_tomasi_response .== maxima)# .& (shi_tomasi_response .> threshold)

    mth = maximum(shi_tomasi_response)

    nfea = 0
    targnfea = nfeatures
    ftsl = nothing
    resp = zeros(Bool,size(iml))
    while nfea < targnfea
        mth *= stepguess
        resp .= shi_tomasi_response .> mth  #map(i -> i > mth, shi_tomasi_response);
        # ftsl = Keypoints(resp)
        nfea = length(find(resp))
        if nfea >= targnfea
            # ftsl = Keypoints(resp)
            return Keypoints(resp)[1:nfeatures]
            break
        end
        if mth < threshold
            # ftsl = Keypoints(resp)
            return Keypoints(resp)[1:nfea]
            break
        end
    end
    # return ftsl[1: min(nfeatures, nfea)]
end
