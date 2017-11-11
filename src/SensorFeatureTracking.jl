module SensorFeatureTracking

using Images, ImageView, ImageDraw, ImageFeatures, Gtk.ShortNames, VideoIO, ImageFiltering
using TransformUtils, CoordinateTransformations, StaticArrays

export
  # new functions written here
  topoint2d,
  getharriscorners,
  getapproxbestharris,
  drawfeaturecircle2d!,
  drawfeatureX!,
  drawfeatureLine!,
  getApproxBestHarrisInWindow,
  getApproxBestShiTomasi,


  # pass through functions from packages higher up in tree
  imshow,
  Gray,
  fastcorners,
  load,
  Keypoints,
  Feature,
  colorview,
  # from TransformUtils
  rotate,
  rotate!,

  # BlockMatching
  BlockTracker,
  compute_diff,
  compute_sad,
  compute_ssd,
  compute_ncc,
  block_tracker!,
  grid_features!,


  # Sensor and Camera Geometry Utilities
  IMU_DATA,
  PInt64,
  CameraModel,
  integrateGyroBetweenFrames!,
  estimateRotationFromKeypoints,
  predictHomographyIMU!,
  predictAffinity,
  HornAbsoluteOrientation

  # Tracking Algorithms
  ImageTrackerSetup,
  KTL_Tracker!,
  trackOneFeaturePyramid,
  trackOneFeature,
  warpping!
  

include("Common.jl")
include("BlockMatchingFlow.jl")
include("SensorCameraGeometryUtils.jl")
include("KLTTrackingAlgorithms.jl")



end
