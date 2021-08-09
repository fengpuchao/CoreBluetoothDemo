//
//  CoreBluetoothManage.h
//  CoreBluetoothDemo
//
//  Created by 冯超 on 2021/7/31.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CoreBluetoothManagerState) {
    CoreManagerStateUnknown = 0,   // 未知状态
    CoreManagerStateResetting,     // 重置
    CoreManagerStateUnsupported,   // 不支持
    CoreManagerStateUnauthorized,  // 授权
    CoreManagerStatePoweredOff,    // 蓝牙未开启
    CoreManagerStatePoweredOn,     // 开始扫描
};

@protocol CoreBluetoothManageDelegate <NSObject>

- (void)devCoreBluetoothLists:(NSMutableArray *)devArray;
- (void)devDidConnectPeripheral:(CBPeripheral *)peripheral;
- (void)getPeripheral:(NSData *)data;
- (void)pushDevInfo;
- (void)devDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void)devDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end

@interface CoreBluetoothManage : NSObject

@property (nonatomic, assign) CoreBluetoothManagerState *state;

@property (nonatomic, weak) id<CoreBluetoothManageDelegate>delegate;

+ (instancetype)sharedManage;

- (void)connectDeviceWithPeripheral:(CBPeripheral *)peripheral;
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;
- (void)stopScanBluetooth;
- (void)writeDataInfo:(NSString *)info;

@end

NS_ASSUME_NONNULL_END
