using Images, ImageView, ImageDraw, ImageFeatures, TestImages
using SensorFeatureTracking
using StaticArrays, CoordinateTransformations
using Video4Linux

cd(dirname(@__FILE__))

include("../src/KLTTracker.jl")
datadir = "../Data"

## #################################################################################################
# functions

function tracklive(im1, tracker, vidchan)

    im1[:] = Gray{Float32}.(take!(vidchan)/255)

    numlost = tracker(im1)
    if numlost > 0
        println("Replacing Lost Feature")
        addBestShiTomasi!(im1, tracker)
    end

    foreach(ft -> ft.valid[1] && drawfeatureX!(im1, CartesianIndex(round.(Int,ft.affinity.v[1:2])...), length=3), tracker.features)

    imshow(canvas["gui"]["canvas"], im1)

end


## ##################################################################################################
#run klt on live feed
# producer(c::Channel) = vidproducer(c)
yonly = Y422(640,480)
# create a videoproducer type channel (will only run 100 frames)
vidchan = Channel((c::Channel) -> videoproducer(c, yonly, N = 100))

##
#capture one frame to create im1 and canvas needed to diplay
im1 = Gray{Float32}.(take!(vidchan)/255)
canvas = imshow(im1)


##
im1 = Gray{Float32}.(take!(vidchan)/255)
(ro,co) = size(im1)
kpoints = getApproxBestShiTomasi(im1,nfeatures=20, stepguess=0.95)


tracker  = KLTTracker(im1, 20, Float32(0.05), kpoints )

foreach(ft->drawfeatureX!(im1, CartesianIndex(round.(Int,ft.affinity.v[1:2])...), length=3), tracker.features)
im1

# run untul channel is closed
while isopen(vidchan)
    @time tracklive(im1, tracker, vidchan)
end
