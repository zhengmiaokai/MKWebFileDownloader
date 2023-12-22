# MKWebFileDownloader

基于NSOperationQueue与NSURLSessionDataTask实现的文件下载器（支持设置队列并发数量、任务优先级、断点续传）

```Objective-c
- (void)download {
    NSString *URLString = @"https://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.0.dmg";
    [[MKWebFileDownloader sharedInstance] downloadWithURLString:URLString supportResume:YES directory:nil queuePriority:NSOperationQueuePriorityNormal progressHandler:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSString *statusInfo = [NSString stringWithFormat:@"下载进度：%d%@", (int)(1.0*receivedSize/expectedSize * 100), @"%"];
        NSLog(@"%@", statusInfo);
    } completionHandler:^(NSString *filePath, NSData *fileData, NSError *error) {
        NSLog(@"下载完成");
    }];
}
```

<img width="265" alt="WeChat16372c25ff834ee3641a00cd173912f4" src="https://user-images.githubusercontent.com/13111933/233851292-25e17bd0-11a6-4b2c-b1a2-16a7ad6d9149.png">
