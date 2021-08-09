//
//  CoreBluetoothManage.m
//  CoreBluetoothDemo
//
//  Created by 冯超 on 2021/7/31.
//

#import "CoreBluetoothManage.h"

@interface CoreBluetoothManage ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (nonatomic, strong) NSMutableDictionary *deviceDic;
@property (nonatomic, strong) NSMutableArray <CBCharacteristic *>*characteristicArray;
@property (nonatomic, strong) NSMutableArray *valueArray;


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
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()options:nil];
        _deviceDic = [[NSMutableDictionary alloc]init];
        _characteristicArray = [NSMutableArray array];
    }
    return self;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(getPeripheral:)]) {
        [self.delegate getPeripheral:characteristic.value];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(pushDevInfo)]) {
        [self.delegate pushDevInfo];
    }
}

- (void)writeDataInfo:(NSString *)info{
    __weak typeof(self)weakSelf = self;
    [self.characteristicArray enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSData *data = [info dataUsingEncoding:NSUTF8StringEncoding];
        [weakSelf.peripheral writeValue:data forCharacteristic:obj type:CBCharacteristicWriteWithResponse];
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    self.peripheral = peripheral;
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [peripheral setNotifyValue:true forCharacteristic:obj];
    }];
    
    [self.characteristicArray addObjectsFromArray:service.characteristics];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    [peripheral.services enumerateObjectsUsingBlock:^(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj) {
            [peripheral discoverCharacteristics:NULL forService:obj];
        }
    }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self.centralManager scanForPeripheralsWithServices:NULL options:NULL];
    if ([self.delegate respondsToSelector:@selector(devDidFailToConnectPeripheral:error:)]) {
        [self.delegate devDidFailToConnectPeripheral:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self.deviceDic removeAllObjects];

    [self.centralManager scanForPeripheralsWithServices:NULL options:NULL];
    
    if ([self.delegate respondsToSelector:@selector(devDidDisconnectPeripheral:error:)]) {
        [self.delegate devDidDisconnectPeripheral:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [central stopScan];

    [peripheral discoverServices:NULL];
    
    if ([self.delegate respondsToSelector:@selector(devDidConnectPeripheral:)]) {
        [self.delegate devDidConnectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    peripheral.delegate = self;
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
            }
        }
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    self.state = central.state;
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            break;
        case CBCentralManagerStateResetting:
            break;
        case CBCentralManagerStateUnsupported:
            break;
        case CBCentralManagerStateUnauthorized:
            break;
        case CBCentralManagerStatePoweredOff:
            break;
        case CBCentralManagerStatePoweredOn:{
            [self.centralManager scanForPeripheralsWithServices:NULL options:NULL];
        }
            break;
        default:
            break;
    }
}

#pragma mark 停止扫描
- (void)stopScanBluetooth{
    [self.centralManager stopScan];
}

#pragma mark 取消连接蓝牙
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral{
    [self.centralManager cancelPeripheralConnection:peripheral];
}

#pragma mark 开始连接
- (void)connectDeviceWithPeripheral:(CBPeripheral *)peripheral{
    [self.centralManager connectPeripheral:peripheral options:nil];
}

@end
