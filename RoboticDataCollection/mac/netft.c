/* Simple demo showing how to communicate with Net F/T using C language. */

#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "netftHeader.h"
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>

#define PORT 49152 /* Port the Net F/T always uses */
#define COMMAND 2 /* Command code 2 starts streaming */
#define NUM_SAMPLES 0 /* Will send 1 sample before stopping */

/* Typedefs used so integer sizes are more explicit */
typedef unsigned int uint32;
typedef int int32;
typedef unsigned short uint16;
typedef short int16;
typedef unsigned char byte;
typedef struct response_struct {
	uint32 rdt_sequence;
	uint32 ft_sequence;
	uint32 status;
	int32 FTData[6];
} RESPONSE;

// 添加全局变量来存储套接字句柄
static int g_socketHandle = -1;
static struct sockaddr_in g_addr;

/**
 * 连接到FT传感器
 * @param ip_address 传感器的IP地址
 * @return 成功返回0，失败返回负值
 */
int connectFT_sensor(const char *ip_address) {
	struct hostent *he;
	byte request[8];
	int err;
	
	if (ip_address == NULL) {
		return -1;
	}
	
	// 关闭现有连接
	if (g_socketHandle != -1) {
		close(g_socketHandle);
		g_socketHandle = -1;
	}
	
	// 创建新套接字
	g_socketHandle = socket(AF_INET, SOCK_DGRAM, 0);
	if (g_socketHandle == -1) {
		return -2;
	}
	
	// 设置接收超时
	struct timeval tv;
	tv.tv_sec = 1;  // 1秒超时
	tv.tv_usec = 0;
	setsockopt(g_socketHandle, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
	
	// 解析主机名
	he = gethostbyname(ip_address);
	if (he == NULL) {
		close(g_socketHandle);
		g_socketHandle = -1;
		return -3;
	}
	
	// 设置地址
	memset(&g_addr, 0, sizeof(g_addr));
	memcpy(&g_addr.sin_addr, he->h_addr_list[0], he->h_length);
	g_addr.sin_family = AF_INET;
	g_addr.sin_port = htons(PORT);
	
	// 连接
	err = connect(g_socketHandle, (struct sockaddr *)&g_addr, sizeof(g_addr));
	if (err == -1) {
		close(g_socketHandle);
		g_socketHandle = -1;
		return -4;
	}
	
	// 发送重置命令
	*(uint16*)&request[0] = htons(0x1234);
	*(uint16*)&request[2] = htons(0x0042);
	*(uint32*)&request[4] = htonl(0);
	
	send(g_socketHandle, request, 8, 0);
	
	// 等待重置完成
	usleep(100000);  // 100毫秒
	
	// 发送开始流式传输命令
	*(uint16*)&request[0] = htons(0x1234);
	*(uint16*)&request[2] = htons(COMMAND);
	*(uint32*)&request[4] = htonl(NUM_SAMPLES);
	
	send(g_socketHandle, request, 8, 0);
	
	// 接收并丢弃第一个响应
	byte response[36];
	recv(g_socketHandle, response, 36, 0);
	
	return 0;
}

/**
 * 从已连接的传感器读取数据
 * @param ft_data 输出的力/扭矩数据数组
 * @return 成功返回0，失败返回负值
 */
int readFT_data_continuous(int ft_data[6]) {
	RESPONSE resp;
	byte response[36];
	byte request[8];
	int i;
	
	if (g_socketHandle == -1) {
		return -1;  // 未连接
	}
	
	// 完全按照readFT_data的方式构造请求
	*(uint16*)&request[0] = htons(0x1234); /* standard header. */
	*(uint16*)&request[2] = htons(COMMAND); /* per table 9.1 in Net F/T user manual. */
	*(uint32*)&request[4] = htonl(NUM_SAMPLES); /* see section 9.1 in Net F/T user manual. */
	
	// 发送请求
	int bytes_sent = send(g_socketHandle, request, 8, 0);
	if (bytes_sent != 8) {
		return -3;  // 发送失败
	}
	
	// 清空任何可能存在的旧数据
	fd_set readfds;
	struct timeval tv;
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	
	FD_ZERO(&readfds);
	FD_SET(g_socketHandle, &readfds);
	
	while (select(g_socketHandle+1, &readfds, NULL, NULL, &tv) > 0) {
		recv(g_socketHandle, response, 36, 0);
		FD_ZERO(&readfds);
		FD_SET(g_socketHandle, &readfds);
	}
	
	// 设置接收超时
	tv.tv_sec = 1;  // 1秒超时
	tv.tv_usec = 0;
	setsockopt(g_socketHandle, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
	
	// 接收新数据
	int bytes_received = recv(g_socketHandle, response, 36, 0);
	if (bytes_received != 36) {
		// 如果接收失败，尝试重新建立连接
		return -2;  // 接收数据失败
	}
	
	resp.rdt_sequence = ntohl(*(uint32*)&response[0]);
	resp.ft_sequence = ntohl(*(uint32*)&response[4]);
	resp.status = ntohl(*(uint32*)&response[8]);
	
	// 打印状态码，帮助调试
//	printf("Status: %u\n", resp.status);
	
	for (i = 0; i < 6; i++) {
		resp.FTData[i] = ntohl(*(int32*)&response[12 + i * 4]);
		ft_data[i] = resp.FTData[i];
//		printf("%f, ", (double)(resp.FTData[i]) / 1000000);
	}
//	printf("\n");
	
	return 0;
}

/**
 * 断开FT传感器连接
 * @return 成功返回0
 */
int disconnectFT_sensor() {
	if (g_socketHandle != -1) {
		close(g_socketHandle);
		g_socketHandle = -1;
	}
	return 0;
}

int readFT_data(const char *ip_address, int ft_data[6]) {
	int socketHandle;           /* Handle to UDP socket used to communicate with Net F/T. */
	struct sockaddr_in addr;    /* Address of Net F/T. */
	struct hostent *he;         /* Host entry for Net F/T. */
	byte request[8];            /* The request data sent to the Net F/T. */
	RESPONSE resp;              /* The structured response received from the Net F/T. */
	byte response[36];          /* The raw response data received from the Net F/T. */
	int i;                      /* Generic loop/array index. */
	int err;                    /* Error status of operations. */
	
	if (ip_address == NULL) {
		return -1;
	}
	
	/* Calculate number of samples, command code, and open socket here. */
	socketHandle = socket(AF_INET, SOCK_DGRAM, 0);
	if (socketHandle == -1) {
		return -2;  // 返回错误代码而不是退出程序
	}
	
	*(uint16*)&request[0] = htons(0x1234); /* standard header. */
	*(uint16*)&request[2] = htons(COMMAND); /* per table 9.1 in Net F/T user manual. */
	*(uint32*)&request[4] = htonl(NUM_SAMPLES); /* see section 9.1 in Net F/T user manual. */
	
	/* Sending the request. */
	he = gethostbyname(ip_address);
	if (he == NULL) {
		close(socketHandle);
		return -3;  // 无法解析主机名
	}
	
	memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
	addr.sin_family = AF_INET;
	addr.sin_port = htons(PORT);
	
	err = connect(socketHandle, (struct sockaddr *)&addr, sizeof(addr));
	if (err == -1) {
		close(socketHandle);
		return -4;  // 连接失败
	}
	
	send(socketHandle, request, 8, 0);

	/* Receiving the response. */
	int bytes_received = recv(socketHandle, response, 36, 0);
	if (bytes_received != 36) {
		close(socketHandle);
		return -5;  // 接收数据失败
	}
	
	resp.rdt_sequence = ntohl(*(uint32*)&response[0]);
	resp.ft_sequence = ntohl(*(uint32*)&response[4]);
	resp.status = ntohl(*(uint32*)&response[8]);
	for (i = 0; i < 6; i++) {
		resp.FTData[i] = ntohl(*(int32*)&response[12 + i * 4]);
		ft_data[i] = resp.FTData[i];  // 将数据复制到输出数组
//        printf("%f, ",  (double)(resp.FTData[i]) / 1000000);
	}

	close(socketHandle);  // 关闭套接字
	
	return 0;  // 成功
}

/**
 * 重置 Net F/T 传感器
 * @param ip_address 传感器的IP地址
 * @return 成功返回0，失败返回负值
 */
int resetFT_sensor(const char *ip_address) {
	int socketHandle;           /* Handle to UDP socket used to communicate with Net F/T. */
	struct sockaddr_in addr;    /* Address of Net F/T. */
	struct hostent *he;         /* Host entry for Net F/T. */
	byte request[8];            /* The request data sent to the Net F/T. */
	int err;                    /* Error status of operations. */
	
	if (ip_address == NULL) {
		return -1;
	}
	
	/* Open socket */
	socketHandle = socket(AF_INET, SOCK_DGRAM, 0);
	if (socketHandle == -1) {
		return -2;  // 无法创建套接字
	}
	
	/* 准备重置命令 */
	*(uint16*)&request[0] = htons(0x1234); /* 标准头 */
	*(uint16*)&request[2] = htons(0x0042);
	*(uint32*)&request[4] = htonl(0);      /* 重置参数 */
	
	/* 发送请求 */
	he = gethostbyname(ip_address);
	if (he == NULL) {
		close(socketHandle);
		return -3;  // 无法解析主机名
	}
	
	memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
	addr.sin_family = AF_INET;
	addr.sin_port = htons(PORT);
	
	err = connect(socketHandle, (struct sockaddr *)&addr, sizeof(addr));
	if (err == -1) {
		close(socketHandle);
		return -4;  // 连接失败
	}
	
	/* 发送重置命令 */
	int bytes_sent = send(socketHandle, request, 8, 0);
	if (bytes_sent != 8) {
		close(socketHandle);
		return -5;  // 发送失败
	}
	
	/* 等待一小段时间确保重置完成 */
	usleep(100000);  // 100毫秒
	
	close(socketHandle);
	return 0;  // 成功
}
