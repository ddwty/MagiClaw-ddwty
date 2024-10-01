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
//#include <array>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreVideo/CoreVideo.h>
#import <Accelerate/Accelerate.h>
#import "ArucoCV.h"
//
@implementation ArucoCV

+(double) calculateDistance:(CVPixelBufferRef)pixelBuffer withIntrinsics:(matrix_float3x3)intrinsics andMarkerSize:(Float64)markerSize {
    
    std::vector<int> ids;//用于存储检测到的标记的id
    std::vector<std::vector<cv::Point2f>> corners;//用于存储检测到的标记的四个角点的坐标
    detect(corners, ids, pixelBuffer);//检测当前帧中是否包含标记
   
    //如果没有检测到标记，则返回0
    if(ids.size() == 0) {
        return 0.0;
    }
    else if (ids.size() > 0) {
        
// 遍历 corners 中的数据并输出
//        for (int i = 0; i < corners.size(); i++) {
//            printf("Marker ID: %d\n", ids[i]);
//            for (int j = 0; j < 4; j++) {
//                printf("Corner %d: (%f, %f)\n", j, corners[i][j].x, corners[i][j].y);
//            }
//        }
//        NSLog(@"found: rvec.size(): %lu", corners.size());
        //将Swift传递进来的相机内参矩阵的数据赋值给intrinMat中对应位置的元素
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
        
        
        
        std::vector<cv::Vec3d> rvecs, tvecs;  //这是一个向量，向量的每个元素是储存每个marker的位姿, rvec用于存储旋转向量，tvec用于存储平移向量
        cv::Mat distCoeffs = cv::Mat::zeros(8, 1, CV_64F);  // 相机畸变系数，初始化为8个0
       
//        cv::aruco::estimatePoseSingleMarkers(corners, markerSize, intrinMat, distCoeffs, rvecs, tvecs);//输出是所有marker的旋转向量rvecs和平移向量tvecs
//        std::cout << "tvecs: " << std::endl;
//            for (const auto& tvec : tvecs) {
//                std::cout << tvec << std::endl;
//            }
        // 确保只处理两个标记
        if (ids.size() == 2) {
            // 计算第一个标记的中心点
            double center1X = (corners[0][0].x + corners[0][1].x + corners[0][2].x + corners[0][3].x) / 4.0;
            double center1Y = (corners[0][0].y + corners[0][1].y + corners[0][2].y + corners[0][3].y) / 4.0;
            
            // 计算第二个标记的中心点
            double center2X = (corners[1][0].x + corners[1][1].x + corners[1][2].x + corners[1][3].x) / 4.0;
            double center2Y = (corners[1][0].y + corners[1][1].y + corners[1][2].y + corners[1][3].y) / 4.0;
            
            // 计算两个中心点之间的距离
            double distance = std::sqrt((center2X - center1X) * (center2X - center1X) + (center2Y - center1Y) * (center2Y - center1Y));
            NSLog(@"distance: %f", distance);
            return distance;
        }
        
        //MARK: -  遍历每个id
//        for (int index = 0; index < ids.size(); index++) {
//            for (int i = 0; i < tvecs.size(); i++) {
//                std::cout << "Element " << i << ": tvec:" << tvecs[i][0] << ", " << tvecs[i][1] << ", " << tvecs[i][2] << std::endl;
//            }
//            //按获取某个marker的顶点坐标
//            const auto& corner = corners[index];
//            const auto& topLeft = corner[0];
//            const auto& topRight = corner[1];
//            const auto& bottomRight = corner[2];
//            const auto& bottomLeft = corner[3];
//            
//            std::cout << "topLeft: (" << topLeft.x << ", " << topLeft.y << ")" << std::endl;
//            std::vector<cv::Point2f> points = {topLeft, topRight, bottomRight, bottomLeft};
//            
//            double centerX = (topLeft.x + topRight.x + bottomRight.x + bottomLeft.x) / 4.0;
//            double centerY = (topLeft.y + topRight.y + bottomRight.y + bottomLeft.y) / 4.0;
//            
//            
//            cv::Mat rotMat, tranMat;
//           
//            cv::Rodrigues(rvecs[index], rotMat);   // 将旋转向量转化为旋转矩阵, rotMat是3x3
//            cv::Mat computedRotMat = cv::Mat::zeros(3, 3, CV_64F);
//            
// //将computedRotMat转为simd类型的矩阵
//            simd_float3x3 simd_computedRotMat = (simd_float3x3){
//                .columns[0] = {(float) computedRotMat.at<double>(0, 0), (float) computedRotMat.at<double>(1, 0), (float)  computedRotMat.at<double>(2, 0)},
//                .columns[1] = {(float) computedRotMat.at<double>(0, 1),(float) computedRotMat.at<double>(1, 1), (float) computedRotMat.at<double>(2, 1)},
//                .columns[2] = {(float) computedRotMat.at<double>(0, 2), (float) computedRotMat.at<double>(1, 2), (float) computedRotMat.at<double>(2, 2)}
//            };
//
//        } //: for每一个marker
        
        
        
        return 0.0;
    }
    return 0.0;
}

// Build success
static void detect(std::vector<std::vector<cv::Point2f> > &corners, std::vector<int> &ids, CVPixelBufferRef pixelBuffer) {
    double startTime = cv::getTickCount();
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::makePtr<cv::aruco::Dictionary> (cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50));

    // grey scale channel at 0
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0); //CV_8UC1每个像素用 8 位无符号整数表示，且只有一个通道
    
    cv::aruco::detectMarkers(mat, dictionary, corners, ids);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    double endTime = cv::getTickCount();
    double totalTime = (endTime - startTime) / cv::getTickFrequency();
//    NSLog(@"Time: %f", totalTime);
    
}



@end
