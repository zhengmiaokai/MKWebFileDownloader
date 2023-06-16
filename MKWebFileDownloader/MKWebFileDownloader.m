//
//  MKWebFileDownloader.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import "MKWebFileDownloader.h"
#import "MKDownloadUitls.h"
#import "MKWebFileDownloadOperation.h"

@interface MKWebFileDownloader () <NSURLSessionDataDelegate> {
    NSString *_defaultDirectory;
}

/// 下载队列
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@property (nonatomic, strong) NSURLSession *downloadSession;

@end

@implementation MKWebFileDownloader

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloadQueue = [[NSOperationQueue alloc]init];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"com.Base.MKWebFileDownloader";
        
        self.downloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        _defaultDirectory = [cachesPath stringByAppendingPathComponent:NSStringFromClass([self class])];
    }
    return self;
}

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (void)setTimeoutIntervalForRequest:(NSTimeInterval)timeoutIntervalForRequest {
    _timeoutIntervalForRequest = timeoutIntervalForRequest;
    _downloadSession.configuration.timeoutIntervalForRequest = timeoutIntervalForRequest;
}

- (NSURLSessionDataTask *)downloadWithURLString:(NSString *)URLString
                            progressHandler:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progressHandler
                          completionHandler:(void(^)(NSString *filePath, NSData *fileData, NSError *error))completionHandler {
    return [self downloadWithURLString:URLString supportResume:NO directory:_defaultDirectory queuePriority:NSOperationQueuePriorityNormal progressHandler:progressHandler completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)downloadWithURLString:(NSString *)URLString
                              supportResume:(BOOL)supportResume
                            progressHandler:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progressHandler
                          completionHandler:(void(^)(NSString *filePath, NSData *fileData, NSError *error))completionHandler {
    return [self downloadWithURLString:URLString supportResume:supportResume directory:_defaultDirectory queuePriority:NSOperationQueuePriorityNormal progressHandler:progressHandler completionHandler:completionHandler];
}

- (NSURLSessionDataTask *)downloadWithURLString:(NSString *)URLString
                              supportResume:(BOOL)supportResume
                                  directory:(NSString *)directory
                              queuePriority:(NSOperationQueuePriority)queuePriority
                            progressHandler:(void(^)(NSInteger receivedSize, NSInteger expectedSize))progressHandler
                          completionHandler:(void(^)(NSString *filePath, NSData *fileData, NSError *error))completionHandler {
    
    directory = (directory ? directory:_defaultDirectory);
    if (![NSFileManager creatFolderWithPath:directory]) {
        if (completionHandler) {
            NSError *fileError = [NSError errorWithDomain:URLString code:-1 userInfo:@{@"message": @"存储路劲异常"}];
            completionHandler(nil, nil, fileError);
        }
        return nil;
    }
    
    NSURL* URL = [NSURL URLWithString:URLString];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", [MKDownloadUitls MD5WithString:URL.absoluteString], URL.pathExtension];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    if ([NSFileManager isExistsAtPath:filePath]) {
        // 文件已下载
        NSData *fileData = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
        if (completionHandler) {
            completionHandler(filePath, fileData, nil);
        }
        return nil;
    } else {
        MKWebFileDownloadOperation *downloadOperation = [[MKWebFileDownloadOperation alloc] initWithDownloadSession:_downloadSession];
        downloadOperation.supportResume = supportResume;
        downloadOperation.delegateOnMainThread = _delegateOnMainThread;
        downloadOperation.queuePriority = queuePriority;
        downloadOperation.downloadFilePath = filePath;
        downloadOperation.tmpFilePath = [directory stringByAppendingPathComponent:[MKDownloadUitls MD5WithString:URL.absoluteString]];
        downloadOperation.progressHandler = progressHandler;
        downloadOperation.completionHandler = completionHandler;
        [downloadOperation dataTaskWithURL:URL];
        [self.downloadQueue addOperation:downloadOperation];
        
        return downloadOperation.dataTask;
    }
}

#pragma mark - NSURLSessionTaskDelegate -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    MKWebFileDownloadOperation *downloadOperation = [self operationWithTask:task];
    if (downloadOperation) {
        [downloadOperation URLSession:session task:task didCompleteWithError:error];
    } else {
        // 无效操作
    }
}

#pragma mark - NSURLSessionDataTaskDelegate -
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MKWebFileDownloadOperation *downloadOperation = [self operationWithTask:dataTask];
    if (downloadOperation) {
        [downloadOperation URLSession:session dataTask:dataTask didReceiveData:data];
    } else {
        // 无效操作
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    MKWebFileDownloadOperation *downloadOperation = [self operationWithTask:dataTask];
    if (downloadOperation) {
        [downloadOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    } else {
        // 无效操作
    }
}

#pragma mark - Getter -
- (MKWebFileDownloadOperation *)operationWithTask:(NSURLSessionTask *)task {
    MKWebFileDownloadOperation *resultOperation = nil;
    for (MKWebFileDownloadOperation *operation in _downloadQueue.operations) {
        if ([operation respondsToSelector:@selector(dataTask)]) {
            NSURLSessionTask *dataTask;
            @synchronized (operation) {
                dataTask = operation.dataTask;
            }
            if (dataTask.taskIdentifier == task.taskIdentifier) {
                resultOperation = operation;
                break;
            }
        }
    }
    return resultOperation;
}

@end
