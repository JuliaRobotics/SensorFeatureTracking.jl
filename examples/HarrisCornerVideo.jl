# harris corner feature example from webcam or movie

using Images, ImageView, ImageDraw, ImageFeatures, Gtk.ShortNames, VideoIO


@show projdir = joinpath(dirname(@__FILE__), "..")
srcdir = joinpath(projdir,"src")
include(srcdir, "SensorFeatureTracking.jl")
include(srcdir, "Common.jl")





function fromvideohandle(fhl ;iters=100, param1=0.15, param2=0.35)
    grid, frames, canvases = canvasgrid((1,2))  # 1 row, 2 columns

    img = read(fhl)

    imshow(canvases[1,1], img)
    imshow(canvases[1,2], img)

    win = Window(grid)
    showall(win)


    f = VideoIO.opencamera()

    for i in 1:iters
        read!(fhl, img)

        # imshow(canvases[1,1], img)
        imgg = Gray.(img)
        # corners = fastcorners(imgg, param1, param2)
        corners = getharriscorners(imgg)
        # corners = imcorner(imgg; method=harris)
        fts1 = Features(corners)

        # draw the results
        for ft in fts1
            drawfeaturecircle2d!(imgg, ft, radius=10)
        end
        imshow(canvases[1,2], imgg)
        sleep(0.001)
    end


    nothing
end




# f = VideoIO.testvideo("annie_oakley")
f = VideoIO.opencamera()
fromvideohandle(f)
close(f)
