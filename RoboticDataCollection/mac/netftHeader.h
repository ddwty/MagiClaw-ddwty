//
//  netftHeader.h
//  MagiClaw
//
//  Created by Tianyu on 4/17/25.
//

#ifndef netftHeader_h
#define netftHeader_h

/**
 * 读取来自 Net F/T 传感器的力和扭矩数据
 * @param ip_address 传感器的IP地址
 * @param ft_data 用于存储读取到的力和扭矩数据的数组（长度为6）
 * @return 成功返回0，失败返回负值
 */
int readFT_data(const char *ip_address, int ft_data[6]);

/**
 * 重置 Net F/T 传感器
 * @param ip_address 传感器的IP地址
 * @return 成功返回0，失败返回负值
 */
int resetFT_sensor(const char *ip_address);

int connectFT_sensor(const char *ip_address);

int readFT_data_continuous(int ft_data[6]);

int disconnectFT_sensor();

#endif /* netftHeader_h */
