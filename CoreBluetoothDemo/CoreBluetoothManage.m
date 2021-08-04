//
//  CoreBluetoothManage.m
//  CoreBluetoothDemo
//
//  Created by 冯超 on 2021/7/31.
//

#import "CoreBluetoothManage.h"
@interface CoreBluetoothManage ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong) NSMutableDictionary *deviceDic;
@property (nonatomic, strong) NSMutableArray *writeArray;

@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBCharacteristic *characteristic;

@end

static CoreBluetoothManage *__coreBluetoothManage;
@implementation CoreBluetoothManage

+ (instancetype)sharedManage{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __coreBluetoothManage = [[CoreBluetoothManage alloc]init];
    });
    return __coreBluetoothManage;
}

- (instancetype)init{
    if ([super init]) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _deviceDic = [[NSMutableDictionary alloc]init];
        _writeArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark - 获取值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(getPeripheral:)]) {
        [self.delegate getPeripheral:characteristic.value];
    }
    NSLog(@"收到数据 = %@",characteristic.value);
}

#pragma mark 数据写入成功回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(pushDevInfo)]) {
        [self.delegate pushDevInfo];
    }
    NSLog(@"数据写入成功");
}

#pragma mark 数据写入
- (void)writeDataInfo:(NSString *)info{
    if (self.characteristic.properties && CBCharacteristicPropertyWrite) {
        NSData *data = [info dataUsingEncoding:NSUTF8StringEncoding];
        [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }
}

#pragma mark 发现特征回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    self.peripheral = peripheral;
    self.characteristic = service.characteristics.lastObject;
    [peripheral setNotifyValue:true forCharacteristic:self.characteristic]; //接收
    
    __weak typeof(self)weakSelf = self;
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.value == nil) {
            [peripheral setNotifyValue:true forCharacteristic:obj]; //发送
            weakSelf.characteristic = obj;
        }
    }];
}

#pragma mark 发现服务回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
//    __block CBService * __nullable findService = nil;
    [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        findService = obj;
        if (obj) {
            [peripheral discoverCharacteristics:NULL forService:obj];
        }
    }];
    
//    if (findService){
//        [peripheral discoverCharacteristics:NULL forService:findService];
//    }
}

#pragma mark 连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(devDidFailToConnectPeripheral:error:)]) {
        [self.delegate devDidFailToConnectPeripheral:peripheral error:error];
    }
}

#pragma mark 设备连接断开
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self.deviceDic removeAllObjects];

    [self.centralManager scanForPeripheralsWithServices:NULL options:NULL]; //重新进入扫描状态
    
    if ([self.delegate respondsToSelector:@selector(devDidDisconnectPeripheral:error:)]) {
        [self.delegate devDidDisconnectPeripheral:peripheral error:error];
    }
}

#pragma mark 连接外设--成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self saveDeviceUuid:[NSString stringWithFormat:@"%@", peripheral.identifier]]; //保存连接过的设备
    
    [central stopScan];

    [peripheral discoverServices:NULL];
    
    if ([self.delegate respondsToSelector:@selector(devDidConnectPeripheral:)]) {
        [self.delegate devDidConnectPeripheral:peripheral];
    }
    NSLog(@"连接到名称为（%@）的设备-成功",peripheral.name);
}

#pragma mark 发现外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    peripheral.delegate = self;
    
    if ([self getDevicePeripheral].length != 0 && [[self getDevicePeripheral]isEqual:[NSString stringWithFormat:@"%@",peripheral.identifier]]) { //连接之前设备信息
        [self connectDeviceWithPeripheral:peripheral];
        [self stopScanBluetooth];
    }

    if (![self.deviceDic objectForKey:[peripheral name]]) {
        if (peripheral != nil) {
            if ([peripheral name] != nil) {
                
                [self.deviceDic setObject:peripheral forKey:[peripheral name]];
                
                    NSMutableArray *array = [NSMutableArray array];
                    [self.deviceDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([key isEqual:[peripheral name]]){
                            CBPeripheral *peripheral = obj;
                            [array addObject:peripheral];
                        }
                    }];

                if ([self.delegate respondsToSelector:@selector(devCoreBluetoothLists:)]) {
                    [self.delegate devCoreBluetoothLists:array];
                }
                 // 停止扫描, 看需求决定要不要加
//               [_centralManager stopScan];
            }
        }
    }
}

#pragma mark 搜索扫描外围设备
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>未知状态");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>重置");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>不支持");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>授权");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>蓝牙未开启");
            break;
        case CBCentralManagerStatePoweredOn:{
            NSLog(@">>>开始扫描。");
            [self.centralManager scanForPeripheralsWithServices:NULL options:NULL];
        }
            break;
        default:
            break;
    }
}

#pragma mark 保存之前连接的设备
- (NSUserDefaults *)saveDeviceUuid:(NSString *)uuid{
    NSUserDefaults *userinfo = [NSUserDefaults standardUserDefaults];
    [userinfo setObject:uuid forKey:@"CONNECTION_DEV"];
    [userinfo synchronize];
    return  userinfo;
}

#pragma mark 获取之前连接过的设备
- (NSString *)getDevicePeripheral{
    NSUserDefaults *userinfo = [NSUserDefaults standardUserDefaults];
    NSString *dev = [userinfo objectForKey:@"CONNECTION_DEV"];
    return dev;
}

#pragma mark 开始连接
- (void)connectDeviceWithPeripheral:(CBPeripheral *)peripheral{
    [self.centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark 取消连接蓝牙
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral{
    [self.centralManager cancelPeripheralConnection:peripheral];
}
#pragma mark 停止扫描
- (void)stopScanBluetooth{
    [self.centralManager stopScan];
}

@end
