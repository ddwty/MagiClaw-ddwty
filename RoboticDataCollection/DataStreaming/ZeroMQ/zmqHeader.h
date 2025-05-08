//
//  zmqHeader.h
//  MagiClaw
//
//  Created by Tianyu on 5/7/25.
//

#ifndef zmqHeader_h
#define zmqHeader_h

#ifdef __cplusplus
extern "C" {
#endif

/**
 * 初始化ZMQ发送器
 * @param endpoint 连接端点，例如 "tcp://*:5555" 用于绑定服务器
 * @return 成功返回0，失败返回负值
 */
int zmq_init_publisher(const char *endpoint);

/**
 * 发送数据
 * @param topic 消息主题
 * @param data 要发送的数据
 * @param size 数据大小
 * @return 成功返回0，失败返回负值
 */
int zmq_send_data(const char *topic, const void *data, size_t size);

/**
 * 关闭ZMQ发送器
 * @return 成功返回0，失败返回负值
 */
int zmq_close_publisher();

/**
 * 初始化ZMQ订阅者
 * @param endpoint 连接端点，例如 "tcp://192.168.1.100:5555" 用于连接到发布者
 * @param topics 要订阅的主题数组，传入NULL订阅所有主题
 * @param topicCount 主题数量，如果订阅所有主题，传入0
 * @return 成功返回0，失败返回负值
 */
int zmq_init_subscriber(const char *endpoint, const char **topics, int topicCount);

/**
 * 接收数据（非阻塞）
 * @param topic 接收到的主题将存储在此处
 * @param topicSize topic缓冲区大小
 * @param data 接收到的数据将存储在此处
 * @param size 数据缓冲区大小
 * @return 接收到的数据大小，如果没有数据返回0，错误返回负值
 */
int zmq_receive_data(char *topic, size_t topicSize, void *data, size_t size);

/**
 * 关闭ZMQ订阅者
 * @return 成功返回0，失败返回负值
 */
int zmq_close_subscriber();



#ifdef __cplusplus
}
#endif

#endif /* zmqHeader_h */
