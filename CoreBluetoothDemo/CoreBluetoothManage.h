//
//  CoreBluetoothManage.h
//  CoreBluetoothDemo
//
//  Created by 冯超 on 2021/7/31.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CoreBluetoothManageDelegate <NSObject>
// 获取扫描列表
- (void)devCoreBluetoothLists:(NSMutableArray *)devArray;
// 连接设备成功
- (void)devDidConnectPeripheral:(CBPeripheral *)peripheral;
// 获取设备信息
- (void)getPeripheral:(NSData *)value;
// 连接断开
- (void)devDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
// 连接失败
- (void)devDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end

@interface CoreBluetoothManage : NSObject

@property (nonatomic, weak) id<CoreBluetoothManageDelegate>delegate;

+ (instancetype)sharedManage; //指定初始化

// 连接设备
- (void)connectDeviceWithPeripheral:(CBPeripheral *)peripheral;
// 取消连接蓝牙
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;
// 停止扫描
- (void)stopScanBluetooth;
// 写入数据
- (void)writeDataInfo:(NSString *)info;

@end

NS_ASSUME_NONNULL_END
