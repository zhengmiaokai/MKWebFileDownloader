//
//  ViewController.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/23.
//

#import "ViewController.h"
#import "MKWebFileDownloader.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [MKWebFileDownloader sharedInstance].delegateOnMainThread = YES;
    [MKWebFileDownloader sharedInstance].maxConcurrentOperationCount = 5;
}

- (IBAction)download:(id)sender {
    self.downloadBtn.enabled = NO;
    self.textField.enabled = NO;
    
    /* https://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.0.dmg
       https://dldir1.qq.com/weixin/mac/WeChat_2.3.17.18.dmg */
    [[MKWebFileDownloader sharedInstance] downloadWithURLString:_textField.text supportResume:YES directory:nil queuePriority:NSOperationQueuePriorityNormal progressHandler:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSString *statusInfo = [NSString stringWithFormat:@"下载进度：%d%@", (int)(1.0*receivedSize/expectedSize * 100), @"%"];
        self.statusLab.text = statusInfo;
    } completionHandler:^(NSString *filePath, NSData *fileData, NSError *error) {
        NSLog(@"下载完成");
        self.statusLab.text = @"下载完成";
        self.downloadBtn.enabled = YES;
        self.textField.enabled = YES;
    }];
    
    /* 文件下载（默认路径、Normal优先级、非断点续传）
    [[MKWebFileDownloader sharedInstance] downloadWithURLString:_textField.text progressHandler:^(NSInteger receivedSize, NSInteger expectedSize) {
        
    } completionHandler:^(NSString *filePath, NSData *fileData, NSError *error) {
        
    }];
     */
}

@end
