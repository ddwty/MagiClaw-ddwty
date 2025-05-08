//
//  testZMQ2.m
//  MagiClaw
//
//  Created by Tianyu on 5/7/25.
//
#include <TargetConditionals.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_OSX
#import <Appkit/AppKit.h>
#endif

#import "zmq.h"
#import "zmqHeader.h"

// ZMQ上下文和发布者套接字
static void *context = NULL;
static void *publisher = NULL;

int zmq_init_publisher(const char *endpoint) {
    // 如果已经初始化，先关闭
    if (context != NULL || publisher != NULL) {
        zmq_close_publisher();
    }
    
    // 创建ZMQ上下文
    context = zmq_ctx_new();
    if (!context) {
        NSLog(@"创建ZMQ上下文失败");
        return -1;
    }
    
    // 创建发布者套接字
    publisher = zmq_socket(context, ZMQ_PUB);
    if (!publisher) {
        NSLog(@"创建ZMQ发布者套接字失败");
        zmq_ctx_destroy(context);
        context = NULL;
        return -2;
    }
    
    // 绑定到指定端点
    int rc = zmq_bind(publisher, endpoint);
    if (rc != 0) {
        NSLog(@"ZMQ绑定到%s失败: %s", endpoint, zmq_strerror(zmq_errno()));
        zmq_close(publisher);
        zmq_ctx_destroy(context);
        publisher = NULL;
        context = NULL;
        return -3;
    }
    
    // 设置发送超时（毫秒）
    int timeout = 1000;
    zmq_setsockopt(publisher, ZMQ_SNDTIMEO, &timeout, sizeof(timeout));
    
    NSLog(@"ZMQ发布者初始化成功，绑定到: %s", endpoint);
    return 0;
}

int zmq_send_data(const char *topic, const void *data, size_t size) {
    if (!publisher) {
        NSLog(@"ZMQ发布者未初始化");
        return -1;
    }
    
    // 发送主题
    int rc = zmq_send(publisher, topic, strlen(topic), ZMQ_SNDMORE);
    if (rc == -1) {
        NSLog(@"发送主题失败: %s", zmq_strerror(zmq_errno()));
        return -2;
    }
    
    // 发送数据
    rc = zmq_send(publisher, data, size, 0);
    if (rc == -1) {
        NSLog(@"发送数据失败: %s", zmq_strerror(zmq_errno()));
        return -3;
    }
    
    return 0;
}

int zmq_close_publisher() {
    if (publisher) {
        zmq_close(publisher);
        publisher = NULL;
    }
    
    if (context) {
        zmq_ctx_destroy(context);
        context = NULL;
    }
    
    NSLog(@"ZMQ发布者已关闭");
    return 0;
}

int test(int argc, const char * argv[]) {
    // 测试ZMQ功能
    zmq_init_publisher("tcp://*:5555");
    const char *message = "Hello, ZeroMQ!";
    zmq_send_data("test", message, strlen(message));
    zmq_close_publisher();
    return 0;
}



// ZMQ订阅者套接字
static void *subscriber = NULL;

int zmq_init_subscriber(const char *endpoint, const char **topics, int topicCount) {
    // 如果已经初始化，先关闭
    if (subscriber != NULL) {
        zmq_close_subscriber();
    }
    
    // 如果上下文不存在，创建上下文
    if (context == NULL) {
        context = zmq_ctx_new();
        if (!context) {
            NSLog(@"创建ZMQ上下文失败");
            return -1;
        }
    }
    
    // 创建订阅者套接字
    subscriber = zmq_socket(context, ZMQ_SUB);
    if (!subscriber) {
        NSLog(@"创建ZMQ订阅者套接字失败");
        return -2;
    }
    
    // 连接到指定端点
    int rc = zmq_connect(subscriber, endpoint);
    if (rc != 0) {
        NSLog(@"ZMQ连接到%s失败: %s", endpoint, zmq_strerror(zmq_errno()));
        zmq_close(subscriber);
        subscriber = NULL;
        return -3;
    }
    
    // 设置接收超时（毫秒）
    int timeout = 1000;
    zmq_setsockopt(subscriber, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));
    
    // 设置订阅主题
    if (topics == NULL || topicCount == 0) {
        // 订阅所有主题
        zmq_setsockopt(subscriber, ZMQ_SUBSCRIBE, "", 0);
        NSLog(@"ZMQ订阅者已订阅所有主题");
    } else {
        // 订阅指定主题
        for (int i = 0; i < topicCount; i++) {
            zmq_setsockopt(subscriber, ZMQ_SUBSCRIBE, topics[i], strlen(topics[i]));
            NSLog(@"ZMQ订阅者已订阅主题: %s", topics[i]);
        }
    }
    
    NSLog(@"ZMQ订阅者初始化成功，连接到: %s", endpoint);
    return 0;
}

int zmq_receive_data(char *topic, size_t topicSize, void *data, size_t size) {
    if (!subscriber) {
        NSLog(@"ZMQ订阅者未初始化");
        return -1;
    }
    
    // 非阻塞接收主题
    int topicLen = zmq_recv(subscriber, topic, topicSize - 1, ZMQ_DONTWAIT);
    if (topicLen < 0) {
        if (zmq_errno() == EAGAIN) {
            // 没有消息可接收
            return 0;
        }
        NSLog(@"接收主题失败: %s", zmq_strerror(zmq_errno()));
        return -2;
    }
    
    // 确保主题字符串以null结尾
    topic[topicLen < topicSize ? topicLen : topicSize - 1] = '\0';
    
    // 接收数据
    int dataLen = zmq_recv(subscriber, data, size - 1, 0);
    if (dataLen < 0) {
        NSLog(@"接收数据失败: %s", zmq_strerror(zmq_errno()));
        return -3;
    }
    
    // 确保数据以null结尾（如果是字符串数据）
    if (dataLen < size) {
        ((char*)data)[dataLen] = '\0';
    }
    
    return dataLen;
}

int zmq_close_subscriber() {
    if (subscriber) {
        zmq_close(subscriber);
        subscriber = NULL;
        NSLog(@"ZMQ订阅者已关闭");
    }
    
    // 如果发布者也已关闭，则销毁上下文
    if (publisher == NULL && context != NULL) {
        zmq_ctx_destroy(context);
        context = NULL;
    }
    
    return 0;
}
