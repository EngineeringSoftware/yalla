#include "opencv2/core.hpp"
#include "opencv2/imgproc.hpp"
#include "opencv2/highgui.hpp"
#include <stdio.h>

using namespace cv;

static void help(char** argv)
{
    printf("\nThis program demonstrates OpenCV drawing and text output functions.\n"
    "Usage:\n"
    "   %s\n", argv[0]);
}
static Scalar_<double> randomColor(RNG& rng)
{
    int icolor = (unsigned)rng;
    return Scalar_<double>(icolor&255, (icolor>>8)&255, (icolor>>16)&255);
}

int main(int /* argc */, char** argv)
{
    help(argv);
    char wndname[] = "Drawing Demo";
    const int NUMBER = 100;
    const int DELAY = 5;
    int lineType = LINE_AA; // change it to LINE_8 to see non-antialiased graphics
    int i, width = 1000, height = 700;
    int x1 = -width/2, x2 = width*3/2, y1 = -height/2, y2 = height*3/2;
    RNG rng(0xFFFFFFFF);

    MatExpr zeros_temp = Mat::zeros(height, width, CV_8UC3);
    Mat image = zeros_temp;
    InputArray image_input_temp = image;

    for (i = 0; i < NUMBER * 2; i++)
    {
        Point pt1;
        Point pt2;
        pt1.x = rng.uniform(x1, x2);
        pt1.y = rng.uniform(y1, y2);
        pt2.x = rng.uniform(x1, x2);
        pt2.y = rng.uniform(y1, y2);

        int arrowed = rng.uniform(0, 6);
        int uniform_temp = rng.uniform(1, 10);

        if( arrowed < 3 ) {
            InputOutputArray image_inputoutput_temp = image;
            line( image_inputoutput_temp, pt1, pt2, randomColor(rng), uniform_temp, lineType );
        } else {
            InputOutputArray image_inputoutput_temp = image;
            arrowedLine(image_inputoutput_temp, pt1, pt2, randomColor(rng), uniform_temp, lineType);
        }
    }

    for (i = 0; i < NUMBER * 2; i++)
    {
        Point pt1;
        Point pt2;
        pt1.x = rng.uniform(x1, x2);
        pt1.y = rng.uniform(y1, y2);
        pt2.x = rng.uniform(x1, x2);
        pt2.y = rng.uniform(y1, y2);
        int thickness = rng.uniform(-3, 10);
        int marker = rng.uniform(0, 10);
        int marker_size = rng.uniform(30, 80);

        InputOutputArray image_io_temp = image;
        if (marker > 5)
            rectangle(image_io_temp, pt1, pt2, randomColor(rng), MAX(thickness, -1), lineType);
        else
            drawMarker(image_io_temp, pt1, randomColor(rng), marker, marker_size );
    }

    for (i = 0; i < NUMBER; i++)
    {
        Point center;
        center.x = rng.uniform(x1, x2);
        center.y = rng.uniform(y1, y2);
        Size axes;
        axes.width = rng.uniform(0, 200);
        axes.height = rng.uniform(0, 200);
        double angle = rng.uniform(0, 180);

        int uniform_temp = rng.uniform(-1, 9);
        InputOutputArray image_io_temp = image;
        ellipse( image_io_temp, center, axes, angle, angle - 100, angle + 200,
                 randomColor(rng), uniform_temp, lineType );
    }

    for (i = 0; i< NUMBER; i++)
    {
        Point pt_0_0;
        Point pt_0_1;
        Point pt_0_2;
        Point pt_1_0;
        Point pt_1_1;
        Point pt_1_2;
        pt_0_0.x = rng.uniform(x1, x2);
        pt_0_0.y = rng.uniform(y1, y2);
        pt_0_1.x = rng.uniform(x1, x2);
        pt_0_1.y = rng.uniform(y1, y2);
        pt_0_2.x = rng.uniform(x1, x2);
        pt_0_2.y = rng.uniform(y1, y2);
        pt_1_0.x = rng.uniform(x1, x2);
        pt_1_0.y = rng.uniform(y1, y2);
        pt_1_1.x = rng.uniform(x1, x2);
        pt_1_1.y = rng.uniform(y1, y2);
        pt_1_2.x = rng.uniform(x1, x2);
        pt_1_2.y = rng.uniform(y1, y2);
        const Point* ppt_0[3] = {&pt_0_0, &pt_0_1, &pt_0_2};
        const Point* ppt_1[3] = {&pt_1_0, &pt_1_1, &pt_1_2};
        const Point** ppt_temp[2] = {ppt_0, ppt_1};
        int npt[] = {3, 3};

        InputOutputArray image_io_temp = image;
        int uniform_temp = rng.uniform(1,10);
        polylines(image_io_temp, *ppt_temp, npt, 2, true, randomColor(rng), uniform_temp, lineType);
    }

    for (i = 0; i< NUMBER; i++)
    {
        Point pt_0_0;
        Point pt_0_1;
        Point pt_0_2;
        Point pt_1_0;
        Point pt_1_1;
        Point pt_1_2;
        pt_0_0.x = rng.uniform(x1, x2);
        pt_0_0.y = rng.uniform(y1, y2);
        pt_0_1.x = rng.uniform(x1, x2);
        pt_0_1.y = rng.uniform(y1, y2);
        pt_0_2.x = rng.uniform(x1, x2);
        pt_0_2.y = rng.uniform(y1, y2);
        pt_1_0.x = rng.uniform(x1, x2);
        pt_1_0.y = rng.uniform(y1, y2);
        pt_1_1.x = rng.uniform(x1, x2);
        pt_1_1.y = rng.uniform(y1, y2);
        pt_1_2.x = rng.uniform(x1, x2);
        pt_1_2.y = rng.uniform(y1, y2);
        const Point* ppt_0[3] = {&pt_0_0, &pt_0_1, &pt_0_2};
        const Point* ppt_1[3] = {&pt_1_0, &pt_1_1, &pt_1_2};
        const Point** ppt_temp[2] = {ppt_0, ppt_1};
        int npt[] = {3, 3};

        InputOutputArray image_io_temp = image;
        // fillPoly(image_io_temp, *ppt_temp, npt, 2, randomColor(rng), lineType);
    }

    for (i = 0; i < NUMBER; i++)
    {
        Point center;
        center.x = rng.uniform(x1, x2);
        center.y = rng.uniform(y1, y2);

        int uniform_temp = rng.uniform(-1, 9);
        int uniform_temp2 = rng.uniform(0, 300);
        InputOutputArray image_io_temp = image;
        circle(image_io_temp, center, uniform_temp2, randomColor(rng),
               uniform_temp, lineType);
    }

    for (i = 1; i < NUMBER; i++)
    {
        Point org;
        org.x = rng.uniform(x1, x2);
        org.y = rng.uniform(y1, y2);


        int uniform_temp = rng.uniform(0, 8);
        int uniform_temp2 = rng.uniform(0, 100);
        int uniform_temp3 = rng.uniform(1, 10);
        InputOutputArray image_io_temp = image;
        // putText(image_io_temp, "Testing text rendering", org, uniform_temp,
        //         uniform_temp2*0.05+0.1, randomColor(rng), uniform_temp3, lineType);
    }

    unsigned hershey_temp = FONT_HERSHEY_COMPLEX;
    Size textsize = getTextSize("OpenCV forever!", hershey_temp, 3, 5, 0);
    int textsize_width = textsize.width; 
    int textsize_height = textsize.height; 
    Point org((width - textsize_width)/2, (height - textsize_height)/2);

    // Mat image2;
    // for( i = 0; i < 255; i += 2 )
    // {
    //     Scalar all_temp = Scalar::all(i);
    //     auto temp = image - all_temp; 
    //     image2 = temp;
    //     InputOutputArray image_io_temp = image2;
    //     InputArray image2_input_temp = image2;
    //     Scalar scalar_temp(i, i, 255);
    //     // putText(image_io_temp, "OpenCV forever!", org, hershey_temp, 3,
    //     //         scalar_temp, 5, lineType);
    // }

    return 0;
}
