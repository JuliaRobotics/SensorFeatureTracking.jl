var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#SensorFeatureTracking.jl-1",
    "page": "Home",
    "title": "SensorFeatureTracking.jl",
    "category": "section",
    "text": "Feature Tracking Algorithms for Julia.Algorithms to track features of interest, such as KLT and Block Matching. Feature tracking with inertial sensor aiding, such as gyroscope aided feature tracking. Utilities to aid in alignment of camera and other sensors. Camera geomitry utilities such as camera models and projection."
},

{
    "location": "index.html#Package-Features-1",
    "page": "Home",
    "title": "Package Features",
    "category": "section",
    "text": "Tracking Algorithms\nFeature Detection\nIMU Tracking Utilities\nSupports Julia 0.6"
},

{
    "location": "index.html#Installing-1",
    "page": "Home",
    "title": "Installing",
    "category": "section",
    "text": "This is an unregistered Julia package, but can be readily installed from a Julia console:Pkg.clone(\"https://github.com/<YOURFORKEDREPO>/SensorFeatureTracking.jl.git\")Upstream master is at: https://github.com/dehann/SensorFeatureTracking.jl.git"
},

{
    "location": "index.html#Examples-1",
    "page": "Home",
    "title": "Examples",
    "category": "section",
    "text": "Please see, as part of the development, the examples folder.Please note this code is not yet optimized in any way. Performance can be improved."
},

{
    "location": "index.html#Manual-Outline-1",
    "page": "Home",
    "title": "Manual Outline",
    "category": "section",
    "text": "Pages = [\n    \"index.md\"\n    \"func_ref.md\"\n]"
},

{
    "location": "func_ref.html#",
    "page": "Functions",
    "title": "Functions",
    "category": "page",
    "text": ""
},

{
    "location": "func_ref.html#Function-Reference-1",
    "page": "Functions",
    "title": "Function Reference",
    "category": "section",
    "text": "Pages = [\n    \"func_ref.md\"\n]\nDepth = 3"
},

{
    "location": "func_ref.html#SensorFeatureTracking.drawfeatureLine!",
    "page": "Functions",
    "title": "SensorFeatureTracking.drawfeatureLine!",
    "category": "Function",
    "text": "drawfeatureLine!(image,feature1, feature2)\n\nDraw a line between 2 features.\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.drawfeatureX!",
    "page": "Functions",
    "title": "SensorFeatureTracking.drawfeatureX!",
    "category": "Function",
    "text": "drawfeatureX!(image,feature [,crosslength = 2])\n\nDraw a + on a feature.\n\nExamples\n\njulia> map(ft->drawfeatureX!(image, ft, length=5),features)\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.getApproxBestHarrisInWindow",
    "page": "Functions",
    "title": "SensorFeatureTracking.getApproxBestHarrisInWindow",
    "category": "Function",
    "text": "getApproxBestHarrisInWindow(image,[n=100, windowSize = 9, k=0.04, stepguess=0.4])\n\nReturn the n best Harris features in a window\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.getApproxBestShiTomasi",
    "page": "Functions",
    "title": "SensorFeatureTracking.getApproxBestShiTomasi",
    "category": "Function",
    "text": "getApproxBestShiTomasi(image,[n=100, windowSize = 9, k=0.04, stepguess=0.4, threshold = 1e-4])\n\nReturn the n aproxamate best Shi Tomasi features in a window\n\n\n\n"
},

{
    "location": "func_ref.html#Common-1",
    "page": "Functions",
    "title": "Common",
    "category": "section",
    "text": "drawfeatureLine!\ndrawfeatureX!\ngetApproxBestHarrisInWindow\ngetApproxBestShiTomasi"
},

{
    "location": "func_ref.html#SensorFeatureTracking.compute_sad",
    "page": "Functions",
    "title": "SensorFeatureTracking.compute_sad",
    "category": "Function",
    "text": "compute_sad(image1, image2, off1X, off1Y, off2X, off2Y, REGION_SIZE)\n\nCompute Sum of Absolute Differences of two regions with size REGION_SIZE.\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.compute_ssd",
    "page": "Functions",
    "title": "SensorFeatureTracking.compute_ssd",
    "category": "Function",
    "text": "compute_ssd(image1, image2, off1X, off1Y, off2X, off2Y, REGION_SIZE)\n\nCompute Sum of Squared Differences of two regions with REGION_SIZE.\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.compute_ncc",
    "page": "Functions",
    "title": "SensorFeatureTracking.compute_ncc",
    "category": "Function",
    "text": "compute_ncc(image1, image2, off1X, off1Y, off2X, off2Y, REGION_SIZE)\n\nCompute the normalized cross-correlation of two regions with size REGION_SIZE.\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.block_tracker!",
    "page": "Functions",
    "title": "SensorFeatureTracking.block_tracker!",
    "category": "Function",
    "text": "block_tracker(tracker::BlockTracker, image1, image2)\n\nTrack features between two images.\n\n\n\n"
},

{
    "location": "func_ref.html#Block-Matching-Feature-Tracking-1",
    "page": "Functions",
    "title": "Block Matching Feature Tracking",
    "category": "section",
    "text": "compute_sad\ncompute_ssd\ncompute_ncc\nblock_tracker!"
},

{
    "location": "func_ref.html#KLT-Feature-Tracking-1",
    "page": "Functions",
    "title": "KLT Feature Tracking",
    "category": "section",
    "text": "Forward and Inverse KLT tracking with pyramidsImageTrackerSetup\nfillNewImageTemplates!\nKTL_Tracker!\ntrackOneFeatureInversePyramid\ntrackOneFeatureInverse\ntrackOneFeaturePyramid\ntrackOneFeature\nwarping!"
},

{
    "location": "func_ref.html#SensorFeatureTracking.CameraModelandParameters",
    "page": "Functions",
    "title": "SensorFeatureTracking.CameraModelandParameters",
    "category": "Type",
    "text": "Data structure for a Camera model with parameters. Use CameraModel(width,height,fc,cc,skew,kc) for easy construction.\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.CameraModel",
    "page": "Functions",
    "title": "SensorFeatureTracking.CameraModel",
    "category": "Function",
    "text": "CameraModel(width,height,fc,cc,skew,kc)\n\nConstructor helper for creating a camera model.\n\n\n\n"
},

{
    "location": "func_ref.html#Camera-Models-and-Geometry-1",
    "page": "Functions",
    "title": "Camera Models and Geometry",
    "category": "section",
    "text": "CameraModelandParameters\nCameraModel"
},

{
    "location": "func_ref.html#SensorFeatureTracking.IMU_DATA",
    "page": "Functions",
    "title": "SensorFeatureTracking.IMU_DATA",
    "category": "Type",
    "text": "Data structure for holding time, gyroscope, and accelerometer data.\n\nFields\n\nutime – time [μs]\nacc   – accelerometer data\ngyro  – gyroscope data\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.estimateRotationFromKeypoints",
    "page": "Functions",
    "title": "SensorFeatureTracking.estimateRotationFromKeypoints",
    "category": "Function",
    "text": "estimateRotationFromKeypoints(points_a, points_b, cameraModel, [compensate = false])\n\nEstimate the rotation between 2 sets of Keypoints a and b using HornAbsoluteOrientation.\nIt is assumed that only possitive Keypoints are valid.\nSet compensate to true if rotaion should be around centre off image rather than 0,0\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.predictHomographyIMU!",
    "page": "Functions",
    "title": "SensorFeatureTracking.predictHomographyIMU!",
    "category": "Function",
    "text": "predictHomographyIMU!(index, current_time, vector_data, CameraK, CameraK_inverse)\n\nEstimate camera rotation from IMU data and compute predicted homography\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.integrateGyroBetweenFrames!",
    "page": "Functions",
    "title": "SensorFeatureTracking.integrateGyroBetweenFrames!",
    "category": "Function",
    "text": "integrateGyroBetweenFrames!(index, current_time, vector_data)\n\nEstimate rotations from IMU data between time stamps.\n\n\n\n"
},

{
    "location": "func_ref.html#SensorFeatureTracking.HornAbsoluteOrientation",
    "page": "Functions",
    "title": "SensorFeatureTracking.HornAbsoluteOrientation",
    "category": "Function",
    "text": "HornAbsoluteOrientation(a::Matrix{Float64},b::Matrix{Float64})\nHornAbsoluteOrientation(a::Vector{Vector{Float64}},b::Vector{Vector{Float64}})\n\nCompute the rotation between rows of (a and b)::Array{Float64,2}.\nRotate b into the frame of a\nReturns a quaternion, aQb\n\n\n\n"
},

{
    "location": "func_ref.html#Inertial-Sensor-Aided-Feature-Tracking-1",
    "page": "Functions",
    "title": "Inertial Sensor Aided Feature Tracking",
    "category": "section",
    "text": "IMU_DATA\nestimateRotationFromKeypoints\npredictHomographyIMU!\nintegrateGyroBetweenFrames!\nHornAbsoluteOrientation"
},

{
    "location": "func_ref.html#Index-1",
    "page": "Functions",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
