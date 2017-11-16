# First compile all functions in RT_tracking_functions_list.jl
#


## Section 1: import packages

using Images, ImageView, ImageDraw, ImageFeatures, Gtk.ShortNames, VideoIO, ImageFiltering
using SensorFeatureTracking

#######
## Section 2: Setup structs and use Harris corner detection to create a list of features

const TrackingType_Forward = "Forward"
const TrackingType_Pyramid = "Pyramid"
const TrackingType_Inversed = "Inversed"
const TrackingType_InversedPyramid = "InversedPyramid"

const windowSize_25 = 25            # this is half the size of the window to look for a matching feature. Actual window size is windowSize * 2 + 1
const windowSize_20 = 20            # windowSize = windowSize_20 will result in a 41x41 window
const windowSize_15 = 15
const windowSize_10 = 10

frame_counter_from = 2             # in an image sequence you can select a range of images from frame_counter_from + 1 to frame_counter_to
frame_counter_to = 213
nfeatures=10

frame_counter = 2
window_counter = 0
update_reference_frame_count = 10

number_frames = frame_counter_to - frame_counter_from +1

img = load(joinpath(dirname(@__FILE__),"../Data/testSequence/image_$(frame_counter_from - 1).jpg"))
img_end = load(joinpath(dirname(@__FILE__),"../Data/testSequence/image_$(frame_counter_to).jpg"))

I = Gray.(img);
orgI_setup = deepcopy(img)
orgI_setup = Gray.(orgI_setup)
orgI_setup = convert(Array{Float64}, orgI_setup)

#harris corner detection=============

corners = getApproxBestHarrisInWindow(I, nfeatures=nfeatures)   # function in RT_tracking_functions_list.jl
number_features_setup = length(corners[:,1])

#harris corner detection=============

# images used to draw and display the tracked feature's path
feature_path_img_start = deepcopy(img)
feature_path_img_start = Gray.(feature_path_img_start);

feature_path_img_end = deepcopy(img_end)
feature_path_img_end = Gray.(feature_path_img_end);

#constructor function for structs ITVar and ITConst
ITVar, ITConst = ImageTrackerSetup(orgI_setup, corners, windowSize = windowSize_15, TrackingType_setup = TrackingType_Inversed)
# fillNewImageTemplates!(ITVar, ITConst)
#########
# Section 3: Run KLT tracker on the selected image sequence
frame_counter = 2
window_counter = 0
tic()
while frame_counter <= number_frames
    @show frame_counter
    window_counter += 1
    # Load next image
    NextFrame = load(joinpath(dirname(@__FILE__),"../Data/testSequence/image_$(frame_counter + frame_counter_from - 1).jpg"))
    NextFrame = Gray.(NextFrame)
    NextFrame = convert(Array{Float64}, NextFrame)
    I_nextFrame = convert(Array{Float64}, NextFrame)

    ITVar.I_nextFrame = I_nextFrame
    if (ITConst.TrackingType == "Pyramid" || ITConst.TrackingType == "InversedPyramid")
        ITVar.I_nextFrame_downsample = imresize(I_nextFrame, (Int(length(I_nextFrame[:,1])/ITConst.downsampleFactor),Int(length(I_nextFrame[1,:])/ITConst.downsampleFactor)));
    end

        # Main KLT tracker function ==============
        # @time KTL_Tracker!(ITVar, ITConst)
        KTL_Tracker!(ITVar, ITConst)
        # Main KLT tracker function ==============

    # Draw the path of the feature on both the first and last image in the sequence
    # This code draws lines between the reference frame and the tracked feature and not sequential frames.
    # If you need a frame to frame feature path set update_reference_frame_count = 1, however this will decrease the accuracy of the tracker
        for columnCount = 1:length(ITVar.p_reference[1,:])
            if (ITVar.p_reference[2, columnCount][1] <= 0   ||   ITVar.p_reference[2, columnCount][2] <= 0)
                @show fail=1
            else
                draw!(feature_path_img_start, LineSegment(ITVar.p_reference[1, columnCount],ITVar.p_reference[2, columnCount]))
            end
        end
        for columnCount = 1:length(ITVar.p_reference[1,:])
            if (ITVar.p_reference[2, columnCount][1] <= 0   ||   ITVar.p_reference[2, columnCount][2] <= 0)
                @show fail=1
            else
                draw!(feature_path_img_end, LineSegment(ITVar.p_reference[1, columnCount],ITVar.p_reference[2, columnCount]))
            end
        end

    # Update the frame used as reference for tracking
    # Making update_reference_frame_count larger reduces feature drift but can make the tracker lose the feature if the feature change to much
    if (window_counter == update_reference_frame_count)
        # if frame_counter == 96
        #     @show ITVar
        # end
        fillNewImageTemplates!(ITVar, ITConst)
        window_counter = 0
    end

    frame_counter += 1
end
toc()
ImageView.imshow(feature_path_img_start)
ImageView.imshow(feature_path_img_end)
####
