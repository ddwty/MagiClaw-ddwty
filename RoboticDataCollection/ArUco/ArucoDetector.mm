//
//  ArucoDetector.m
//  MagiClaw
//
//  Created by Tianyu on 9/30/24.
//

// ArucoDetector.mm
#import "ArucoCV.h"
#import <opencv2/opencv.hpp>
#import <opencv2/aruco.hpp>

@implementation ArucoDetector

// 辅助函数：将 simd_float3x3 转换为 cv::Mat
cv::Mat simdToCvMat(simd_float3x3 simdMat) {
    cv::Mat mat(3, 3, CV_32F);
    for(int row = 0; row < 3; row++) {
        for(int col = 0; col < 3; col++) {
            mat.at<float>(row, col) = simdMat.columns[col][row];
        }
    }
    return mat;
}

- (void)detectMarkersInPixelBuffer:(CVPixelBufferRef)pixelBuffer
                              ids:(NSMutableArray<NSNumber *> *)ids
                          corners:(NSMutableArray<NSArray<NSValue *> *> *)corners {
    std::vector<int> detectedIds;
    std::vector<std::vector<cv::Point2f>> detectedCorners;

    // 创建 Aruco 字典
    cv::Ptr<cv::aruco::Dictionary> dictionary = cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50);

    // 锁定像素缓冲区
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);

    // 创建灰度图像
    cv::Mat mat(height, width, CV_8UC1, baseAddress, 0);

    // 检测标记
    cv::aruco::detectMarkers(mat, dictionary, detectedCorners, detectedIds);

    // 解锁像素缓冲区
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    // 将检测结果转换为 NSMutableArray
    [ids removeAllObjects];
    [corners removeAllObjects];
    for (size_t i = 0; i < detectedIds.size(); i++) {
        [ids addObject:@(detectedIds[i])];
        NSMutableArray<NSValue *> *cornerArray = [NSMutableArray array];
        for (const auto& point : detectedCorners[i]) {
            CGPoint cgPoint = CGPointMake(point.x, point.y);
            [cornerArray addObject:[NSValue valueWithCGPoint:cgPoint]];
        }
        [corners addObject:cornerArray];
    }
}

- (double)calculateDistanceWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
                               intrinsics:(simd_float3x3)intrinsics
                               markerSize:(double)markerSize {
    std::vector<int> detectedIds;
    std::vector<std::vector<cv::Point2f>> detectedCorners;

    // 检测标记
    [self detectMarkersInPixelBuffer:pixelBuffer ids:nil corners:nil];

    // 如果检测到至少两个标记，计算它们的距离
    if (detectedIds.size() >= 2) {
        // 示例：计算第一个和第二个标记的中心点距离
        cv::Point2f center1(0, 0);
        for (const auto& point : detectedCorners[0]) {
            center1 += point;
        }
        center1 *= (1.0 / 4.0);

        cv::Point2f center2(0, 0);
        for (const auto& point : detectedCorners[1]) {
            center2 += point;
        }
        center2 *= (1.0 / 4.0);

        double distance = std::sqrt(std::pow(center2.x - center1.x, 2) + std::pow(center2.y - center1.y, 2));
        return distance;
    }

    return 0.0;
}

@end

