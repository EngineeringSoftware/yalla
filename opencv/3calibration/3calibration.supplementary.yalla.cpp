#include "opencv2/calib3d.hpp"
#include "opencv2/core/utility.hpp"
#include "opencv2/highgui.hpp"
#include "opencv2/imgcodecs.hpp"
#include "opencv2/imgproc.hpp"

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <string>
#include <time.h>
#include <vector>

using namespace std;
using namespace cv;

template <typename T>
vector<vector<T>> convert_vector_of_vector_yalla(vector<vector<T *>> &v) {
  vector<vector<T>> result;
  for (auto &c : v) {
    vector<T> current;
    result.push_back(current);
    auto &current_ref = result.back();
    for (auto p : c) {
      current_ref.push_back(*p);
    }
  }

  return result;
}

template <typename T> vector<T> convert_vector_yalla(vector<T *> &v) {
  vector<T> result;
  for (auto c : v) {
    result.push_back(*c);
  }

  return result;
}

double yalla_calibrateCamera(vector<vector<Point3f *>> &a0,
                             vector<vector<Point2f *>> &a1, cv::Size *a2,
                             Mat *a3, Mat *a4, vector<Mat *> &a5,
                             vector<Mat *> &a6, int a7) {
  vector<vector<Point3f>> a0_inner = convert_vector_of_vector_yalla(a0);
  vector<vector<Point2f>> a1_inner = convert_vector_of_vector_yalla(a1);
  vector<Mat> a5_inner = convert_vector_yalla(a5);
  vector<Mat> a6_inner = convert_vector_yalla(a6);

  return calibrateCamera(a0_inner, a1_inner, *a2, *a3, *a4, a5_inner, a6_inner,
                         a7);
}

double yalla_stereoCalibrate(vector<vector<Point3f *>> &objectPoints,
                             vector<vector<Point2f *>> &imagePoints1,
                             vector<vector<Point2f *>> &imagePoints2,
                             Mat *cameraMatrix1, Mat *distCoeffs1,
                             Mat *cameraMatrix2, Mat *distCoeffs2,
                             Size *imageSize, Mat *R, Mat *T, Mat *E, Mat *F,
                             int flags, TermCriteria *criteria) {
  vector<vector<Point3f>> objectPointsInner =
      convert_vector_of_vector_yalla(objectPoints);
  vector<vector<Point2f>> imagePoints1Inner =
      convert_vector_of_vector_yalla(imagePoints1);
  vector<vector<Point2f>> imagePoints2Inner =
      convert_vector_of_vector_yalla(imagePoints2);
  return stereoCalibrate(objectPointsInner, imagePoints1Inner,
                         imagePoints2Inner, *cameraMatrix1, *distCoeffs1,
                         *cameraMatrix2, *distCoeffs2, *imageSize, *R, *T, *E,
                         *F, flags, *criteria);
}

bool yalla_findChessboardCorners(Mat *image_, Size *pattern_size,
                                 vector<Point2f *> &corners_, int flags) {
  vector<Point2f> _cornersInner = convert_vector_yalla(corners_);
  bool result =
      findChessboardCorners(*image_, *pattern_size, _cornersInner, flags);
  corners_.resize(_cornersInner.size());
  for (int i = 0; i < _cornersInner.size(); i++) {
    corners_[i] = new Point2f(_cornersInner[i]);
  }
  return result;
}

void yalla_drawChessboardCorners(Mat *m1, Size *s, Mat *m2, bool b) {
  return drawChessboardCorners(*m1, *s, *m2, b);
}

Mat *yalla_vectp2f_to_Mat(vector<Point2f *> &v) {
  vector<Point2f> vInner = convert_vector_yalla(v);
  return new Mat(vInner);
}

float yalla_rectify3Collinear(
    Mat *cameraMatrix1, Mat *distCoeffs1, Mat *cameraMatrix2, Mat *distCoeffs2,
    Mat *cameraMatrix3, Mat *distCoeffs3, vector<vector<Point2f *>> &imgpt1,
    vector<vector<Point2f *>> &imgpt3, Size *imageSize, Mat *R12, Mat *T12,
    Mat *R13, Mat *T13, Mat *R1, Mat *R2, Mat *R3, Mat *P1, Mat *P2, Mat *P3,
    Mat *Q, double alpha, Size *newImgSize, Rect *roi1, Rect *roi2, int flags) {
  vector<vector<Point2f>> imgpt1Inner = convert_vector_of_vector_yalla(imgpt1);
  vector<vector<Point2f>> imgpt3Inner = convert_vector_of_vector_yalla(imgpt3);

  return rectify3Collinear(*cameraMatrix1, *distCoeffs1, *cameraMatrix2,
                           *distCoeffs2, *cameraMatrix3, *distCoeffs3,
                           imgpt1Inner, imgpt3Inner, *imageSize, *R12, *T12,
                           *R13, *T13, *R1, *R2, *R3, *P1, *P2, *P3, *Q, alpha,
                           *newImgSize, roi1, roi2, flags);
}