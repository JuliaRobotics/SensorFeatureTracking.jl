# harris corner feature example from webcam or movie

using Images, ImageView, ImageDraw, ImageFeatures, Gtk.ShortNames, VideoIO


@show projdir = joinpath(dirname(@__FILE__), "..")
srcdir = joinpath(projdir,"src")
include(joinpath(srcdir, "SensorFeatureTracking.jl"))
include(joinpath(srcdir, "Common.jl"))





function fromvideohandle(fhl ;iters=50, param1=0.15, param2=0.35)
    grid, frames, canvases = canvasgrid((1,2))  # 1 row, 2 columns

    img = read(fhl)

    imshow(canvases[1,1], img)
    imshow(canvases[1,2], img)

    win = Window(grid)
    showall(win)


    for i in 1:iters
        read!(fhl, img)

        # imshow(canvases[1,1], img)
        imgg = Gray.(img)
        # corners = fastcorners(imgg, param1, param2)
        # fts1 = Features(corners)
        ## corners = getharriscorners(imgg)
        fts1 = getapproxbestharris(imgg, 200)

        # draw the results
        for ft in fts1
            drawfeaturecircle2d!(imgg, ft, radius=5)
        end
        imshow(canvases[1,2], imgg)
        sleep(0.001)
    end


    nothing
end




# f = VideoIO.testvideo("annie_oakley") # this doesn't directly work for reading images in current version

f = VideoIO.opencamera() #webcam
fromvideohandle(f)
close(f)



#
