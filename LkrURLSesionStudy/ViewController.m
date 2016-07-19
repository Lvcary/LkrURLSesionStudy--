//
//  ViewController.m
//  LkrURLSesionStudy
//
//  Created by 刘康蕤 on 16/6/17.
//  Copyright © 2016年 刘康蕤. All rights reserved.
//

#import "ViewController.h"
#import "LkrSessionManager.h"

@interface ViewController ()

@property (nonatomic, strong) LkrSessionManager *manager;
@property (nonatomic, strong) NSString *targetPath;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.deleteBtn.hidden = YES;
    
    
    
}
- (IBAction)startDown:(id)sender {
    if (self.manager) {
        [self.manager cancel];
        self.manager = nil;
    }
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    self.targetPath = [documentsDirectory stringByAppendingString:@"mypic"];
    
    NSURL *url = [NSURL URLWithString:@"http://p1.pichost.me/i/40/1639665.png"];
    
    self.manager = [LkrSessionManager sessionManagerWithURL:url
                                                 targetPath:self.targetPath
                                                    success:^{
                                                        
                                                        self.imageView.image = [UIImage imageWithContentsOfFile:self.targetPath];
                                                        self.deleteBtn.hidden = NO;
                                                    } failure:^(NSError *error) {
                                                        
                                                    } progress:^(long long totalReceiveContentLenght, long long totalContentLenght) {
                                                        
                                                        float percent = 1.0 * totalReceiveContentLenght / totalContentLenght;
                                                        NSString *strPersent = [[NSString alloc]initWithFormat:@"%.f", percent *100];
                                                        self.progress.progress = percent;
                                                        self.label.text = [NSString stringWithFormat:@"已下载%@%%", strPersent];
                                                    }];
    [self.manager start];
}

- (IBAction)puase:(id)sender {
    [self.manager cancel];
    self.manager = nil;
}

- (IBAction)delete:(id)sender {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    [manager removeItemAtPath:self.targetPath error:&error];
    
    if (error == nil) {
        
        self.imageView.image = [UIImage imageWithContentsOfFile:self.targetPath];
        self.progress.progress = 0;
        self.label.text = nil;
        
        self.deleteBtn.hidden = YES;
    }
}

@end
