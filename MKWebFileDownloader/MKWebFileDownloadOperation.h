//
//  MKWebFileDownloadOperation.h
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import <Foundation/Foundation.h>

@interface MKWebFileDownloadOperation : NSOperation <NSURLSessionDataDelegate>

@property (nonatomic, copy) NSString *downloadFilePath;

/// 是否支持断点续传
@property (nonatomic, assign) BOOL supportResume;
@property (nonatomic, copy) NSString *tmpFilePath;

@property (nonatomic, copy) void(^progressHandler)(NSInteger receivedSize, NSInteger expectedSize);
@property (nonatomic, copy) void(^completionHandler)(NSString *filePath, NSData *fileData, NSError *error);

- (instancetype)initWithDownloadSession:(NSURLSession *)downloadSession;

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)URL;

@end
