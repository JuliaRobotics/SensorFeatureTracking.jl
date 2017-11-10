include("ndgrid.jl")

mutable struct ImageTrackerVariables

    orgI::Array{Float64,2}                      #the first frame in the image sequence, does not need to be updated after every tracking itteration
    I_nextFrame::Array{Float64,2}               #the next frame in the image sequence, needs to be updated after every tracking itteration
    orgI_downsample::Array{Float64,2}           #when usning pyramid images orgI_downsample = orgI downsampled by a factor of downsampleFactor
    I_nextFrame_downsample::Array{Float64,2}    #when usning pyramid images I_nextFrame_downsample = I_nextFrame downsampled by a factor of downsampleFactor
    p_reference::Array{CartesianIndex{2}}       #feature pixel coordinates. p_reference[1,:] = coordinate of the reference feature on orgI. p_reference[2,:] = coordinate of the new feature on I_nextFrame

end

struct ImageTrackerConstants

    windowSize::Int8
    number_features::Int8
    downsampleFactor::Int8
    x::Array{Float64,2}
    y::Array{Float64,2}
    xder::Array{Int64,2}
    yder::Array{Int64,2}
    DGaussx::Array{Float64,2}
    DGaussy::Array{Float64,2}
    W_Jacobian_x::Array{Float64,2}
    W_Jacobian_y::Array{Float64,2}

end

##
"""
    ImageTrackerSetup(orgI_setup, corners,[windowSize = 20, downsampleFactor_setup = 2])

orgI_setup:             Image to do trackingon
corners:                List of corners, preferably a returned list from getApproxBestHarrisInWindow()
windowSize              Half the size of the window to look for a matching feature. Actual window size is windowSize * 2 + 1, windowSize = 20 will result in a 41x41 window
downsampleFactor_setup  downsampleFactor_setup = 2: use pyramid images (first track on a downsampled image, then on the regular image with a smaller windowsize), increases speed. Set downsampleFactor_setup = 1 to use only regular image

Returns two structures, one of type ImageTrackerVariables and one of type ImageTrackerConstants
"""

function ImageTrackerSetup(orgI_setup, corners; windowSize = 20, downsampleFactor_setup = 2)

    windowSize_setup = round(Int, windowSize/downsampleFactor_setup)
    orgI_downsample_setup = imresize(orgI_setup, (Int(length(orgI_setup[:,1])/downsampleFactor_setup),Int(length(orgI_setup[1,:])/downsampleFactor_setup)));
    number_features_setup = length(corners[:,1])

    # Pixel coordinate matrix
    p_reference_setup = Array{CartesianIndex{2}}(2,number_features_setup)
    for count = 1:number_features_setup
        p_reference_setup[1, count] = corners[count].keypoint
        p_reference_setup[2, count] = corners[count].keypoint
    end

    # Make derivatives kernels
    x_setup, y_setup = ndgrid(0:2*windowSize_setup,0:2*windowSize_setup)
    # TemplateCenter=size(x_setup)./2;
    # x_setup=x_setup-TemplateCenter[1]
    # y_setup=y_setup-TemplateCenter[2]
    x_setup=x_setup.-(windowSize_setup+1)
    y_setup=y_setup.-(windowSize_setup+1)

    sigma = 2;
    xder_setup,yder_setup =ndgrid(floor(-3*sigma):ceil(3*sigma),floor(-3*sigma):ceil(3*sigma));
    DGaussx_setup =-(xder_setup./(2*pi*sigma^4)).*exp(-(xder_setup.^2+yder_setup.^2)/(2*sigma^2));
    DGaussy_setup =-(yder_setup./(2*pi*sigma^4)).*exp(-(xder_setup.^2+yder_setup.^2)/(2*sigma^2));

    DGaussx_reflected_setup = parent(reflect(DGaussx_setup))
    DGaussy_reflected_setup = parent(reflect(DGaussy_setup))

    # Evaluate the Jacobian
    W_Jacobian_x_setup=[x_setup[:] zeros(size(x_setup[:])) y_setup[:] zeros(size(x_setup[:])) ones(size(x_setup[:])) zeros(size(x_setup[:]))]
    W_Jacobian_y_setup=[zeros(size(x_setup[:])) x_setup[:] zeros(size(x_setup[:])) y_setup[:] zeros(size(x_setup[:])) ones(size(x_setup[:]))]

    # ImageTrackerVariables
    orgI_constructor                    = orgI_setup
    I_nextFrame_constructor             = orgI_setup
    orgI_downsample_constructor         = orgI_downsample_setup
    I_nextFrame_downsample_constructor  = orgI_downsample_setup
    p_reference_constructor             = p_reference_setup

    # ImageTrackerConstants
    windowSize_constructor              = windowSize_setup
    number_features_constructor         = number_features_setup
    downsampleFactor_constructor        = downsampleFactor_setup
    x_constructor                       = x_setup
    y_constructor                       = y_setup
    xder_constructor                    = xder_setup
    yder_constructor                    = yder_setup
    DGaussx_constructor                 = DGaussx_reflected_setup
    DGaussy_constructor                 = DGaussy_reflected_setup
    W_Jacobian_x_constructor            = W_Jacobian_x_setup
    W_Jacobian_y_constructor            = W_Jacobian_y_setup


    ITVar = ImageTrackerVariables(      orgI_constructor,
                                        I_nextFrame_constructor,
                                        orgI_downsample_constructor,
                                        I_nextFrame_downsample_constructor,
                                        p_reference_constructor)

    #
    ITConst = ImageTrackerConstants(    windowSize_constructor,
                                        number_features_constructor,
                                        downsampleFactor_constructor,
                                        x_constructor,
                                        y_constructor,
                                        xder_constructor,
                                        yder_constructor,
                                        DGaussx_constructor,
                                        DGaussy_constructor,
                                        W_Jacobian_x_constructor,
                                        W_Jacobian_y_constructor)

    return ITVar, ITConst

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
        if (ITVar.p_reference[2, corner_i][1]-ITConst.windowSize > 0 && ITVar.p_reference[2, corner_i][1]+ITConst.windowSize <= size(ITVar.orgI, 1) && ITVar.p_reference[2, corner_i][2]-ITConst.windowSize > 0 && ITVar.p_reference[2, corner_i][2]+ITConst.windowSize < size(ITVar.orgI, 2))

            if (ITConst.downsampleFactor == 1)
            # slower code, does not use pyramid images============================================
                trackOneFeature(ITVar, ITConst, corner_i)
            # slower code, does not use pyramid images============================================
            else
            # faster code, use pyramid images=====================================================
                trackOneFeaturePyramid(ITVar, ITConst, corner_i)
            # faster code, use pyramid images=====================================================
            end

        else
            ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
        end
    end
    return nothing
end

####################
"""
    trackOneFeature(ITVar, ITConst, corner_i)

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
            T = ITVar.orgI_downsample[round(Int, ITVar.p_reference[1, corner_i][1]/2)-ITConst.windowSize:round(Int, ITVar.p_reference[1, corner_i][1]/2)+ITConst.windowSize,round(Int, ITVar.p_reference[1, corner_i][2]/2)-ITConst.windowSize:round(Int, ITVar.p_reference[1, corner_i][2]/2)+ITConst.windowSize]
            T = convert(Array{Float64}, T)
        else
            T = ITVar.orgI[round(Int, ITVar.p_reference[1, corner_i][1])-ITConst.windowSize:round(Int, ITVar.p_reference[1, corner_i][1])+ITConst.windowSize,round(Int, ITVar.p_reference[1, corner_i][2])-ITConst.windowSize:round(Int, ITVar.p_reference[1, corner_i][2])+ITConst.windowSize]
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
                warpping!(I_warped, ITVar.I_nextFrame_downsample, ITConst.x, ITConst.y, W_p)
            else
                warpping!(I_warped, ITVar.I_nextFrame, ITConst.x, ITConst.y, W_p)
            end

            #2 Subtract I from T
            I_error= T - I_warped

            # Break if outside image
            if((p[5]>(size(ITVar.I_nextFrame,1))-1)||(p[6]>(size(ITVar.I_nextFrame,2)-1))||(p[5]<0)||(p[6]<0))
                break;
            end

            #3 Warp the gradient
            warpping!(Ix, Ix_grad, ITConst.x, ITConst.y, W_p);
            warpping!(Iy, Iy_grad, ITConst.x, ITConst.y, W_p);

            #4 Compute steepest descent
            I_steepest=zeros(length(ITConst.x),6);
            Gradient1 = 0
            W_Jacobian = 0
            for j1=1:length(ITConst.x)
                W_Jacobian=[ITConst.W_Jacobian_x[j1,:] ITConst.W_Jacobian_y[j1,:]]';
                Gradient1=[Ix[j1] Iy[j1]];
                I_steepest[j1,1:6] = Gradient1 * W_Jacobian;
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
            p = [0 0 0 0 round(Int, p[5]*2) round(Int, p[6]*2)]
        end
    end
    if (converged == true)
        ITVar.p_reference[2, corner_i] = CartesianIndex(round(Int,p[5]), round(Int,p[6]))
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

    T = ITVar.orgI[round(Int, ITVar.p_reference[1, corner_i][1])-ITConst.windowSize:round(Int, ITVar.p_reference[1, corner_i][1])+ITConst.windowSize,round(Int, ITVar.p_reference[1, corner_i][2])-ITConst.windowSize:round(Int, ITVar.p_reference[1, corner_i][2])+ITConst.windowSize]
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
        warpping!(I_warped, ITVar.I_nextFrame, ITConst.x, ITConst.y, W_p)

        #2 Subtract I from T
        I_error= T - I_warped

        # Break if outside image
        if((p[5]>(size(ITVar.I_nextFrame,1))-1)||(p[6]>(size(ITVar.I_nextFrame,2)-1))||(p[5]<0)||(p[6]<0))
            # @show converged = false
            break;#put back
        end

        #3 Warp the gradient
        warpping!(Ix, Ix_grad, ITConst.x, ITConst.y, W_p);
        warpping!(Iy, Iy_grad, ITConst.x, ITConst.y, W_p);

        #4 Compute steepest descent
        I_steepest=zeros(length(ITConst.x),6);
        Gradient1 = 0
        W_Jacobian = 0
        for j1=1:length(ITConst.x)
            W_Jacobian=[ITConst.W_Jacobian_x[j1,:] ITConst.W_Jacobian_y[j1,:]]';
            Gradient1=[Ix[j1] Iy[j1]];
            I_steepest[j1,1:6] = Gradient1 * W_Jacobian;
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
        ITVar.p_reference[2, corner_i] = CartesianIndex(round(Int,p[5]), round(Int,p[6]))
    else
        ITVar.p_reference[2, corner_i] = CartesianIndex(0, 0)
    end
end


#############
#############
"""
    warpping!(Iout,Iin,x,y,M)

Iout:   returned warped image
Iin:    image to be warped
x:      derivatives kernel on x axis
y:      derivatives kernel on y axis
M:      affine matrix for template rotation and translation

Return a warped image
"""

function warpping!(Iout,Iin,x,y,M)
# Calculate the Transformed coordinates
Tlocalx =  M[1,1] .* x + M[1,2] .* y + M[1,3]
Tlocaly =  M[2,1] .* x + M[2,2] .* y + M[2,3]

# All the neighborh pixels involved in linear interpolation.
xBas0=floor(Integer, Tlocalx)
yBas0=floor(Integer, Tlocaly)

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

Iin_one=Iin[:,:]

# Get the intensities
intensity_xyz0=Iin_one[1 .+ xBas0 .+ yBas0*size(Iin,1)]
intensity_xyz1=Iin_one[1 .+ xBas0 .+ yBas1*size(Iin,1)]
intensity_xyz2=Iin_one[1 .+ xBas1 .+ yBas0*size(Iin,1)]
intensity_xyz3=Iin_one[1 .+ xBas1 .+ yBas1*size(Iin,1)]
Iout[:,:] = intensity_xyz0 .* perc0 + intensity_xyz1 .* perc1 + intensity_xyz2 .* perc2 + intensity_xyz3 .* perc3
# Iout[:,:]=reshape(Iout_one, size(x,1), size(x,2))

# end
return nothing
end

############
############
"""
    getApproxBestHarrisInWindow(image,[nfeatures=100, window = 9, k=0.04, stepguess=0.9, threshold = 1e-4])

Return the n best Harris features in a window
"""

function getApproxBestHarrisInWindow(iml;nfeatures=100, window = 9, k=0.04, stepguess=0.9,threshold = 1e-4)
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


##
