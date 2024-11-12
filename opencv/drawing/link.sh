BUILD_DIR=$1

clang++ -Wl,--gc-sections -Wl,--as-needed -Wl,--no-undefined *.o -o a.out  \
  -Wl,-rpath,{BUILD_DIR}/lib  -ldl  -lm  -lpthread  -lrt  ${BUILD_DIR}/3rdparty/lib/libippiw.a \
   ${BUILD_DIR}/3rdparty/ippicv/ippicv_lnx/icv/lib/intel64/libippicv.a ${BUILD_DIR}/lib/libopencv_gapi.so.4.10.0 ${BUILD_DIR}/lib/libopencv_highgui.so.410 \
   ${BUILD_DIR}/lib/libopencv_ml.so.4.10.0 ${BUILD_DIR}/lib/libopencv_objdetect.so.4.10.0 ${BUILD_DIR}/lib/libopencv_photo.so.4.10.0 \
   ${BUILD_DIR}/lib/libopencv_stitching.so.4.10.0 ${BUILD_DIR}/lib/libopencv_video.so.4.10.0 ${BUILD_DIR}/lib/libopencv_videoio.so.4.10.0 \
   ${BUILD_DIR}/lib/libopencv_imgcodecs.so.4.10.0 ${BUILD_DIR}/lib/libopencv_calib3d.so.4.10.0 ${BUILD_DIR}/lib/libopencv_features2d.so.4.10.0 \
   ${BUILD_DIR}/lib/libopencv_flann.so.4.10.0 ${BUILD_DIR}/lib/libopencv_dnn.so.4.10.0 ${BUILD_DIR}/lib/libopencv_imgproc.so.4.10.0 \
   ${BUILD_DIR}/lib/libopencv_core.so.4.10.0