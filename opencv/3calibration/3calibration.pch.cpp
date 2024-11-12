/*
 * 3calibration.cpp -- Calibrate 3 cameras in a horizontal line together.
 */

#include "3calibration-all.h"

#include <stdio.h>
#include <string.h>
#include <time.h>

using namespace cv;
using namespace std;

enum { DETECTION = 0, CAPTURING = 1, CALIBRATED = 2 };

double yalla_calibrateCamera(vector<vector<Point3f*>>&, vector<vector<Point2f*>>&, cv::Size*, Mat* _cameraMatrix, Mat* _distCoeffs,
                            vector<Mat*>& _rvecs, vector<Mat*>& _tvecs, int flags);

double yalla_stereoCalibrate( vector<vector<Point3f*> >& objectPoints,
                                    vector<vector<Point2f*> >& imagePoints1, vector<vector<Point2f*> >& imagePoints2,
                                    Mat* cameraMatrix1, Mat* distCoeffs1,
                                    Mat* cameraMatrix2, Mat* distCoeffs2,
                                    Size* imageSize, Mat* R, Mat* T, Mat* E, Mat* F,
                                    int flags,
                                    TermCriteria* criteria);


bool yalla_findChessboardCorners(Mat* image_, Size* pattern_size,
                           vector<Point2f*>& corners_, int flags);

void yalla_drawChessboardCorners(Mat* m1, Size* s, Mat* m2, bool b);

Mat* yalla_vectp2f_to_Mat(vector<Point2f*>& v);

float yalla_rectify3Collinear( Mat* cameraMatrix1, Mat* distCoeffs1,
                                    Mat* cameraMatrix2, Mat* distCoeffs2,
                                    Mat* cameraMatrix3, Mat* distCoeffs3,
                                    vector<vector<Point2f*> >& imgpt1, vector<vector<Point2f*> >& imgpt3,
                                    Size* imageSize, Mat* R12, Mat* T12,
                                    Mat* R13, Mat* T13,
                                    Mat* R1, Mat* R2, Mat* R3,
                                    Mat* P1, Mat* P2, Mat* P3,
                                    Mat* Q, double alpha, Size* newImgSize,
                                    Rect* roi1, Rect* roi2, int flags );

static void help(char** argv)
{
        printf( "\nThis is a camera calibration sample that calibrates 3 horizontally placed cameras together.\n"
               "Usage: %s\n"
               "     -w=<board_width>         # the number of inner corners per one of board dimension\n"
               "     -h=<board_height>        # the number of inner corners per another board dimension\n"
               "     [-s=<squareSize>]       # square size in some user-defined units (1 by default)\n"
               "     [-o=<out_camera_params>] # the output filename for intrinsic [and extrinsic] parameters\n"
               "     [-zt]                    # assume zero tangential distortion\n"
               "     [-a=<aspectRatio>]      # fix aspect ratio (fx/fy)\n"
               "     [-p]                     # fix the principal point at the center\n"
               "     [input_data]             # input data - text file with a list of the images of the board\n"
               "\n", argv[0] );

}

static void calcChessboardCorners(Size boardSize, float squareSize, vector<Point3f*>& corners)
{
    corners.resize(0);

    for( int i = 0; i < boardSize.height; i++ ) {
        for( int j = 0; j < boardSize.width; j++ ) {
            Point3f* temp = new Point3f(float(j*squareSize), float(i*squareSize), 0);
            corners.push_back(temp);
        }
    }
}

static bool run3Calibration(vector<vector<Point2f*> > imagePoints1,
                            vector<vector<Point2f*> > imagePoints2,
                            vector<vector<Point2f*> > imagePoints3,
                            Size imageSize, Size boardSize,
                            float squareSize, float aspectRatio,
                            int flags,
                            Mat& cameraMatrix1, Mat& distCoeffs1,
                            Mat& cameraMatrix2, Mat& distCoeffs2,
                            Mat& cameraMatrix3, Mat& distCoeffs3,
                            Mat& R12, Mat& T12, Mat& R13, Mat& T13)
{
    int c, i;

    // step 1: calibrate each camera individually
    vector<vector<Point3f*> > objpt(1);
    vector<vector<Point2f*> > imgpt;
    calcChessboardCorners(boardSize, squareSize, objpt[0]);
    vector<Mat*> rvecs, tvecs;

    for( c = 1; c <= 3; c++ )
    {
        const vector<vector<Point2f*> >& imgpt0 = c == 1 ? imagePoints1 : c == 2 ? imagePoints2 : imagePoints3;
        imgpt.clear();
        int N = 0;
        for( i = 0; i < (int)imgpt0.size(); i++ ) {
            bool is_empty_arg = imgpt0[i].empty();
            if( !is_empty_arg )
            {
                imgpt.push_back(imgpt0[i]);
                unsigned long size_temp = imgpt0[i].size();
                N += (int)size_temp;
            }
        }

        if( imgpt.size() < 3 )
        {
            printf("Error: not enough views for camera %d\n", c);
            return false;
        }

        objpt.resize(imgpt.size(),objpt[0]);

        MatExpr eye_temp = Mat::eye(3, 3, CV_64F);
        Mat cameraMatrix = eye_temp;
        if( flags & CALIB_FIX_ASPECT_RATIO )
            cameraMatrix.at<double>(0,0) = aspectRatio;

        MatExpr zeros_temp = Mat::zeros(5, 1, CV_64F);
        Mat distCoeffs = zeros_temp;

        auto enum_temp = CALIB_FIX_K3;
        // cv::InputArray arg0 = objpt;
        // cv::InputArray arg1 = imgpt;
        // cv::InputOutputArray arg3 = cameraMatrix;
        // cv::InputOutputArray arg4 = distCoeffs;
        // cv::OutputArray arg5 = rvecs;
        // cv::OutputArray arg6 = tvecs;
        // double err = calibrateCamera(arg0, arg1, imageSize, arg3,
        //                 arg4, arg5, arg6,
        //                 flags|enum_temp/*|CALIB_FIX_K4|CALIB_FIX_K5|CALIB_FIX_K6*/);
        // double err = calibrateCamera(objpt, imgpt, imageSize, cameraMatrix,
        //                 distCoeffs, rvecs, tvecs,
        //                 flags|enum_temp/*|CALIB_FIX_K4|CALIB_FIX_K5|CALIB_FIX_K6*/);
        double err = yalla_calibrateCamera(objpt, imgpt, &imageSize, &cameraMatrix,
                        &distCoeffs, rvecs, tvecs,
                        flags|enum_temp/*|CALIB_FIX_K4|CALIB_FIX_K5|CALIB_FIX_K6*/);
        cv::InputArray second_arg0 = cameraMatrix;
        cv::InputArray second_arg1 = distCoeffs;
        bool ok = checkRange(second_arg0) && checkRange(second_arg1);
        if(!ok)
        {
            printf("Error: camera %d was not calibrated\n", c);
            return false;
        }
        printf("Camera %d calibration reprojection error = %g\n", c, sqrt(err/N));

        if( c == 1 )
            cameraMatrix1 = cameraMatrix, distCoeffs1 = distCoeffs;
        else if( c == 2 )
            cameraMatrix2 = cameraMatrix, distCoeffs2 = distCoeffs;
        else
            cameraMatrix3 = cameraMatrix, distCoeffs3 = distCoeffs;
    }

    vector<vector<Point2f*> > imgpt_right;

    // step 2: calibrate (1,2) and (3,2) pairs
    for( c = 2; c <= 3; c++ )
    {
        const vector<vector<Point2f*> >& imgpt0 = c == 2 ? imagePoints2 : imagePoints3;

        imgpt.clear();
        imgpt_right.clear();
        int N = 0;

        for( i = 0; i < (int)std::min(imagePoints1.size(), imgpt0.size()); i++ )
            bool imagePoints1_empty = imagePoints1.empty();
            bool imgpt0_empty = imgpt0[i].empty();
            if( !imagePoints1.empty() && !imgpt0_empty )
            {
                imgpt.push_back(imagePoints1[i]);
                imgpt_right.push_back(imgpt0[i]);
                unsigned long size_temp = imgpt0[i].size();
                N += (int)size_temp;
            }

        unsigned long imgpt_size = imgpt.size();
        if( imgpt_size < 3 )
        {
            printf("Error: not enough shared views for cameras 1 and %d\n", c);
            return false;
        }

        objpt.resize(imgpt_size,objpt[0]);
        Mat cameraMatrix = c == 2 ? cameraMatrix2 : cameraMatrix3;
        Mat distCoeffs = c == 2 ? distCoeffs2 : distCoeffs3;
        Mat R;
        Mat T;
        Mat E;
        Mat F;
        auto enum_temp2 = CALIB_FIX_INTRINSIC;
        auto term_temp = TermCriteria::COUNT;

        // cv::InputArray arg0 = objpt;
        // cv::InputArray arg1 = imgpt;
        // cv::InputArray arg2 = imgpt_right;
        // cv::InputOutputArray arg3 = cameraMatrix1;
        // cv::InputOutputArray arg4 = distCoeffs1;
        // cv::InputOutputArray arg5 = cameraMatrix;
        // cv::InputOutputArray arg6 = distCoeffs;
        // cv::OutputArray arg8 = R;
        // cv::OutputArray arg9 = T;
        // cv::OutputArray arg10 = E;
        // cv::OutputArray arg11 = F;
        cv::TermCriteria temp_criteria(term_temp, 30, 0);

        // double err = stereoCalibrate(arg0, arg1, arg2, arg3, arg4,
        //                              arg5, arg6,
        //                              imageSize, arg8, arg9, arg10, arg11,
        //                              enum_temp2,
        //                              temp_criteria);
        // double err = stereoCalibrate(objpt, imgpt, imgpt_right, cameraMatrix1, distCoeffs1,
        //                              cameraMatrix, distCoeffs,
        //                              imageSize, R, T, E, F,
        //                              CALIB_FIX_INTRINSIC,
        //                              TermCriteria(TermCriteria::COUNT, 30, 0));
        double err = yalla_stereoCalibrate(objpt, imgpt, imgpt_right, &cameraMatrix1, &distCoeffs1,
                                     &cameraMatrix, &distCoeffs,
                                     &imageSize, &R, &T, &E, &F,
                                     enum_temp2,
                                     &temp_criteria);
        printf("Pair (1,%d) calibration reprojection error = %g\n", c, sqrt(err/(N*2)));
        if( c == 2 )
        {
            cameraMatrix2 = cameraMatrix;
            distCoeffs2 = distCoeffs;
            R12 = R; T12 = T;
        }
        else
        {
            R13 = R; T13 = T;
        }
    }

    return true;
}

static bool readStringList( const string& filename, vector<string>& l )
{
    l.resize(0);
    auto temp = FileStorage::READ;
    std::string empty_string = "";

    FileStorage fs(filename, temp, empty_string);
    if( !fs.isOpened() )
        return false;
    FileNode n = fs.getFirstTopLevelNode();
    if( n.type() != FileNode::SEQ )
        return false;
    FileNodeIterator it = n.begin();
    FileNodeIterator it_end = n.end();
    for( ; it != it_end; ++it ) {
        auto temp = *it;
        std::string temp2 = (string)temp;
        l.push_back(temp2);
    }
    return true;
}


int main( int argc, char** argv )
{
    int i, k;
    int flags = 0;
    Size boardSize;
    Size imageSize;
    float squareSize, aspectRatio;
    string outputFilename;
    string inputFilename = "";

    vector<vector<Point2f*> > imgpt[3];
    vector<string> imageList;

    cv::CommandLineParser parser(argc, argv,
        "{help ||}{w||}{h||}{s|1|}{o|out_camera_data.yml|}"
        "{zt||}{a|1|}{p||}{@input||}");
    if (parser.has("help"))
    {
        help(argv);
        return 0;
    }

    int width_temp = parser.get<int>("w");
    int height_temp = parser.get<int>("h");

    boardSize.width = width_temp;
    boardSize.height = height_temp;
    squareSize = parser.get<float>("s");
    aspectRatio = parser.get<float>("a");
    if (parser.has("a"))
        flags |= CALIB_FIX_ASPECT_RATIO;
    if (parser.has("zt"))
        flags |= CALIB_ZERO_TANGENT_DIST;
    if (parser.has("p"))
        flags |= CALIB_FIX_PRINCIPAL_POINT;
    outputFilename = parser.get<string>("o");
    inputFilename = parser.get<string>("@input");
    if (!parser.check())
    {
        help(argv);
        parser.printErrors();
        return -1;
    }
    if (boardSize.width <= 0)
        return fprintf( stderr, "Invalid board width\n" ), -1;
    if (boardSize.height <= 0)
        return fprintf( stderr, "Invalid board height\n" ), -1;
    if (squareSize <= 0)
        return fprintf( stderr, "Invalid board square width\n" ), -1;
    if (aspectRatio <= 0)
        return printf("Invalid aspect ratio\n" ), -1;
    if( inputFilename.empty() ||
       !readStringList(inputFilename, imageList) ||
       imageList.size() == 0 || imageList.size() % 3 != 0 )
    {
        printf("Error: the input image list is not specified, or can not be read, or the number of files is not divisible by 3\n");
        return -1;
    }

    Mat view;
    Mat viewGray;
    // Mat cameraMatrix[3];
    Mat cameraMatrix_0;
    Mat cameraMatrix_1;
    Mat cameraMatrix_2;
    // Mat distCoeffs[3];
    Mat distCoeffs_0;
    Mat distCoeffs_1;
    Mat distCoeffs_2;
    // Mat R[3];
    Mat R_0;
    Mat R_1;
    Mat R_2;
    // Mat P[3];
    Mat P_0;
    Mat P_1;
    Mat P_2;
    Mat R12;
    Mat T12;
    // for( k = 0; k < 3; k++ )
    {
        MatExpr temp = Mat_<double>::eye(3,3);
        cameraMatrix_0 = temp;
        cameraMatrix_0.at<double>(0,0) = aspectRatio;
        cameraMatrix_0.at<double>(1,1) = 1;
        MatExpr temp2 = Mat_<double>::zeros(5,1);
        distCoeffs_0 = temp2;

        MatExpr temp_1 = Mat_<double>::eye(3,3);
        cameraMatrix_1 = temp_1;
        cameraMatrix_1.at<double>(0,0) = aspectRatio;
        cameraMatrix_1.at<double>(1,1) = 1;
        MatExpr temp2_1 = Mat_<double>::zeros(5,1);
        distCoeffs_1 = temp2;

        MatExpr temp_2 = Mat_<double>::eye(3,3);
        cameraMatrix_2 = temp;
        cameraMatrix_2.at<double>(0,0) = aspectRatio;
        cameraMatrix_2.at<double>(1,1) = 1;
        MatExpr temp2_2 = Mat_<double>::zeros(5,1);
        distCoeffs_2 = temp2;
    }
    MatExpr temp3 = Mat_<double>::eye(3,3);
    MatExpr temp4 = Mat_<double>::zeros(3,1);
    Mat R13=temp3;
    Mat T13=temp4;

    FileStorage fs;
    // namedWindow( "Image View", 0 );

    for( k = 0; k < 3; k++ )
        imgpt[k].resize(imageList.size()/3);

    for( i = 0; i < (int)(imageList.size()/3); i++ )
    {
        for( k = 0; k < 3; k++ )
            {
            int k1 = k == 0 ? 2 : k == 1 ? 0 : 1;
            printf("%s\n", imageList[i*3+k].c_str());
            int imread_temp_enum = cv::IMREAD_COLOR;
            Mat imread_temp = imread(imageList[i*3+k], imread_temp_enum);
            view = imread_temp;

            if(!view.empty())
            {
                // Some issues with replacement
                vector<Point2f*> ptvec;
                cv::MatSize* temp0 = &(view.size);
                cv::Size temp = temp0->operator()();
                // imageSize = temp0->operator()();
                imageSize = temp;
                // cv::Size s = view.size();
                // imageSize = s;
                unsigned int enum_temp_bgr = COLOR_BGR2GRAY;
                cv::InputArray cvt_arg0 = view;
                cv::OutputArray cvt_arg1 = viewGray;
                cvtColor(cvt_arg0, cvt_arg1, enum_temp_bgr);
                auto calib_temp = CALIB_CB_ADAPTIVE_THRESH;
                // cv::InputArray chess_arg0 = view;
                // cv::OutputArray chess_arg2 = ptvec;
                // bool found = findChessboardCorners( chess_arg0, boardSize, chess_arg2, calib_temp );
                // bool found = findChessboardCorners( view, boardSize, ptvec, CALIB_CB_ADAPTIVE_THRESH );
                bool found = yalla_findChessboardCorners( &view, &boardSize, ptvec, calib_temp);

                Mat* ptvec_temp = yalla_vectp2f_to_Mat(ptvec);
                // cv::InputOutputArray chess2_arg0 = view;
                // cv::InputArray chess2_arg2 = ptvec;
                // drawChessboardCorners( chess2_arg0, boardSize, chess2_arg2, found );
                // drawChessboardCorners( view, boardSize, Mat(ptvec), found );
                yalla_drawChessboardCorners(&view, &boardSize, ptvec_temp, found);
                if( found )
                {
                    unsigned long size_temp = ptvec.size();
                    imgpt[k1][i].resize(size_temp);
                    std::copy(ptvec.begin(), ptvec.end(), imgpt[k1][i].begin());
                }
                //imshow("view", view);
                //int c = waitKey(0) & 255;
                //if( c == 27 || c == 'q' || c == 'Q' )
                //    return -1;
            }
        }
    }

    printf("Running calibration ...\n");

    run3Calibration(imgpt[0], imgpt[1], imgpt[2], imageSize,
                    boardSize, squareSize, aspectRatio, flags|CALIB_FIX_K4|CALIB_FIX_K5,
                    cameraMatrix_0, distCoeffs_0,
                    cameraMatrix_1, distCoeffs_1,
                    cameraMatrix_2, distCoeffs_2,
                    R12, T12, R13, T13);

    auto temp = FileStorage::WRITE;
    std::string empty_string = "";
    fs.open(outputFilename, temp, empty_string);

    fs << "cameraMatrix1";
    fs << cameraMatrix_0;
    fs << "cameraMatrix2";
    fs << cameraMatrix_1;
    fs << "cameraMatrix3";
    fs << cameraMatrix_2;

    fs << "distCoeffs1";
    fs << distCoeffs_0;
    fs << "distCoeffs2";
    fs << distCoeffs_1;
    fs << "distCoeffs3";
    fs << distCoeffs_2;

    fs << "R12";
    fs << R12;
    fs << "T12";
    fs << T12;
    fs << "R13";
    fs << R13;
    fs << "T13";
    fs << T13;

    width_temp = imageSize.width;
    height_temp = imageSize.height;
    fs << "imageWidth";
    fs << width_temp;
    fs << "imageHeight";
    fs << height_temp;

    Mat Q;

    auto here_temp =  CALIB_ZERO_DISPARITY;
    // step 3: find rectification transforms
    cv::Rect_<int>* roi1_temp = 0;
    cv::Rect_<int>* roi2_temp = 0;

    // cv::InputArray rectify_arg0 = cameraMatrix_0;
    // cv::InputArray rectify_arg1 = distCoeffs_0;
    // cv::InputArray rectify_arg2 = cameraMatrix_1;
    // cv::InputArray rectify_arg3 = distCoeffs_1;
    // cv::InputArray rectify_arg4 = cameraMatrix_2;
    // cv::InputArray rectify_arg5 = distCoeffs_2;

    // cv::InputOutputArray rectify_arg6 = imgpt[0];
    // cv::InputOutputArray rectify_arg7 = imgpt[2];

    // cv::InputArray rectify_arg8 = R12;
    // cv::InputArray rectify_arg9 = T12;
    // cv::InputArray rectify_arg10 = R13;
    // cv::InputArray rectify_arg11 = T13;
    // cv::OutputArray rectify_arg12 = R_0;
    // cv::OutputArray rectify_arg13 = R_1;
    // cv::OutputArray rectify_arg14 = R_2;
    // cv::OutputArray rectify_arg15 = P_0;
    // cv::OutputArray rectify_arg16 = P_1;
    // cv::OutputArray rectify_arg17 = P_2;
    // cv::OutputArray rectify_arg18 = Q;

    // cv::InputArrayOfArrays rectify_arg19 = imgpt[0];
    // cv::InputArrayOfArrays rectify_arg20 = imgpt[2];

    // double ratio = rectify3Collinear(rectify_arg0, rectify_arg1, rectify_arg2,
    //          rectify_arg3, rectify_arg4, rectify_arg5,
    //          rectify_arg19, rectify_arg20,
    //          imageSize, rectify_arg8, rectify_arg9, rectify_arg10, rectify_arg11,
    //          rectify_arg12, rectify_arg13, rectify_arg14, rectify_arg15, rectify_arg16, rectify_arg17, rectify_arg18, -1.,
    //          imageSize, roi1_temp, roi2_temp, here_temp);
    // double ratio = rectify3Collinear(cameraMatrix[0], distCoeffs[0], cameraMatrix[1],
    //          distCoeffs[1], cameraMatrix[2], distCoeffs[2],
    //          imgpt[0], imgpt[2],
    //          imageSize, R12, T12, R13, T13,
    //          R[0], R[1], R[2], P[0], P[1], P[2], Q, -1.,
    //          imageSize, 0, 0, CALIB_ZERO_DISPARITY);
    double ratio = yalla_rectify3Collinear(&cameraMatrix_0, &distCoeffs_0, &cameraMatrix_1,
             &distCoeffs_1, &cameraMatrix_2, &distCoeffs_2,
             imgpt[0], imgpt[2],
             &imageSize, &R12, &T12, &R13, &T13,
             &R_0, &R_1, &R_2, &P_0, &P_1, &P_2, &Q, -1.,
             &imageSize, 0, 0, here_temp);

    Mat map1_0;
    Mat map1_1;
    Mat map1_2;
    Mat map2_0;
    Mat map2_1;
    Mat map2_2;

    fs << "R1";
    fs << R_0;
    fs << "R2";
    fs << R_1;
    fs << "R3";
    fs << R_2;

    fs << "P1";
    fs << P_0;
    fs << "P2";
    fs << P_1;
    fs << "P3";
    fs << P_2;

    fs << "disparityRatio";
    fs << ratio;
    fs.release();

    printf("Disparity ratio = %g\n", ratio);

    cv::InputArray undistort0_arg0 = cameraMatrix_0; 
    cv::InputArray undistort0_arg1 = distCoeffs_0;
    cv::InputArray undistort0_arg2 = R_0;
    cv::InputArray undistort0_arg3 = P_0;
    cv::OutputArray undistort0_arg5 = map1_0;
    cv::OutputArray undistort0_arg6 = map2_0;
    initUndistortRectifyMap(undistort0_arg0, undistort0_arg1, undistort0_arg2, undistort0_arg3, imageSize, CV_16SC2, undistort0_arg5, undistort0_arg6);

    cv::InputArray undistort1_arg0 = cameraMatrix_1;
    cv::InputArray undistort1_arg1 = distCoeffs_1;
    cv::InputArray undistort1_arg2 = R_1;
    cv::InputArray undistort1_arg3 = P_1;
    cv::OutputArray undistort1_arg5 = map1_1;
    cv::OutputArray undistort1_arg6 = map2_1;
    initUndistortRectifyMap(undistort1_arg0, undistort1_arg1, undistort1_arg2, undistort1_arg3, imageSize, CV_16SC2, undistort1_arg5, undistort1_arg6);

    cv::InputArray undistort2_arg0 = cameraMatrix_2;
    cv::InputArray undistort2_arg1 = distCoeffs_2;
    cv::InputArray undistort2_arg2 = R_2;
    cv::InputArray undistort2_arg3 = P_2;
    cv::OutputArray undistort2_arg5 = map1_2;
    cv::OutputArray undistort2_arg6 = map2_2;
    initUndistortRectifyMap(undistort2_arg0, undistort2_arg1, undistort2_arg2, undistort2_arg3, imageSize, CV_16SC2, undistort2_arg5, undistort2_arg6);

    width_temp = imageSize.width;
    height_temp = imageSize.height;
    Mat canvas(height_temp, width_temp*3, CV_8UC3);
    Mat small_canvas;
    // destroyWindow("view");
    Scalar scalar_temp = Scalar::all(0);
    canvas = scalar_temp;

    for( i = 0; i < (int)(imageList.size()/3); i++ )
    {
        Scalar scalar_temp = Scalar::all(0);
        canvas = scalar_temp;
        // for( k = 0; k < 3; k++ )
        {
            k = 0;
            int k1 = k == 0 ? 2 : k == 1 ? 0 : 1;
            int k2 = k == 0 ? 1 : k == 1 ? 0 : 2;
            auto temp = cv::IMREAD_COLOR;
            Mat imread_temp = imread(imageList[i*3+k], temp);
            view = imread_temp;

            bool is_empty_0 = view.empty();

            if(!is_empty_0) {
                width_temp = imageSize.width;
                height_temp = imageSize.height;

                Mat rview = canvas.colRange(k2*width_temp, (k2+1)*width_temp);
                auto inter_temp = INTER_LINEAR;

                cv::InputArray remap_arg0 = view;
                cv::OutputArray remap_arg1 = rview;
                cv::InputArray remap_arg2 = map1_0;
                cv::InputArray remap_arg3 = map2_0;

                remap(remap_arg0, remap_arg1, remap_arg2, remap_arg3, inter_temp);
            }

            k = 1;
            k1 = k == 0 ? 2 : k == 1 ? 0 : 1;
            k2 = k == 0 ? 1 : k == 1 ? 0 : 2;
            auto temp2 = cv::IMREAD_COLOR;
            Mat imread_temp2 = imread(imageList[i*3+k], temp2);
            view = imread_temp2;

            if(!view.empty()) {
                width_temp = imageSize.width;
                height_temp = imageSize.height;

                Mat rview = canvas.colRange(k2*width_temp, (k2+1)*width_temp);
                auto inter_temp = INTER_LINEAR;

                cv::InputArray remap_arg0 = view;
                cv::OutputArray remap_arg1 = rview;
                cv::InputArray remap_arg2 = map1_1;
                cv::InputArray remap_arg3 = map2_1;

                remap(remap_arg0, remap_arg1, remap_arg2, remap_arg3, inter_temp);
            }

            k = 2;
            k1 = k == 0 ? 2 : k == 1 ? 0 : 1;
            k2 = k == 0 ? 1 : k == 1 ? 0 : 2;
            auto temp3 = cv::IMREAD_COLOR;
            Mat imread_temp3 = imread(imageList[i*3+k], temp3);
            view = imread_temp3;

            if(!view.empty()) {
                width_temp = imageSize.width;
                height_temp = imageSize.height;

                Mat rview = canvas.colRange(k2*width_temp, (k2+1)*width_temp);
                auto inter_temp = INTER_LINEAR;

                cv::InputArray remap_arg0 = view;
                cv::OutputArray remap_arg1 = rview;
                cv::InputArray remap_arg2 = map1_2;
                cv::InputArray remap_arg3 = map2_2;

                remap(remap_arg0, remap_arg1, remap_arg2, remap_arg3, inter_temp);
            }
        }
        printf("%s %s %s\n", imageList[i*3].c_str(), imageList[i*3+1].c_str(), imageList[i*3+2].c_str());
        auto inter_temp = INTER_LINEAR_EXACT;

        cv::InputArray resize_arg0 = canvas;
        cv::OutputArray resize_arg1 = small_canvas;
        Size resize_arg2(1500, 1500/3);
        resize( resize_arg0, resize_arg1, resize_arg2, 0, 0, inter_temp );

        int cols_temp = small_canvas.cols;
        for( k = 0; k < small_canvas.rows; k += 16 ) {
            Point p0(0, k);
            Point p1(cols_temp, k);
            Scalar p2(0, 255, 0);

            cv::InputOutputArray line_arg0 = small_canvas;
            line(line_arg0, p0, p1, p2, 1);
        }

        cv::InputArray imshow_arg1 = small_canvas;
        // imshow("rectified", imshow_arg1);
        // char c = (char)waitKey(0);
        // if( c == 27 || c == 'q' || c == 'Q' )
        //     break;
    }

    return 0;
}
