//
//  DetectAruco.m
//  MagiClaw
//
//  Created by Tianyu on 9/3/24.
//

//#import <OpenCV/opencv2/opencv.hpp>
//#import <OpenCV/opencv2/core.hpp>
//#import <OpenCV/opencv2/imgcodecs/ios.h>
//#import <OpenCV/opencv2/imgproc/imgproc.hpp>
//#import <OpenCV/opencv2/aruco.hpp>
//#import <OpenCV/opencv2/objdetect/aruco_dictionary.hpp>
//#import <OpenCV/opencv2/core/cvstd_wrapper.hpp>
//#import <OpenCV/opencv2/core/mat.hpp>
//#import <Foundation/Foundation.h>

#import <opencv2/opencv.hpp>
#import <opencv2/core.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#include "opencv2/aruco.hpp"
//#include "opencv2/aruco/dictionary.hpp"
#include "opencv2/objdetect/aruco_dictionary.hpp"
#include <opencv2/core/cvstd_wrapper.hpp>
#include <map>
#include <opencv2/core/mat.hpp>
#include<opencv2/objdetect/aruco_detector.hpp>
//#include <array>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreVideo/CoreVideo.h>
#import <Accelerate/Accelerate.h>
#import "ArucoCV.h"
#import "SKWorldTransform.h"
//
@implementation ArucoCV

static cv::Mat rotateRodriques(cv::Mat &rotMat, cv::Vec3d &tvecs) {
    cv::Mat extrinsics(4, 4, CV_64F);
    
    for( int row = 0; row < rotMat.rows; row++) {
        for (int col = 0; col < rotMat.cols; col++) {
            extrinsics.at<double>(row,col) = rotMat.at<double>(row,col);
        }
        extrinsics.at<double>(row,3) = tvecs[row];
    }
    extrinsics.at<double>(3,3) = 1;

    // Convert Opencv coords to OpenGL coords
    extrinsics = [ArucoCV GetCVToGLMat] * extrinsics;
    return extrinsics;
}

//+(double) calculateDistance:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerSize {
//    
//    std::vector<int> ids;//用于存储检测到的标记的id
//    std::vector<std::vector<cv::Point2f>> corners;//用于存储检测到的标记的四个角点的坐标
//    detect(corners, ids, pixelBuffer);//检测当前帧中是否包含标记
//   
//    //如果没有检测到标记，则返回0
//    if(ids.size() == 0) {
//        return 0.0;
//    }
//    else if (ids.size() > 0) {
//        
//// 遍历 corners 中的数据并输出
////        for (int i = 0; i < corners.size(); i++) {
////            printf("Marker ID: %d\n", ids[i]);
////            for (int j = 0; j < 4; j++) {
////                printf("Corner %d: (%f, %f)\n", j, corners[i][j].x, corners[i][j].y);
////            }
////        }
////        NSLog(@"found: rvec.size(): %lu", corners.size());
//        //将Swift传递进来的相机内参矩阵的数据赋值给intrinMat中对应位置的元素
//        cv::Mat intrinMat(3,3,CV_64F);
//        intrinMat.at<Float64>(0,0) = intrinsics.columns[0][0];
//        intrinMat.at<Float64>(0,1) = intrinsics.columns[1][0];
//        intrinMat.at<Float64>(0,2) = intrinsics.columns[2][0];
//        intrinMat.at<Float64>(1,0) = intrinsics.columns[0][1];
//        intrinMat.at<Float64>(1,1) = intrinsics.columns[1][1];
//        intrinMat.at<Float64>(1,2) = intrinsics.columns[2][1];
//        intrinMat.at<Float64>(2,0) = intrinsics.columns[0][2];
//        intrinMat.at<Float64>(2,1) = intrinsics.columns[1][2];
//        intrinMat.at<Float64>(2,2) = intrinsics.columns[2][2];
//        
//        
//        
//        std::vector<cv::Vec3d> rvecs, tvecs;  //这是一个向量，向量的每个元素是储存每个marker的位姿, rvec用于存储旋转向量，tvec用于存储平移向量
//        cv::Mat distCoeffs = cv::Mat::zeros(8, 1, CV_64F);  // 相机畸变系数，初始化为8个0
//       
////        cv::aruco::estimatePoseSingleMarkers(corners, markerSize, intrinMat, distCoeffs, rvecs, tvecs);//输出是所有marker的旋转向量rvecs和平移向量tvecs
////        std::cout << "tvecs: " << std::endl;
////            for (const auto& tvec : tvecs) {
////                std::cout << tvec << std::endl;
////            }
//        // 确保只处理两个标记
//        if (ids.size() == 2) {
//            // 计算第一个标记的中心点
//            double center1X = (corners[0][0].x + corners[0][1].x + corners[0][2].x + corners[0][3].x) / 4.0;
//            double center1Y = (corners[0][0].y + corners[0][1].y + corners[0][2].y + corners[0][3].y) / 4.0;
//            
//            // 计算第二个标记的中心点
//            double center2X = (corners[1][0].x + corners[1][1].x + corners[1][2].x + corners[1][3].x) / 4.0;
//            double center2Y = (corners[1][0].y + corners[1][1].y + corners[1][2].y + corners[1][3].y) / 4.0;
//            
//            // 计算两个中心点之间的距离
//            double distance = std::sqrt((center2X - center1X) * (center2X - center1X) + (center2Y - center1Y) * (center2Y - center1Y));
//            NSLog(@"distance: %f", distance);
//            return distance;
//        }
//        return 0.0;
//    }
//    return 0.0;
//}

//cv::Ptr<cv::aruco::Dictionary> dictionary = cv::makePtr<cv::aruco::Dictionary> (cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50));
//cv::Ptr<cv::aruco::DetectorParameters> detectorParams = cv::aruco::DetectorParameters::create();

//parameters.minMarkerPerimeterRate = 0.03;
// Build success
static void detect(std::vector<std::vector<cv::Point2f> > &corners, std::vector<int> &ids, CVPixelBufferRef pixelBuffer) {
    double startTime = cv::getTickCount();
//    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::makePtr<cv::aruco::Dictionary> (cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50));
    cv::aruco::DetectorParameters detectorParams = cv::aruco::DetectorParameters();
    cv::aruco::Dictionary dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50);

    

    detectorParams.minMarkerPerimeterRate = 0.5;
    detectorParams.adaptiveThreshWinSizeMin = 23;
    detectorParams.adaptiveThreshWinSizeMax = 23;
    detectorParams.adaptiveThreshWinSizeStep = 10;
    detectorParams.adaptiveThreshConstant = 7;
    detectorParams.minMarkerPerimeterRate = 0.1;
    detectorParams.maxMarkerPerimeterRate = 4;
    detectorParams.polygonalApproxAccuracyRate = 0.03;
    detectorParams.minCornerDistanceRate = 0.05;
    detectorParams.minDistanceToBorder = 3;
    detectorParams.minMarkerDistanceRate = 0.05;
    detectorParams.cornerRefinementWinSize = 5;
    detectorParams.cornerRefinementMaxIterations = 30;
    detectorParams.cornerRefinementMinAccuracy = 0.1;
    detectorParams.markerBorderBits = 1;
    detectorParams.perspectiveRemovePixelPerCell = 2;
    detectorParams.perspectiveRemoveIgnoredMarginPerCell = 0.13;
    detectorParams.maxErroneousBitsInBorderRate = 0.35;
    detectorParams.minOtsuStdDev = 5.0;
    detectorParams.errorCorrectionRate = 0.6;
//    
    cv::aruco::ArucoDetector detector(dictionary, detectorParams);
    // grey scale channel at 0
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0);
    
//    cv::Mat kernel = cv::Mat::ones(5, 5, CV_32F) / 25;
//    // 对图像进行预处理，如直方图均衡化
//    cv::GaussianBlur(mat, mat, cv::Size(3, 3), 0);  // 对图像进行高斯模糊以减少噪声
//    cv::Canny(mat, mat, 100, 200);  // 使用 Canny 边缘检测
    
//    cv::aruco::detectMarkers(mat, dictionary, corners, ids);
    detector.detectMarkers(mat, corners, ids);
    cv::aruco::drawDetectedMarkers(mat, corners, ids);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    double endTime = cv::getTickCount();
    double totalTime = (endTime - startTime) / cv::getTickFrequency();
//    NSLog(@"Time: %f", totalTime);
    
}



+(NSMutableArray *) estimatePose:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerSize {
    
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f>> corners;
    detect(corners, ids, pixelBuffer);
    
    NSMutableArray *arrayMatrix = [NSMutableArray new];
    if(ids.size() == 0) {
        return arrayMatrix;
    }
    // 遍历 corners 中的数据并输出
//        for (int i = 0; i < corners.size(); i++) {
//            printf("Marker ID: %d\n", ids[i]);
//            for (int j = 0; j < 4; j++) {
//                printf("Corner %d: (%f, %f)\n", j, corners[i][j].x, corners[i][j].y);
//            }
//        }
    cv::Mat intrinMat(3,3,CV_64F);
    intrinMat.at<Float64>(0,0) = intrinsics.columns[0][0];
    intrinMat.at<Float64>(0,1) = intrinsics.columns[1][0];
    intrinMat.at<Float64>(0,2) = intrinsics.columns[2][0];
    intrinMat.at<Float64>(1,0) = intrinsics.columns[0][1];
    intrinMat.at<Float64>(1,1) = intrinsics.columns[1][1];
    intrinMat.at<Float64>(1,2) = intrinsics.columns[2][1];
    intrinMat.at<Float64>(2,0) = intrinsics.columns[0][2];
    intrinMat.at<Float64>(2,1) = intrinsics.columns[1][2];
    intrinMat.at<Float64>(2,2) = intrinsics.columns[2][2];
    
    std::vector<cv::Vec3d> rvecs, tvecs;
    cv::Mat distCoeffs = cv::Mat::zeros(8, 1, CV_64F);
    cv::aruco::estimatePoseSingleMarkers(corners, markerSize, intrinMat, distCoeffs, rvecs, tvecs);
//    NSLog(@"found: rvecs.size(): %lu", rvecs.size());
    

    cv::Mat rotMat, tranMat;
    for (int i = 0; i < rvecs.size(); i++) {
        cv::Rodrigues(rvecs[i], rotMat);
        cv::Mat extrinsics = rotateRodriques(rotMat, tvecs[i]);
        simd_float4x4 transformMatrix = [ArucoCV transformToSimdMatrix:extrinsics];
        SKWorldTransform *transform = [SKWorldTransform new];
        transform.arucoId = ids[i];
        transform.transform = transformMatrix;
        [arrayMatrix addObject:transform];
    }
    
    return arrayMatrix;
}

+(cv::Mat) GetCVToGLMat {
    cv::Mat cvToGL = cv::Mat::zeros(4,4,CV_64F);
    cvToGL.at<double>(0,0) = 1.0f;
    cvToGL.at<double>(1,1) = -1.0f; //invert y
    cvToGL.at<double>(2,2) = -1.0f; //invert z
    cvToGL.at<double>(3,3) = 1.0f;
    return cvToGL;
}

+(simd_float4x4) transformToSimdMatrix:(cv::Mat&) openCVTransformation {
    
    // 定义 simd_float4x4 矩阵
    simd_float4x4 mat;
    
    

    // 将 OpenCV 矩阵的元素映射到 simd_float4x4
    mat.columns[0] = simd_make_float4(
        (float) openCVTransformation.at<double>(0, 0),
        (float) openCVTransformation.at<double>(1, 0),
        (float) openCVTransformation.at<double>(2, 0),
        (float) openCVTransformation.at<double>(3, 0)
    );
    
    mat.columns[1] = simd_make_float4(
        (float) openCVTransformation.at<double>(0, 1),
        (float) openCVTransformation.at<double>(1, 1),
        (float) openCVTransformation.at<double>(2, 1),
        (float) openCVTransformation.at<double>(3, 1)
    );
    
    mat.columns[2] = simd_make_float4(
        (float) openCVTransformation.at<double>(0, 2),
        (float) openCVTransformation.at<double>(1, 2),
        (float) openCVTransformation.at<double>(2, 2),
        (float) openCVTransformation.at<double>(3, 2)
    );
    
    mat.columns[3] = simd_make_float4(
        (float) openCVTransformation.at<double>(0, 3),
        (float) openCVTransformation.at<double>(1, 3),
        (float) openCVTransformation.at<double>(2, 3),
        (float) openCVTransformation.at<double>(3, 3)
    );

    return mat;
}




@end
