//
//  DetectAruco.m
//  MagiClaw
//
//  Created by Tianyu on 9/3/24.
//

#include <TargetConditionals.h>
//#if !TARGET_OS_MAC
//#if TARGET_OS_IOS

#import <opencv2/opencv.hpp>
#import <opencv2/core.hpp>

#if TARGET_OS_IOS
#import <opencv2/imgcodecs/ios.h>
#endif

#if TARGET_OS_OSX
#import <opencv2/imgcodecs/macosx.h>
#import <Appkit/AppKit.h>
#endif

#import <opencv2/imgcodecs.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#include "opencv2/objdetect/aruco_detector.hpp"
//#include "opencv2/aruco/dictionary.hpp"
#include "opencv2/objdetect/aruco_dictionary.hpp"
#include <opencv2/core/cvstd_wrapper.hpp>
#include <opencv2/core/matx.hpp>
#include <map>
#include <opencv2/core/mat.hpp>
#include<opencv2/objdetect/aruco_detector.hpp>
//#include <array>

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
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

// Build success
static void detect(std::vector<std::vector<cv::Point2f> > &corners, std::vector<int> &ids, CVPixelBufferRef pixelBuffer) {
    double startTime = cv::getTickCount();
//    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::makePtr<cv::aruco::Dictionary> (cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50));
    cv::aruco::DetectorParameters detectorParams = cv::aruco::DetectorParameters();
    cv::aruco::Dictionary dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50);

    

    detectorParams.adaptiveThreshWinSizeMin = 23;
    detectorParams.adaptiveThreshWinSizeMax = 23;
    detectorParams.adaptiveThreshWinSizeStep = 3;
    detectorParams.adaptiveThreshConstant = 7;
    detectorParams.minMarkerPerimeterRate = 0.15;
    detectorParams.maxMarkerPerimeterRate = 4;
    detectorParams.polygonalApproxAccuracyRate = 0.06;
    detectorParams.minCornerDistanceRate = 0.05;
    detectorParams.minDistanceToBorder = 0;
    detectorParams.minMarkerDistanceRate = 0.05;
    detectorParams.cornerRefinementWinSize = 1;
    detectorParams.cornerRefinementMaxIterations = 30;
    detectorParams.cornerRefinementMinAccuracy = 0.1;
    detectorParams.markerBorderBits = 1;
    detectorParams.perspectiveRemovePixelPerCell = 2;
    detectorParams.perspectiveRemoveIgnoredMarginPerCell = 0.1;
    detectorParams.maxErroneousBitsInBorderRate = 0.5;
    detectorParams.minOtsuStdDev = 5.0;
    detectorParams.errorCorrectionRate = 0.8;
////
    cv::aruco::ArucoDetector detector(dictionary, detectorParams);
    // grey scale channel at 0
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    
    printf("11111 width: %f, height: %f", width, height);
    
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0);
//
    cv::Mat kernel = cv::Mat::ones(5, 5, CV_32F) / 25;
    // 对图像进行预处理，如直方图均衡化
//    cv::GaussianBlur(mat, mat, cv::Size(30, 30), 0);  // 对图像进行高斯模糊以减少噪声
//    cv::Canny(mat, mat, 100, 200);  // 使用 Canny 边缘检测
    
//    cv::aruco::detectMarkers(mat, dictionary, corners, ids);
    detector.detectMarkers(mat, corners, ids);
//    cv::aruco::drawDetectedMarkers(mat, corners, ids);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    double endTime = cv::getTickCount();
    double totalTime = (endTime - startTime) / cv::getTickFrequency();
//    NSLog(@"Time: %f", totalTime);
    
}



+(NSMutableArray *) estimatePose:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerLength {
    
    std::vector<int> ids;
    std::vector<std::vector<cv::Point2f>> corners;
    // set coordinate system
    cv::Mat objPoints(4, 1, CV_32FC3);
    objPoints.ptr<cv::Vec3f>(0)[0] = cv::Vec3f(-markerLength/2.f, markerLength/2.f, 0);
    objPoints.ptr<cv::Vec3f>(0)[1] = cv::Vec3f(markerLength/2.f, markerLength/2.f, 0);
    objPoints.ptr<cv::Vec3f>(0)[2] = cv::Vec3f(markerLength/2.f, -markerLength/2.f, 0);
    objPoints.ptr<cv::Vec3f>(0)[3] = cv::Vec3f(-markerLength/2.f, -markerLength/2.f, 0);
    
    detect(corners, ids, pixelBuffer);
    printf("detect ");
    NSMutableArray *arrayMatrix = [NSMutableArray new];
    if(ids.size() == 0) {
        return arrayMatrix;
    }
   
    // 遍历 corners 中的数据并输出
        for (int i = 0; i < corners.size(); i++) {
            printf("Marker ID: %d\n", ids[i]);
            for (int j = 0; j < 4; j++) {
                printf("Corner %d: (%f, %f)\n", j, corners[i][j].x, corners[i][j].y);
            }
        }
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
    
    cv::Mat distCoeffs = cv::Mat::zeros(8, 1, CV_64F);
    size_t nMarkers = corners.size();
    std::vector<cv::Vec3d> rvecs(nMarkers), tvecs(nMarkers);
//    cv::aruco::estimatePoseSingleMarkers(corners, markerSize, intrinMat, distCoeffs, rvecs, tvecs);
    if(!ids.empty()) {
        for (size_t i = 0; i < nMarkers; i++) {
            cv::solvePnP(objPoints, corners.at(i), intrinMat, distCoeffs, rvecs.at(i), tvecs.at(i));
        }
    }
    
//    NSLog(@"found: rvecs.size(): %lu", rvecs.size());
    
    // successed
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
//#endif
