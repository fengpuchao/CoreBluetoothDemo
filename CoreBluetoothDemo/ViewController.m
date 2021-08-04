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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
    
    [CoreBluetoothManage sharedManage].delegate = self;
    
    self.textView = [[UITextView alloc]initWithFrame:CGRectMake(10, self.view.frame.origin.x + self.view.frame.size.height - 480, self.view.frame.size.width / 2, 450)];
    self.textView.backgroundColor = [UIColor orangeColor];
    self.textView.editable = false;
    [self.view addSubview:self.textView];
    
    self.dataArray = [NSMutableArray array];
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 500) style:UITableViewStylePlain];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellForRowAtIndexPath"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    [self.view addSubview:self.tableView];
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

- (void)getPeripheral:(NSData *)value{
    NSString *str = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    self.textView.text = str;
}

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
