# Harris corner features from image files

using Images, ImageView, ImageDraw, ImageFeatures, Gtk.ShortNames, VideoIO
using TestImages


@show projdir = joinpath(dirname(@__FILE__), "..")
srcdir = joinpath(projdir,"src")
include(srcdir, "SensorFeatureTracking.jl")
include(srcdir, "Common.jl")



# trying out different stuff
# img = testimage("walkbridge")
# img = testimage("livingroom")

# f = VideoIO.testvideo("annie_oakley")
f = VideoIO.opencamera()
img = read(f)
close(f)
# size(img)

imgg = Gray.(img)
imshow(img)

# Just in time compiling, see usage below
Features(fastcorners(imgg, 12, 0.2)); # compile first
getapproxbestharris(imgg, 500, k=0.04); # compile first


# Fast corner features
@time begin
  corners = fastcorners(imgg, 12, 0.2)
  feats1 = Features(corners)
end

# selected best harris features
@time feats2 = getapproxbestharris(imgg, 500, k=0.04)


# separate drawing image
imcf = deepcopy(imgg);
imch = deepcopy(imgg);
for ft in fts1
    drawfeaturecircle2d!(imcf, ft, radius=3)
    drawfeaturecircle2d!(imch, ft, radius=3)
end

imshow(imcf)
imshow(imch)



# cs = getharriscorners(imgg,fracmax=0.6, k=0.04)
## corners = BitArray{2}(cs)
# fts1 = Features(cs)
