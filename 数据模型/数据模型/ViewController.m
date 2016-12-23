//
//  ViewController.m
//  数据模型
//
//  Created by IOS_HMX on 16/12/8.
//  Copyright © 2016年 humingxing. All rights reserved.
//

#import "ViewController.h"
#import "Foo.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    Foo *f = [Foo new ];
    f.name = @"111";
    f.array = @[@1];
    f.count = @(10);
    
    Foo *f2 = [f copy];
    NSLog(@"%@   %ld   %@",f2.name,[f2.count integerValue],f2.array);
    
    NSArray *doc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    [NSKeyedArchiver archiveRootObject:f toFile:[[doc objectAtIndex:0] stringByAppendingPathComponent:@"222"]];
    
    Foo *f3 = [NSKeyedUnarchiver unarchiveObjectWithFile:[[doc objectAtIndex:0] stringByAppendingPathComponent:@"222"]];
    NSLog(@"%@   %ld   %@",f3.name,[f3.count integerValue],f3.array);
    NSLog(@"%@",f.description);
    if ([f2 isEqual:f3]) {
        NSLog(@"equal");
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
