//
//  ViewController.m
//  CoreBluetoothDemo
//
//  Created by 冯超 on 2021/7/30.
//

#import "ViewController.h"
#import "CoreBluetoothManage.h"
#import "SVProgressHUD.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CoreBluetoothManageDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSMutableSet *valueSet;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor redColor];

    self.valueSet = [NSMutableSet set];

    [CoreBluetoothManage sharedManage];
    [CoreBluetoothManage sharedManage].delegate = self;

    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(10, self.view.frame.origin.y + self.view.frame.size.height/2 + 10, self.view.frame.size.width / 2, self.view.frame.size.height/2 - 20)];
    self.textView.backgroundColor = [UIColor orangeColor];
    self.textView.editable = false;
    [self.view addSubview:self.textView];

    self.dataArray = [NSMutableArray array];

    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, (self.view.frame.origin.y + self.view.frame.size.height / 2) - (self.view.frame.size.height/2), self.view.frame.size.width,self.view.frame.size.height/2) style:UITableViewStylePlain];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellForRowAtIndexPath"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    [self.view addSubview:self.tableView];
}

- (void)test:(NSArray *)array{
    NSString *dataStr = [array componentsJoinedByString:@""];
    NSArray *key_arr = @[@"0x5a 0xa5"];// 存放的指令
    NSMutableArray *value_Array = [NSMutableArray array];// 拿到最后的结果
    NSMutableArray *indexArray = [NSMutableArray arrayWithObject:[NSNumber numberWithInteger:dataStr.length]]; // 存放存在的每个指令下标____先添加整个字符串长度
    
    [key_arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([dataStr containsString:obj]) {
            [indexArray addObjectsFromArray:[self getRangeStr:dataStr findText:obj]];
        }
    }];
    
    [indexArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 intValue] > [obj2 intValue];
    }];
            
    [indexArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx + 1 < indexArray.count) {
            NSInteger index = [indexArray[idx + 1]integerValue] - [obj integerValue];
            NSString *value = [dataStr substringWithRange:NSMakeRange([obj integerValue],index)];
            [value_Array addObject:value];
        }
    }];
    NSLog(@"最终取得的数据:%@",value_Array);
}

#pragma mark - 获取这个字符串中的所有对象的所在的index
- (NSMutableArray *)getRangeStr:(NSString *)text findText:(NSString *)findText{
    NSMutableArray *arrayRanges = [NSMutableArray arrayWithCapacity:3];
    if (findText == nil && [findText isEqualToString:@""]){
        return nil;
    }
    
    NSRange rang = [text rangeOfString:findText]; //获取第一次出现的range
    if (rang.location != NSNotFound && rang.length != 0){
        [arrayRanges addObject:[NSNumber numberWithInteger:rang.location]];//将第一次的加入到数组中
        NSRange rang1 = {0,0};
        NSInteger location = 0;
        NSInteger length = 0;
        
        for (int i = 0;; i++){
            if (0 == i){
                location = rang.location + rang.length;
                length = text.length - rang.location - rang.length;
                rang1 = NSMakeRange(location, length);
            }else{
                location = rang1.location + rang1.length;
                length = text.length - rang1.location - rang1.length;
                rang1 = NSMakeRange(location, length);
            }
            //在一个range范围内查找另一个字符串的range
            rang1 = [text rangeOfString:findText options:NSCaseInsensitiveSearch range:rang1];
            if (rang1.location == NSNotFound && rang1.length == 0){
                break;
            }else//添加符合条件的location进数组
            [arrayRanges addObject:[NSNumber numberWithInteger:rang1.location]];
        }
        return arrayRanges;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellForRowAtIndexPath"];
    CBPeripheral *peripheral = self.dataArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",peripheral.name];
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CBPeripheral *peripheral = self.dataArray[indexPath.row];
     [[CoreBluetoothManage sharedManage]connectDeviceWithPeripheral:peripheral];
    
    NSLog(@"\n蓝牙名称:->%@\n蓝牙ID:->%@\n蓝牙状态:->%ld",peripheral.name,peripheral.identifier,(long)peripheral.state);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [[CoreBluetoothManage sharedManage]writeDataInfo:[NSString stringWithFormat:@"我是测试数据-1111111"]];
}

- (void)getPeripheral:(NSData *)data{
    if (self.valueSet.count != 0) {
        [self.valueSet removeAllObjects];
    }
    
    NSMutableArray *contArray = [NSMutableArray arrayWithObject:data];
    NSMutableArray *instructionArray = [NSMutableArray array];
    [contArray enumerateObjectsUsingBlock:^(NSData *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *str = [[NSString alloc]initWithData:obj encoding:NSUTF8StringEncoding];
        [instructionArray addObject:str];
//        Byte *byte = (Byte *)[obj bytes];
//        for(int i = 0; i < obj.length; i++){
//            [instructionArray addObject:[NSNumber numberWithInt:byte[i]]];
//        }
    }];
    
    [self.valueSet addObjectsFromArray:instructionArray];
    
    [self test:[self.valueSet allObjects]];
    
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
////        [self test:self.valueSet]
//        NSLog(@"%@",self.valueSet);
//    });
    
    
//    NSMutableArray *array = [NSMutableArray array];
//    [self.valueArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSString *str = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
//        if ([str containsString:@"5A"] && [str containsString:@"A5"]) {
//            [array addObject:str];
//        }
//    }];
//
//    NSLog(@"%@",array);
//    NSString *str = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
//    self.textView.text = str;
    
}

#pragma CoreBluetoothManageDelegate
- (void)pushDevInfo{
    [SVProgressHUD showSuccessWithStatus:@"数据写入成功,请在调试工具查看。"];
}

- (void)devCoreBluetoothLists:(nonnull NSMutableArray *)devsArray {
    [SVProgressHUD showWithStatus:@"设备搜索中..."];
    [self.dataArray addObjectsFromArray:devsArray];
    [self.tableView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });    
}

- (void)devDidConnectPeripheral:(nonnull CBPeripheral *)peripheral {
    NSLog(@"连接到名称为（%@）的设备-成功",peripheral.name);
    [SVProgressHUD showSuccessWithStatus:@"设备连接成功！"];
}

- (void)devDidDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self.dataArray removeAllObjects];
    [self.tableView reloadData];
    
    [SVProgressHUD showErrorWithStatus:@"连接断开，正在尝试重新连接中...."];
}

- (void)devDidFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nonnull NSError *)error {
    [SVProgressHUD showErrorWithStatus:@"设备连接失败"];
}

@end
