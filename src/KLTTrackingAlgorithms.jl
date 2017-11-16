include("ndgrid.jl")

####################################################################
## Structs for forward KLT tracking

mutable struct F_ImageTrackerVariables

    orgI::Array{Float64,2}                      #the first frame in the image sequence, does not need to be updated after every tracking itteration
    I_nextFrame::Array{Float64,2}               #the next frame in the image sequence, needs to be updated after every tracking itteration
    p_reference::Array{CartesianIndex{2}}       #feature pixel coordinates. p_reference[1,:] = coordinate of the reference feature on orgI. p_reference[2,:] = coordinate of the new feature on I_nextFrame

end

struct F_ImageTrackerConstants

    TrackingType::String
    windowSize::Int8
    number_features::Int8
    x::Array{Float64,2}
    y::Array{Float64,2}
    xder::Array{Int64,2}
    yder::Array{Int64,2}
    DGaussx::Array{Float64,2}
    DGaussy::Array{Float64,2}
    W_Jacobian::Array{Float64,3}

end

## Structs for forward KLT tracking
####################################################################
## Structs for forward KLT tracking with pyramid images

mutable struct FP_ImageTrackerVariables

    orgI::Array{Float64,2}                      #the first frame in the image sequence, does not need to be updated after every tracking itteration
    I_nextFrame::Array{Float64,2}               #the next frame in the image sequence, needs to be updated after every tracking itteration
    orgI_downsample::Array{Float64,2}           #when usning pyramid images orgI_downsample = orgI downsampled by a factor of downsampleFactor
    I_nextFrame_downsample::Array{Float64,2}    #when usning pyramid images I_nextFrame_downsample = I_nextFrame downsampled by a factor of downsampleFactor
    p_reference::Array{CartesianIndex{2}}       #feature pixel coordinates. p_reference[1,:] = coordinate of the reference feature on orgI. p_reference[2,:] = coordinate of the new feature on I_nextFrame

end

struct FP_ImageTrackerConstants

    TrackingType::String
    windowSize::Int8
    number_features::Int8
    downsampleFactor::Int8
    x::Array{Float64,2}
    y::Array{Float64,2}
    xder::Array{Int64,2}
    yder::Array{Int64,2}
    DGaussx::Array{Float64,2}
    DGaussy::Array{Float64,2}
    W_Jacobian::Array{Float64,3}

end

## Structs for forward KLT tracking with pyramid images
####################################################################
## Structs for inversed KLT tracking

mutable struct I_ImageTemplate

    T::Array{Float64,2}
    I_steepest::Array{Float64,2}
    H_inv::Array{Float64,2}

end

mutable struct I_ImageTrackerVariables

    orgI::Array{Float64,2}                      #the first frame in the image sequence, does not need to be updated after every tracking itteration
    I_nextFrame::Array{Float64,2}               #the next frame in the image sequence, needs to be updated after every tracking itteration
    Template::Array{I_ImageTemplate,1}            #template information for the tracked feature
    p_reference::Array{CartesianIndex{2}}       #feature pixel coordinates. p_reference[1,:] = coordinate of the reference feature on orgI. p_reference[2,:] = coordinate of the new feature on I_nextFrame

end

struct I_ImageTrackerConstants

    TrackingType::String
    windowSize::Int8
    number_features::Int8
    x::Array{Float64,2}
    y::Array{Float64,2}
    xder::Array{Int64,2}
    yder::Array{Int64,2}
    DGaussx::Array{Float64,2}
    DGaussy::Array{Float64,2}
    W_Jacobian::Array{Float64,3}

end

## Structs for inversed KLT tracking
####################################################################
## Structs for inversed KLT tracking with pyramid images

mutable struct IP_ImageTemplate

    T::Array{Float64,2}
    T_downsample::Array{Float64,2}
    I_steepest::Array{Float64,2}
    I_steepest_downsample::Array{Float64,2}
    H_inv::Array{Float64,2}
    H_inv_downsample::Array{Float64,2}

end

mutable struct IP_ImageTrackerVariables

    orgI::Array{Float64,2}                      #the first frame in the image sequence, does not need to be updated after every tracking itteration
    I_nextFrame::Array{Float64,2}               #the next frame in the image sequence, needs to be updated after every tracking itteration
    orgI_downsample::Array{Float64,2}           #when usning pyramid images orgI_downsample = orgI downsampled by a factor of downsampleFactor
    I_nextFrame_downsample::Array{Float64,2}    #when usning pyramid images I_nextFrame_downsample = I_nextFrame downsampled by a factor of downsampleFactor
    Template::Array{IP_ImageTemplate,1}            #template information for the tracked feature
    p_reference::Array{CartesianIndex{2}}       #feature pixel coordinates. p_reference[1,:] = coordinate of the reference feature on orgI. p_reference[2,:] = coordinate of the new feature on I_nextFrame

end

struct IP_ImageTrackerConstants

    TrackingType::String
    windowSize::Int8
    number_features::Int8
    downsampleFactor::Int8
    x::Array{Float64,2}
    y::Array{Float64,2}
    xder::Array{Int64,2}
    yder::Array{Int64,2}
    DGaussx::Array{Float64,2}
    DGaussy::Array{Float64,2}
    W_Jacobian::Array{Float64,3}

end

## Structs for inversed KLT tracking with pyramid images
####################################################################










##
"""
    ImageTrackerSetup(orgI_setup, corners,[windowSize = 20, downsampleFactor_setup = 2])

orgI_setup:             Image to do tracking on
corners:                List of corners, preferably a returned list from getApproxBestHarrisInWindow()
windowSize              Half the size of the window to look for a matching feature. Actual window size is windowSize * 2 + 1, windowSize = 20 will result in a 41x41 window
downsampleFactor_setup  downsampleFactor_setup = 2: use pyramid images (first track on a downsampled image, then on the regular image with a smaller windowsize), increases speed. Set downsampleFactor_setup = 1 to use only regular image

Returns two structures, one of type ImageTrackerVariables and one of type ImageTrackerConstants
"""

function ImageTrackerSetup(orgI_setup, corners; windowSize = 20, TrackingType_setup = "Inversed")

    if (TrackingType_setup == "Pyramid" || TrackingType_setup == "InversedPyramid")
        downsampleFactor_setup = 2
    else
        downsampleFactor_setup = 1
    end

    ref_point = CartesianIndex{2}
    ref_point_downsampled = CartesianIndex{2}

    windowSize_setup = round(Int64, windowSize/downsampleFactor_setup)
    orgI_downsample_setup = imresize(orgI_setup, (Int64(length(orgI_setup[:,1])/downsampleFactor_setup),Int64(length(orgI_setup[1,:])/downsampleFactor_setup)));
    number_features_setup = length(corners[:,1])

    # Pixel coordinate matrix
    p_reference_setup = Array{CartesianIndex{2}}(2,number_features_setup)
    for count = 1:number_features_setup
        p_reference_setup[1, count] = corners[count].keypoint
        p_reference_setup[2, count] = corners[count].keypoint
    end

    # Make derivatives kernels
    x_setup, y_setup = ndgrid(0:2*windowSize_setup,0:2*windowSize_setup)

    x_setup=x_setup.-(windowSize_setup+1)
    y_setup=y_setup.-(windowSize_setup+1)
    # x_setup=x_setup.-(windowSize_setup)
    # y_setup=y_setup.-(windowSize_setup)

    sigma = 2;
    xder_setup,yder_setup =ndgrid(floor(-3*sigma):ceil(3*sigma),floor(-3*sigma):ceil(3*sigma));
    DGaussx_setup =-(xder_setup./(2*pi*sigma^4)).*exp(-(xder_setup.^2+yder_setup.^2)/(2*sigma^2));
    DGaussy_setup =-(yder_setup./(2*pi*sigma^4)).*exp(-(xder_setup.^2+yder_setup.^2)/(2*sigma^2));

    DGaussx_reflected_setup = parent(reflect(DGaussx_setup))
    DGaussy_reflected_setup = parent(reflect(DGaussy_setup))

    # Evaluate the Jacobian
    W_Jacobian_x_setup=[x_setup[:] zeros(size(x_setup[:])) y_setup[:] zeros(size(x_setup[:])) ones(size(x_setup[:])) zeros(size(x_setup[:]))]
    W_Jacobian_y_setup=[zeros(size(x_setup[:])) x_setup[:] zeros(size(x_setup[:])) y_setup[:] zeros(size(x_setup[:])) ones(size(x_setup[:]))]

    W_Jacobian_setup = Array{Float64}(2,6,length(x_setup))
    I_steepest_setup = Array{Float64}(length(x_setup),6)

    for j1=1:length(x_setup)
        W_Jacobian_setup[:,:,j1]=[W_Jacobian_x_setup[j1,:] W_Jacobian_y_setup[j1,:]]'
    end

    T = zeros(windowSize_setup * 2 + 1, windowSize_setup * 2 + 1 )
    Ix = zeros(windowSize_setup * 2 + 1, windowSize_setup * 2 + 1 )
    Iy = zeros(windowSize_setup * 2 + 1, windowSize_setup * 2 + 1 )
    T_downsample = zeros(windowSize_setup * 2 + 1, windowSize_setup * 2 + 1 )
    Ix_downsample = zeros(windowSize_setup * 2 + 1, windowSize_setup * 2 + 1 )
    Iy_downsample = zeros(windowSize_setup * 2 + 1, windowSize_setup * 2 + 1 )

    if (TrackingType_setup == "Inversed")
        single_template_setup = I_ImageTemplate(zeros(windowSize_setup*2+1, windowSize_setup*2+1), zeros(length(x_setup), 6), zeros(6, 6))
        Template_setup = Array{I_ImageTemplate,1}(number_features_setup)
    else
        single_template_setup = IP_ImageTemplate(zeros(windowSize_setup*2+1, windowSize_setup*2+1), zeros(windowSize_setup*2+1, windowSize_setup*2+1), zeros(length(x_setup), 6), zeros(length(x_setup), 6), zeros(6, 6), zeros(6, 6))
        Template_setup = Array{IP_ImageTemplate,1}(number_features_setup)
    end
    # Template_setup = Array{ImageTemplate,1}(number_features_setup)


    Ix_grad = imfilter(orgI_setup, centered(DGaussx_reflected_setup));
    Iy_grad = imfilter(orgI_setup, centered(DGaussy_reflected_setup));

    Ix_grad_downsample = imfilter(orgI_downsample_setup, centered(DGaussx_reflected_setup));
    Iy_grad_downsample = imfilter(orgI_downsample_setup, centered(DGaussy_reflected_setup));

    for count = 1:number_features_setup

        x_min = round(Int64,p_reference_setup[1,count][1]-windowSize_setup)
        x_max = round(Int64,p_reference_setup[1,count][1]+windowSize_setup)
        y_min = round(Int64,p_reference_setup[1,count][2]-windowSize_setup)
        y_max = round(Int64,p_reference_setup[1,count][2]+windowSize_setup)

        x_min_downsample = round(Int64,p_reference_setup[1,count][1]/downsampleFactor_setup-windowSize_setup)
        x_max_downsample = round(Int64,p_reference_setup[1,count][1]/downsampleFactor_setup+windowSize_setup)
        y_min_downsample = round(Int64,p_reference_setup[1,count][2]/downsampleFactor_setup-windowSize_setup)
        y_max_downsample = round(Int64,p_reference_setup[1,count][2]/downsampleFactor_setup+windowSize_setup)

        T = orgI_setup[x_min : x_max , y_min : y_max]
        T_downsample = orgI_downsample_setup[x_min_downsample : x_max_downsample , y_min_downsample : y_max_downsample]

        single_template_setup.T = T
        if (TrackingType_setup == "InversedPyramid")
            single_template_setup.T_downsample = T_downsample
        end

        Ix = Ix_grad[x_min : x_max , y_min : y_max]
        Iy = Iy_grad[x_min : x_max , y_min : y_max]

        Ix_downsample = Ix_grad_downsample[x_min_downsample : x_max_downsample , y_min_downsample : y_max_downsample]
        Iy_downsample = Iy_grad_downsample[x_min_downsample : x_max_downsample , y_min_downsample : y_max_downsample]


        # W_p = [ 1 0 p_reference_setup[1,count][1]; 0 1 p_reference_setup[1,count][2]];

        Gradient1 = 0
        for j1=1:length(x_setup)
            Gradient1=[Ix[j1] Iy[j1]];
            Gradient1_downsample=[Ix_downsample[j1] Iy_downsample[j1]];

            single_template_setup.I_steepest[j1,1:6] = Gradient1 * W_Jacobian_setup[:,:,j1];
            if (TrackingType_setup == "InversedPyramid")
                single_template_setup.I_steepest_downsample[j1,1:6] = Gradient1_downsample * W_Jacobian_setup[:,:,j1];
            end
        end

        H=zeros(6,6);
        H_downsample=zeros(6,6);
        for j2=1:length(x_setup)
            H = H + single_template_setup.I_steepest[j2,:] * single_template_setup.I_steepest[j2,:]'
            if (TrackingType_setup == "InversedPyramid")
                H_downsample = H_downsample + single_template_setup.I_steepest_downsample[j2,:] * single_template_setup.I_steepest_downsample[j2,:]'
            end
        end

        single_template_setup.H_inv = inv(H)
        if (TrackingType_setup == "InversedPyramid")
            single_template_setup.H_inv_downsample = inv(H_downsample)
        end

        Template_setup[count] = deepcopy(single_template_setup)

    end

    # ImageTrackerVariables
    orgI_constructor                    = orgI_setup
    I_nextFrame_constructor             = orgI_setup
    orgI_downsample_constructor         = orgI_downsample_setup
    I_nextFrame_downsample_constructor  = orgI_downsample_setup
    Template_constructor                = Template_setup
    p_reference_constructor             = p_reference_setup

    # ImageTrackerConstants
    TrackingType_constructor            = TrackingType_setup
    windowSize_constructor              = windowSize_setup
    number_features_constructor         = number_features_setup
    downsampleFactor_constructor        = downsampleFactor_setup
    x_constructor                       = x_setup
    y_constructor                       = y_setup
    xder_constructor                    = xder_setup
    yder_constructor                    = yder_setup
    DGaussx_constructor                 = DGaussx_reflected_setup
    DGaussy_constructor                 = DGaussy_reflected_setup
    W_Jacobian_constructor              = W_Jacobian_setup



    if (TrackingType_setup == "Forward")

        ITVar = F_ImageTrackerVariables(    orgI_constructor,
                                            I_nextFrame_constructor,
                                            p_reference_constructor)

        #
        ITConst = F_ImageTrackerConstants(  TrackingType_constructor,
                                            windowSize_constructor,
                                            number_features_constructor,
                                            x_constructor,
                                            y_constructor,
                                            xder_constructor,
                                            yder_constructor,
                                            DGaussx_constructor,
                                            DGaussy_constructor,
                                            W_Jacobian_constructor)

    elseif (TrackingType_setup == "Pyramid")

        ITVar = FP_ImageTrackerVariables(   orgI_constructor,
                                            I_nextFrame_constructor,
                                            orgI_downsample_constructor,
                                            I_nextFrame_downsample_constructor,
                                            p_reference_constructor)

        #
        ITConst = FP_ImageTrackerConstants( TrackingType_constructor,
                                            windowSize_constructor,
                                            number_features_constructor,
                                            downsampleFactor_constructor,
                                            x_constructor,
                                            y_constructor,
                                            xder_constructor,
                                            yder_constructor,
                                            DGaussx_constructor,
                                            DGaussy_constructor,
                                            W_Jacobian_constructor)

    elseif (TrackingType_setup == "Inversed")

        ITVar = I_ImageTrackerVariables(    orgI_constructor,
                                            I_nextFrame_constructor,
                                            Template_constructor ,
                                            p_reference_constructor)

        #
        ITConst = I_ImageTrackerConstants(  TrackingType_constructor,
                                            windowSize_constructor,
                                            number_features_constructor,
                                            x_constructor,
                                            y_constructor,
                                            xder_constructor,
                                            yder_constructor,
                                            DGaussx_constructor,
                                            DGaussy_constructor,
                                            W_Jacobian_constructor)

    else

        ITVar = IP_ImageTrackerVariables(   orgI_constructor,
                                            I_nextFrame_constructor,
                                            orgI_downsample_constructor,
                                            I_nextFrame_downsample_constructor,
                                            Template_constructor ,
                                            p_reference_constructor)

        #
        ITConst = IP_ImageTrackerConstants( TrackingType_constructor,
                                            windowSize_constructor,
                                            number_features_constructor,
                                            downsampleFactor_constructor,
                                            x_constructor,
                                            y_constructor,
                                            xder_constructor,
                                            yder_constructor,
                                            DGaussx_constructor,
                                            DGaussy_constructor,
                                            W_Jacobian_constructor)

    end







    return ITVar, ITConst

end
#####################
function fillNewImageTemplates!(ITVar, ITConst)

    for count = 1:ITConst.number_features
        testedges(ITVar, ITConst, count)
    end
    #update reference image and reference feature coordinates
    ITVar.orgI = ITVar.I_nextFrame
    if (ITConst.TrackingType == "Pyramid" || ITConst.TrackingType == "InversedPyramid")
        ITVar.orgI_downsample = ITVar.I_nextFrame_downsample
    end
    ITVar.p_reference[1, :] = ITVar.p_reference[2, :]

    Ix = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Iy = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )

    # Evaluate the gradient of the template
    Ix_grad = imfilter(ITVar.orgI, centered(ITConst.DGaussx));
    Iy_grad = imfilter(ITVar.orgI, centered(ITConst.DGaussy));

    if (ITConst.TrackingType == "Pyramid" || ITConst.TrackingType == "InversedPyramid")
        Ix_grad_downsample = imfilter(ITVar.orgI_downsample, centered(ITConst.DGaussx));
        Iy_grad_downsample = imfilter(ITVar.orgI_downsample, centered(ITConst.DGaussy));
    end

    if (ITConst.TrackingType == "Inversed" || ITConst.TrackingType == "InversedPyramid")

        for count = 1:ITConst.number_features

            if (ITVar.p_reference[2, count][1] == 0)

            else

                x_min = round(Int64, ITVar.p_reference[2, count][1])-ITConst.windowSize
                x_max = round(Int64, ITVar.p_reference[2, count][1])+ITConst.windowSize
                y_min = round(Int64, ITVar.p_reference[2, count][2])-ITConst.windowSize
                y_max = round(Int64, ITVar.p_reference[2, count][2])+ITConst.windowSize

                if (ITConst.TrackingType == "InversedPyramid")
                    x_min_downsample = round(Int64, ITVar.p_reference[2, count][1]/ITConst.downsampleFactor)-ITConst.windowSize
                    x_max_downsample = round(Int64, ITVar.p_reference[2, count][1]/ITConst.downsampleFactor)+ITConst.windowSize
                    y_min_downsample = round(Int64, ITVar.p_reference[2, count][2]/ITConst.downsampleFactor)-ITConst.windowSize
                    y_max_downsample = round(Int64, ITVar.p_reference[2, count][2]/ITConst.downsampleFactor)+ITConst.windowSize
                end

                ITVar.Template[count].T = ITVar.orgI[x_min:x_max,y_min:y_max]
                if (ITConst.TrackingType == "InversedPyramid")
                    ITVar.Template[count].T_downsample = ITVar.orgI_downsample[x_min_downsample:x_max_downsample,y_min_downsample:y_max_downsample]
                end

                Ix = Ix_grad[x_min:x_max,y_min:y_max]
                Iy = Iy_grad[x_min:x_max,y_min:y_max]

                if (ITConst.TrackingType == "InversedPyramid")
                    Ix_downsample = Ix_grad_downsample[x_min_downsample:x_max_downsample,y_min_downsample:y_max_downsample]
                    Iy_downsample = Iy_grad_downsample[x_min_downsample:x_max_downsample,y_min_downsample:y_max_downsample]
                end


                Gradient1 = 0
                for j1=1:length(ITConst.x)
                    Gradient1=[Ix[j1] Iy[j1]];
                    if (ITConst.TrackingType == "InversedPyramid")
                        Gradient1_downsample=[Ix_downsample[j1] Iy_downsample[j1]];
                    end

                    ITVar.Template[count].I_steepest[j1,1:6] = Gradient1 * ITConst.W_Jacobian[:,:,j1];
                    if (ITConst.TrackingType == "InversedPyramid")
                        ITVar.Template[count].I_steepest_downsample[j1,1:6] = Gradient1_downsample * ITConst.W_Jacobian[:,:,j1];
                    end
                end

                H=zeros(6,6);
                if (ITConst.TrackingType == "InversedPyramid")
                    H_downsample=zeros(6,6);
                end
                for j2=1:length(ITConst.x)
                    H = H + ITVar.Template[count].I_steepest[j2,:] * ITVar.Template[count].I_steepest[j2,:]'
                    if (ITConst.TrackingType == "InversedPyramid")
                        H_downsample = H_downsample + ITVar.Template[count].I_steepest_downsample[j2,:] * ITVar.Template[count].I_steepest_downsample[j2,:]'
                    end
                end

                ITVar.Template[count].H_inv = inv(H)
                if (ITConst.TrackingType == "InversedPyramid")
                    ITVar.Template[count].H_inv_downsample = inv(H_downsample)
                end
            end
        end
    end

end
####################
"""
    testedges(ITVar, ITConst, corner_i)

ITVar:   construct of variables of type ImageTrackerVariables
ITConst: construct of constants of type ImageTrackerConstants
corner_i: Feature to test

Returns true if the frame is within the bounds of the image, false otherwise
"""
function testedges(ITVar, ITConst, corner_i)

    if (ITConst.TrackingType == "Forward" || ITConst.TrackingType == "Inversed")
        if (ITVar.p_reference[2, corner_i][1]-ITConst.windowSize > 0 && ITVar.p_reference[2, corner_i][1]+ITConst.windowSize <= size(ITVar.orgI, 1) && ITVar.p_reference[2, corner_i][2]-ITConst.windowSize > 0 && ITVar.p_reference[2, corner_i][2]+ITConst.windowSize < size(ITVar.orgI, 2))
            return true
        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
            ITVar.p_reference[1, corner_i] = CartesianIndex(0, 0)
            return false
        end
    elseif (ITConst.TrackingType == "Pyramid" || ITConst.TrackingType == "InversedPyramid")
        if (ITVar.p_reference[2, corner_i][1]-(ITConst.windowSize*2+1) > 0 && ITVar.p_reference[2, corner_i][1]+(ITConst.windowSize*2+1) < size(ITVar.orgI, 1) && ITVar.p_reference[2, corner_i][2]-(ITConst.windowSize*2+1) > 0 && ITVar.p_reference[2, corner_i][2]+(ITConst.windowSize*2+1) < size(ITVar.orgI, 2))
            return true
        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
            ITVar.p_reference[1, corner_i] = CartesianIndex(0, 0)
            return false
        end
    end
end

#####################
"""
    KTL_Tracker!(ITVar, ITConst)

ITVar:   construct of variables of type ImageTrackerVariables
ITConst: construct of constants of type ImageTrackerConstants

Returns nothing, updates p_reference[2,:] with the new coordinates of the tracked features
"""

function KTL_Tracker!(ITVar, ITConst)

    for corner_i = 1:ITConst.number_features
        if (testedges(ITVar, ITConst, corner_i))
            if (ITConst.TrackingType == "Forward")
                # slower code, does not use pyramid images============================================
                trackOneFeature(ITVar, ITConst, corner_i)
                # slower code, does not use pyramid images============================================
            elseif (ITConst.TrackingType == "Pyramid")
                # faster code, use pyramid images=====================================================
                trackOneFeaturePyramid(ITVar, ITConst, corner_i)
                # faster code, use pyramid images=====================================================
            elseif (ITConst.TrackingType == "Inversed")
                # slower code, does not use pyramid images============================================
                trackOneFeatureInverse(ITVar, ITConst, corner_i)
                # slower code, does not use pyramid images============================================
            elseif (ITConst.TrackingType == "InversedPyramid")
                # slower code, does not use pyramid images============================================
                trackOneFeatureInversePyramid(ITVar, ITConst, corner_i)
                # slower code, does not use pyramid images============================================
            end

        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
        end
    end
    return nothing
end

####################
"""
    trackOneFeatureInversePyramid(ITVar, ITConst, corner_i)

ITVar:   construct of variables of type ImageTrackerVariables
ITConst: construct of constants of type ImageTrackerConstants
corner_i:index of selected corner in ITVar.p_reference to do tracking on

Returns nothing, updates p_reference[2,corner_i] with the new coordinates of the tracked feature
"""

function trackOneFeatureInversePyramid(ITVar, ITConst, corner_i)
    Threshold = 0.2
    converged = true

    I_warped = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Ix = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Iy = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )

    p = [0 0 0 0 round(Int64, ITVar.p_reference[2, corner_i][1]/2) round(Int64, ITVar.p_reference[2, corner_i][2]/2)]

    delta_p = [0 0 0 0 100 100]

    for count_pyramid = 1:2

        delta_p = [0 0 0 0 100 100]

        counter = 0;

        while ( norm(delta_p) > Threshold)
            counter= counter + 1;
            converged = true
            if(counter > 100)
                converged = false
                break;
            end

            #The affine matrix for template rotation and translation
            W_p = [ 1+p[1] p[3] p[5]; p[2] 1+p[4] p[6]];

            #1 Warp I with w
            if count_pyramid == 1
                warping!(I_warped, ITVar.I_nextFrame_downsample, ITConst.x, ITConst.y, W_p)
                I_error= I_warped - ITVar.Template[corner_i].T_downsample
            else
                warping!(I_warped, ITVar.I_nextFrame, ITConst.x, ITConst.y, W_p)
                I_error= I_warped - ITVar.Template[corner_i].T
            end

            # Break if outside image
            if (!testedges(ITVar, ITConst, corner_i))
                converged = false
                break;
            end

            #2 Multiply steepest descend with error

            if count_pyramid == 1
                total=zeros(6,1);
                for j3=1:length(ITConst.x)
                    total = total + (ITVar.Template[corner_i].I_steepest_downsample[j3,:]' * I_error[j3])'
                end
            else
                total=zeros(6,1);
                for j3=1:length(ITConst.x)
                    total = total + (ITVar.Template[corner_i].I_steepest[j3,:]' * I_error[j3])'
                end
            end

            #3 Computer delta_p

            if count_pyramid == 1
                delta_p = ITVar.Template[corner_i].H_inv_downsample*total;

            else
                delta_p = ITVar.Template[corner_i].H_inv*total;
            end

            #4 Update the parameters p <- p + delta_p
            p = p - 0.1 * delta_p';
        end
        if count_pyramid ==1
            p = [0 0 0 0 round(Int64, p[5]*2) round(Int64, p[6]*2)]
        end
    end
    if (converged == true)
        if (testedges(ITVar, ITConst, corner_i) == true)
            ITVar.p_reference[2, corner_i] = CartesianIndex(round(Int64,p[5]), round(Int64,p[6]))
        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
        end
    else
        ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
    end
end


#############
####################
"""
    trackOneFeatureInverse(ITVar, ITConst, corner_i)

ITVar:   construct of variables of type ImageTrackerVariables
ITConst: construct of constants of type ImageTrackerConstants
corner_i:index of selected corner in ITVar.p_reference to do tracking on

Returns nothing, updates p_reference[2,corner_i] with the new coordinates of the tracked feature
Does not use orgI_downsample or I_nextFrame_downsample at all, downsampleFactor must be 1
"""

function trackOneFeatureInverse(ITVar, ITConst, corner_i)
    Threshold = 0.2
    converged = true

    I_warped = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Ix = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Iy = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )

    p = [0 0 0 0 ITVar.p_reference[2, corner_i][1] ITVar.p_reference[2, corner_i][2]]

    delta_p = [0 0 0 0 100 100]


    counter = 0;

    while ( norm(delta_p) > Threshold)
        counter= counter + 1;
        converged = true
        if(counter > 100)
            converged = false
            break;
        end

        #The affine matrix for template rotation and translation
        W_p = [ 1+p[1] p[3] p[5]; p[2] 1+p[4] p[6]];

        #1 Warp I with w
        warping!(I_warped, ITVar.I_nextFrame, ITConst.x, ITConst.y, W_p)

        #2 Subtract T from I
        I_error= I_warped - ITVar.Template[corner_i].T

        # Break if outside image
        if((p[5]>(size(ITVar.I_nextFrame,1))-1)||(p[6]>(size(ITVar.I_nextFrame,2)-1))||(p[5]<0)||(p[6]<0))
            break;#put back
        end

        #3 Multiply steepest descend with error
        total=zeros(6,1);
        for j3=1:length(ITConst.x)
            total = total + (ITVar.Template[corner_i].I_steepest[j3,:]' * I_error[j3])'
        end

        #4 Computer delta_p
        delta_p = ITVar.Template[corner_i].H_inv*total;

        #5 Update the parameters p <- p - delta_p
        p = p - 0.1 * delta_p';

    end
    if (converged == true)
        # @show converged
        if (testedges(ITVar, ITConst, corner_i))
            ITVar.p_reference[2, corner_i] = CartesianIndex(round(Int,p[5]), round(Int,p[6]))
        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
        end
    else
        # @show converged
        ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
    end
end


#############
####################
"""
    trackOneFeaturePyramid(ITVar, ITConst, corner_i)

ITVar:   construct of variables of type ImageTrackerVariables
ITConst: construct of constants of type ImageTrackerConstants
corner_i:index of selected corner in ITVar.p_reference to do tracking on

Returns nothing, updates p_reference[2,corner_i] with the new coordinates of the tracked feature
Use orgI_downsample and I_nextFrame_downsample to track features, downsampleFactor must be 2 for now, can be increased in future work
"""

function trackOneFeaturePyramid(ITVar, ITConst, corner_i)
    Threshold = 0.2
    converged = true

    I_warped = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Ix = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Iy = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )

    p = [0 0 0 0 round(Int, ITVar.p_reference[2, corner_i][1]/2) round(Int, ITVar.p_reference[2, corner_i][2]/2)]

    for count_pyramid = 1:2

        if count_pyramid == 1
            if (testedges(ITVar, ITConst, corner_i))
                T = ITVar.orgI_downsample[round(Int64, ITVar.p_reference[1, corner_i][1]/2)-ITConst.windowSize:round(Int64, ITVar.p_reference[1, corner_i][1]/2)+ITConst.windowSize,round(Int64, ITVar.p_reference[1, corner_i][2]/2)-ITConst.windowSize:round(Int64, ITVar.p_reference[1, corner_i][2]/2)+ITConst.windowSize]
                T = convert(Array{Float64}, T)
            else
                break
            end
        else
            T = ITVar.orgI[round(Int64, ITVar.p_reference[1, corner_i][1])-ITConst.windowSize:round(Int64, ITVar.p_reference[1, corner_i][1])+ITConst.windowSize,round(Int64, ITVar.p_reference[1, corner_i][2])-ITConst.windowSize:round(Int64, ITVar.p_reference[1, corner_i][2])+ITConst.windowSize]
            T = convert(Array{Float64}, T)
        end

        delta_p = [0 0 0 0 100 100]

        # Filter the images to get the derivatives
        if count_pyramid == 1
            Ix_grad = imfilter(ITVar.I_nextFrame_downsample, centered(ITConst.DGaussx));
            Iy_grad = imfilter(ITVar.I_nextFrame_downsample, centered(ITConst.DGaussy));
        else
            Ix_grad = imfilter(ITVar.I_nextFrame, centered(ITConst.DGaussx));
            Iy_grad = imfilter(ITVar.I_nextFrame, centered(ITConst.DGaussy));
        end
        counter = 0;

        while ( norm(delta_p) > Threshold)
            counter= counter + 1;
            converged = true
            if(counter > 100)
                converged = false
                break;
            end

            #The affine matrix for template rotation and translation
            W_p = [ 1+p[1] p[3] p[5]; p[2] 1+p[4] p[6]];

            #1 Warp I with w
            if count_pyramid == 1
                warping!(I_warped, ITVar.I_nextFrame_downsample, ITConst.x, ITConst.y, W_p)
            else
                warping!(I_warped, ITVar.I_nextFrame, ITConst.x, ITConst.y, W_p)
            end

            #2 Subtract I from T
            I_error= T - I_warped

            # Break if outside image
            if((p[5]>(size(ITVar.I_nextFrame,1))-1)||(p[6]>(size(ITVar.I_nextFrame,2)-1))||(p[5]<0)||(p[6]<0))
                break;
            end

            #3 Warp the gradient
            warping!(Ix, Ix_grad, ITConst.x, ITConst.y, W_p);
            warping!(Iy, Iy_grad, ITConst.x, ITConst.y, W_p);

            #4 Compute steepest descent
            I_steepest=zeros(length(ITConst.x),6);
            Gradient1 = 0
            W_Jacobian = 0
            for j1=1:length(ITConst.x)
                # W_Jacobian=[ITConst.W_Jacobian_x[j1,:] ITConst.W_Jacobian_y[j1,:]]';
                Gradient1=[Ix[j1] Iy[j1]];
                I_steepest[j1,1:6] = Gradient1 * ITConst.W_Jacobian[:,:,j1];
            end

            #5 Compute Hessian
            H=zeros(6,6);
            for j2=1:length(ITConst.x)
                H = H + I_steepest[j2,:] * I_steepest[j2,:]'
            end

            #6 Multiply steepest descend with error
            total=zeros(6,1);
            for j3=1:length(ITConst.x)
                total = total + (I_steepest[j3,:]' * I_error[j3])'
            end

            #7 Computer delta_p
            delta_p=H\total;

            #8 Update the parameters p <- p + delta_p
            p = p + 0.1 * delta_p';
        end
        if count_pyramid ==1
            p = [0 0 0 0 round(Int64, p[5]*2) round(Int64, p[6]*2)]
        end
    end
    if (converged == true)
        if (testedges(ITVar, ITConst, corner_i))
            ITVar.p_reference[2, corner_i] = CartesianIndex(round(Int64,p[5]), round(Int64,p[6]))
        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
        end
    else
        ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
    end
end


####################
####################
"""
    trackOneFeature(ITVar, ITConst, corner_i)

ITVar:   construct of variables of type ImageTrackerVariables
ITConst: construct of constants of type ImageTrackerConstants
corner_i:index of selected corner in ITVar.p_reference to do tracking on

Returns nothing, updates p_reference[2,corner_i] with the new coordinates of the tracked feature
Does not use orgI_downsample or I_nextFrame_downsample at all, downsampleFactor must be 1
"""

function trackOneFeature(ITVar, ITConst, corner_i)
    Threshold = 0.2
    converged = true

    I_warped = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Ix = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )
    Iy = zeros(ITConst.windowSize * 2 + 1, ITConst.windowSize * 2 + 1 )

    p = [0 0 0 0 ITVar.p_reference[2, corner_i][1] ITVar.p_reference[2, corner_i][2]]

    T = ITVar.orgI[round(Int64, ITVar.p_reference[1, corner_i][1])-ITConst.windowSize:round(Int64, ITVar.p_reference[1, corner_i][1])+ITConst.windowSize,round(Int64, ITVar.p_reference[1, corner_i][2])-ITConst.windowSize:round(Int64, ITVar.p_reference[1, corner_i][2])+ITConst.windowSize]
    T = convert(Array{Float64}, T)

    delta_p = [0 0 0 0 100 100]

    # Filter the images to get the derivatives
    Ix_grad = imfilter(ITVar.I_nextFrame, centered(ITConst.DGaussx));
    Iy_grad = imfilter(ITVar.I_nextFrame, centered(ITConst.DGaussy));

    counter = 0;

    while ( norm(delta_p) > Threshold)
        counter= counter + 1;
        converged = true
        if(counter > 100)
            converged = false
            break;
        end

        #The affine matrix for template rotation and translation
        W_p = [ 1+p[1] p[3] p[5]; p[2] 1+p[4] p[6]];

        #1 Warp I with w
        warping!(I_warped, ITVar.I_nextFrame, ITConst.x, ITConst.y, W_p)

        #2 Subtract I from T
        I_error= T - I_warped

        # Break if outside image
        if((p[5]>(size(ITVar.I_nextFrame,1))-1)||(p[6]>(size(ITVar.I_nextFrame,2)-1))||(p[5]<0)||(p[6]<0))
            # @show converged = false
            break;#put back
        end

        #3 Warp the gradient
        warping!(Ix, Ix_grad, ITConst.x, ITConst.y, W_p);
        warping!(Iy, Iy_grad, ITConst.x, ITConst.y, W_p);

        #4 Compute steepest descent
        I_steepest=zeros(length(ITConst.x),6);
        Gradient1 = 0
        W_Jacobian = 0
        for j1=1:length(ITConst.x)
            # W_Jacobian=[ITConst.W_Jacobian_x[j1,:] ITConst.W_Jacobian_y[j1,:]]';
            Gradient1=[Ix[j1] Iy[j1]];
            I_steepest[j1,1:6] = Gradient1 * ITConst.W_Jacobian[:,:,j1]#W_Jacobian;
        end

        #5 Compute Hessian
        H=zeros(6,6);
        for j2=1:length(ITConst.x)
            H = H + I_steepest[j2,:] * I_steepest[j2,:]'
        end

        #6 Multiply steepest descend with error
        total=zeros(6,1);
        for j3=1:length(ITConst.x)
            total = total + (I_steepest[j3,:]' * I_error[j3])'
        end

        #7 Computer delta_p
        delta_p=H\total;

        #8 Update the parameters p <- p + delta_p
        p = p + 0.1 * delta_p';
    end
    if (converged == true)
        if (testedges(ITVar, ITConst, corner_i))
            ITVar.p_reference[2, corner_i] = CartesianIndex(round(Int64,p[5]), round(Int64,p[6]))
        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
        end
    else
        ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
    end
end


#############
#############
"""
    warping!(Iout,Iin,x,y,M)

Iout:   returned warped image
Iin:    image to be warped
x:      derivatives kernel on x axis
y:      derivatives kernel on y axis
M:      affine matrix for template rotation and translation

Return a warped image
"""
function warping!(Iout,Iin,x,y,M)
    # Affine transformation function (Rotation, Translation, Resize)
    # Calculate the Transformed coordinates

    Tlocalx =  M[1,1] .* x .+ M[1,2] .*y .+ M[1,3]
    Tlocaly =  M[2,1] .* x .+ M[2,2] .*y .+ M[2,3]

    #Iout  = interp2(Iin, Tlocalx, Tlocaly,'*linear');
    # All the neighborh pixels involved in linear interpolation.
    xBas0=floor.(Int64, Tlocalx)
    yBas0=floor.(Int64, Tlocaly)
    xBas1=xBas0+1
    yBas1=yBas0+1

    # Linear interpolation constants (percentages)
    xCom=Tlocalx-xBas0
    yCom=Tlocaly-yBas0
    perc0=(1-xCom).*(1-yCom)
    perc1=(1-xCom).*yCom
    perc2=xCom.*(1-yCom)
    perc3=xCom.*yCom

    # limit indexes to boundaries
    check_xBas0=(xBas0.<0).|(xBas0.>(size(Iin,1)-1))
    check_yBas0=(yBas0.<0).|(yBas0.>(size(Iin,2)-1))
    xBas0[check_xBas0]=0
    yBas0[check_yBas0]=0
    check_xBas1=(xBas1.<0).|(xBas1.>(size(Iin,1).-1))
    check_yBas1=(yBas1.<0).|(yBas1.>(size(Iin,2).-1))
    xBas1[check_xBas1]=0
    yBas1[check_yBas1]=0

    # Iout=zeros(Float64, size(x, 1), size(x, 2))

    Iin_one = Iin
    # Get the intensities
    intensity_xyz0=Iin_one[1+xBas0+yBas0*size(Iin,1)];
    intensity_xyz1=Iin_one[1+xBas0+yBas1*size(Iin,1)];
    intensity_xyz2=Iin_one[1+xBas1+yBas0*size(Iin,1)];
    intensity_xyz3=Iin_one[1+xBas1+yBas1*size(Iin,1)];

    Iout[:,:] .= intensity_xyz0 .* perc0 .+ intensity_xyz1 .* perc1 .+ intensity_xyz2 .* perc2 .+ intensity_xyz3 .* perc3;
    # Iout[:,:,i]=reshape(Iout_one, (size(x,1) size(x,2)));
    # Iout[:,:]=reshape(Iout_one, size(x,1), size(x,2))


    # end
    return nothing

end

############
