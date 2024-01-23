//
//  MKWebFileDownloadOperation.h
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import <Foundation/Foundation.h>

typedef void(^MKWebFileDownloadProgressHandler)(NSInteger receivedSize, NSInteger expectedSize);
typedef void(^MKWebFileDownloadCompletionHandler)(NSString *filePath, NSData *fileData, NSError *error);

@interface MKWebFileDownloadOperation : NSOperation <NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;

// 文件存储路劲
@property (nonatomic, copy) NSString *downloadFilePath;

/// 是否支持断点续传
@property (nonatomic, assign) BOOL supportResume;
@property (nonatomic, copy) NSString *tmpFilePath;

/// 是否在主线程回调（default: NO）
@property (nonatomic, assign) BOOL delegateOnMainThread;

@property (nonatomic, copy) void(^completionHandler)(void);

- (instancetype)initWithDownloadSession:(NSURLSession *)downloadSession;

- (void)addProgressHandler:(MKWebFileDownloadProgressHandler)progressHandler completionHandler:(MKWebFileDownloadCompletionHandler)completionHandler;

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)URL;

@end
