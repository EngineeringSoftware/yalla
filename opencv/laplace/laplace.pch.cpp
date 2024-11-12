#include "laplace-all.h"
#include <ctype.h>
#include <stdio.h>
#include <iostream>

using namespace cv;
using namespace std;

static void help(char** argv)
{
    cout <<
            "\nThis program demonstrates Laplace point/edge detection using OpenCV function Laplacian()\n"
            "It captures from the camera of your choice: 0, 1, ... default 0\n"
            "Call:\n"
         <<  argv[0] << " -c=<camera #, default 0> -p=<index of the frame to be decoded/captured next>\n" << endl;
}

enum {GAUSSIAN, BLUR, MEDIAN};

int sigma = 3;
int smoothType = GAUSSIAN;

int main( int argc, char** argv )
{
    cv::CommandLineParser parser(argc, argv, "{ c | 0 | }{ p | | }");
    help(argv);

    VideoCapture cap;
    string camera = parser.get<string>("c");
    if (camera.size() == 1 && isdigit(camera[0])) {
        int temp = parser.get<int>("c");
    } else {
        String temp_string = samples::findFileOrKeep(camera);
        cap.open(temp_string);
    }

    unsigned temp_width_enum = cv::VideoCaptureProperties::CAP_PROP_FRAME_WIDTH;
    unsigned temp_height_enum = cv::VideoCaptureProperties::CAP_PROP_FRAME_HEIGHT;
    unsigned temp_nframes_enum = cv::VideoCaptureProperties::CAP_PROP_FRAME_COUNT;
    double temp_width = cap.get(temp_width_enum);
    double temp_height = cap.get(temp_height_enum);
    double temp_nframes = cap.get(temp_nframes_enum);
    cout << "Video " << parser.get<string>("c") <<
        ": width=" << temp_width <<
        ", height=" << temp_height <<
        ", nframes=" << temp_nframes << endl;
    int pos = 0;
    if (parser.has("p"))
    {
        pos = parser.get<int>("p");
    }
    if (!parser.check())
    {
        parser.printErrors();
        return -1;
    }

    if (pos != 0)
    {
        unsigned temp_pos_frames = cv::VideoCaptureProperties::CAP_PROP_POS_FRAMES;
        cout << "seeking to frame #" << pos << endl;
        if (!cap.set(temp_pos_frames, pos))
        {
            cerr << "ERROR: seekeing is not supported" << endl;
        }
    }

    unsigned autosize_temp = WINDOW_AUTOSIZE;

    Mat smoothed;
    Mat laplace;
    Mat result;

    for(;;)
    {
        Mat frame;
        cap >> frame;
        if( frame.empty() )
            break;

        int ksize = (sigma*5)|1;
        Size size_temp(ksize, ksize);
        InputArray frame_temp = frame;
        OutputArray smoothed_temp = smoothed;
        if(smoothType == GAUSSIAN)
            GaussianBlur(frame_temp, smoothed_temp, size_temp, sigma, sigma);
        else if(smoothType == BLUR)
            blur(frame_temp, smoothed_temp, size_temp);
        else
            medianBlur(frame_temp, smoothed_temp, ksize);
        
        InputArray input_temp_0 = smoothed;
        OutputArray output_temp_0 = laplace;
        Laplacian(input_temp_0, output_temp_0, CV_16S, 5);
        InputArray input_temp_1 = laplace;
        OutputArray output_temp_1 = result;
        convertScaleAbs(input_temp_1, output_temp_1, (sigma+1)*0.25);
        InputArray input_temp_2 = result;
        imshow("Laplacian", input_temp_2);

        char c = (char)waitKey(30);
        if( c == ' ' )
            smoothType = smoothType == GAUSSIAN ? BLUR : smoothType == BLUR ? MEDIAN : GAUSSIAN;
        if( c == 'q' || c == 'Q' || c == 27 )
            break;
    }

    return 0;
}
