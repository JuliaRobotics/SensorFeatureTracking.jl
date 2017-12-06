using Images, ImageView, ImageDraw, ImageFeatures, TestImages
using SensorFeatureTracking
using StaticArrays, CoordinateTransformations
using Video4Linux

cd(dirname(@__FILE__))

include("../src/KLTTracker.jl")
datadir = "../Data"

## #################################################################################################
# functions
function producer(c::Channel)

    N = 100
    ##
    set_io_method(Video4Linux.IO_METHOD_READ)

    ## open device
    fid = open_device("/dev/video0")

    ## init_device(fd, force_format);
    init_device(fid)

    ## start_capturing(fd);
    start_capturing(fid)


    imy = zeros(UInt8,480,640)
    for i = 1:N
        mainloop( fid, 1 )
        ## copy_buffer_bytes, copy the image buffer bytes to uint8 vector, the lenght will depend on the pixel format
        imbuff = copy_buffer_bytes(640*480*2)
        imy[:,:] =  reshape(imbuff[2:2:end],(640,480))'
        put!(c, imy)
    end

    ## stop_capturing(fd);
    stop_capturing(fid)

    ## uninit_device();
    uninit_device(fid)

    ## close device
    close_device(fid)
end


#
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
vidchan = Channel(producer)

##

im1 = Gray{Float32}.(take!(vidchan)/255)
canvas = imshow(im1)

##
im1 = Gray{Float32}.(take!(vidchan)/255)
(ro,co) = size(im1)
kpoints = getApproxBestShiTomasi(im1,nfeatures=50, stepguess=0.95)



tracker  = KLTTracker(im1, 20, Float32(0.05), kpoints )

foreach(ft->drawfeatureX!(im1, CartesianIndex(round.(Int,ft.affinity.v[1:2])...), length=3), tracker.features)
im1

# wil break when channel is closed
while isopen(vidchan)
    @time tracklive(im1, tracker, vidchan)

end



##
