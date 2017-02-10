//
//  ViewController.m
//  ZYZAlertViewExample
//
//  Created by AsiaZhang on 17/2/9.
//  Copyright © 2017年 zhifu360. All rights reserved.
//

#import "ViewController.h"
#import "ZYZAlert.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //UIButton *smartCarButton = []
}

- (IBAction)smartCarButton:(UIButton *)sender {
    ZYZAlertView *alert = [[ZYZAlertView alloc]initWithStyle:ZYZAlertViewStyleSmartCar Title:@"智慧汽车网" message:@"我的车生活" customView:nil delegate:nil cancelButtonTitle:@"稍后更新" otherButtonTitles:@"去更新"];
    [alert setCancelBlock:^{
        
    }];
    [alert setConfirmBlock:^{
        
    }];
    [alert show];
}
- (IBAction)rightCornerButton:(UIButton *)sender {
    ZYZAlertView *alert = [[ZYZAlertView alloc]initWithStyle:ZYZAlertViewStyleRightCornerCancle Title:@"智富贷" message:@"我的车贷" customView:nil delegate:nil cancelButtonTitle:@"稍后更新" otherButtonTitles:@"去更新"];
    [alert setCancelBlock:^{
        
    }];
    [alert setConfirmBlock:^{
        
    }];
    [alert show];
}
- (IBAction)toastButton:(UIButton *)sender {
    ZYZToastView *toast = [[ZYZToastView alloc]initWithView:self.view message:@"toast" posY:100];
    [toast show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
