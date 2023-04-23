//
//  MKWebFileDownloader.h
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import <Foundation/Foundation.h>

@interface MKWebFileDownloader : NSObject

/// 是否在主线程回调（default: NO）
@property (nonatomic, assign) BOOL delegateOnMainThread;

/// 队列并发数（default: 6）
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

/// 设置任务超时时长
@property (nonatomic, assign) NSTimeInterval timeoutIntervalForRequest;

+ (instancetype)sharedInstance;

/**
 文件下载（默认路径、Normal优先级、非断点续传）
 
 @param URLString          下载链接
 @param progressHandler    进度回调
 @param completionHandler  完成回调
 */
- (NSURLSessionDataTask *)downloadWithURLString:(NSString *)URLString
                            progressHandler:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progressHandler
                          completionHandler:(void(^)(NSString *filePath, NSData *fileData, NSError *error))completionHandler;

/**
 文件下载（默认路径、Normal优先级）
 
 @param URLString          下载链接
 @param supportResume      支持断点续传（YES：支持；NO：不支持）
 @param progressHandler    进度回调
 @param completionHandler  完成回调
 */
- (NSURLSessionDataTask *)downloadWithURLString:(NSString *)URLString
                           supportResume:(BOOL)supportResume
                            progressHandler:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progressHandler
                          completionHandler:(void(^)(NSString *filePath, NSData *fileData, NSError *error))completionHandler;

/**
 文件下载
 
 @param URLString          下载链接
 @param directory          文件目录路劲
 @param queuePriority      队列优先级
 @param supportResume      支持断点续传
 @param progressHandler    进度回调
 @param completionHandler  完成回调
 */
- (NSURLSessionDataTask *)downloadWithURLString:(NSString *)URLString
                              supportResume:(BOOL)supportResume
                                  directory:(NSString *)directory
                              queuePriority:(NSOperationQueuePriority)queuePriority
                            progressHandler:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progressHandler
                          completionHandler:(void(^)(NSString *filePath, NSData *fileData, NSError *error))completionHandler;

@end
