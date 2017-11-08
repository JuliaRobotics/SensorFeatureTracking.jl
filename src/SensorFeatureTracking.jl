module SensorFeatureTracking

using Images, ImageView, ImageDraw, ImageFeatures, Gtk.ShortNames, VideoIO, ImageFiltering

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

  # BlockMatching
  BlockTracker,
  REGION_SIZE,
  compute_diff,
  compute_sad,
  compute_ssd,
  compute_ncc,
  block_tracker!,
  grid_features!,

  # Tracking Algorithms
  ImageTrackerSetup,
  KTL_Tracker!,
  trackOneFeaturePyramid,
  trackOneFeature,
  warpping!
  



include("Common.jl")
include("BlockMatchingFlow.jl")
include("KLTTrackingAlgorithms.jl")



end
