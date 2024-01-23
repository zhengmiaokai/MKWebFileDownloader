//
//  MKWebFileDownloader.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import "MKWebFileDownloader.h"
#import "MKDownloadUitls.h"
#import "MKWebFileDownloadOperation.h"

#define WFLOCK(...) dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self.lock);

@interface MKWebFileDownloader () <NSURLSessionDataDelegate> {
    NSString *_defaultDirectory;
}

/// 下载队列
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@property (nonatomic, strong) NSURLSession *downloadSession;

@property (nonatomic, strong) NSMutableDictionary *downloadOperations;
@property (nonatomic, strong) dispatch_semaphore_t lock;

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
        _downloadQueue.name = @"com.webFileDownloader.downloadQueue";
        
        self.downloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        
        self.downloadOperations = [NSMutableDictionary dictionary];
        self.lock = dispatch_semaphore_create(1);
        
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
            [MKDownloadUitls performOnMainThread:^{
                NSError *fileError = [NSError errorWithDomain:URLString code:-1 userInfo:@{@"message": @"存储路劲异常"}];
                completionHandler(nil, nil, fileError);
            } available:self.delegateOnMainThread];
        }
        return nil;
    }
    
    NSString *fileKey = [MKDownloadUitls MD5WithString:URLString];
    NSURL* URL = [NSURL URLWithString:URLString];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", fileKey, URL.pathExtension];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    
    if ([NSFileManager isExistsAtPath:filePath]) { // 文件已下载
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *fileData = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
            if (completionHandler) {
                [MKDownloadUitls performOnMainThread:^{
                    completionHandler(filePath, fileData, nil);
                } available:self.delegateOnMainThread];
            }
        });
        return nil;
    } else {
        WFLOCK(MKWebFileDownloadOperation *downloadOperation = [self.downloadOperations objectForKey:fileKey]);
        if (downloadOperation) {
            [downloadOperation addProgressHandler:progressHandler completionHandler:completionHandler];
        } else {
            downloadOperation = [[MKWebFileDownloadOperation alloc] initWithDownloadSession:self.downloadSession];
            downloadOperation.supportResume = supportResume;
            downloadOperation.delegateOnMainThread = _delegateOnMainThread;
            downloadOperation.queuePriority = queuePriority;
            downloadOperation.downloadFilePath = filePath;
            downloadOperation.tmpFilePath = [directory stringByAppendingPathComponent:fileKey];
            [downloadOperation addProgressHandler:progressHandler completionHandler:completionHandler];
            [downloadOperation dataTaskWithURL:URL];
            
            __weak typeof(self) weakSelf = self;
            [downloadOperation setCompletionHandler:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                WFLOCK([strongSelf.downloadOperations removeObjectForKey:fileKey]);
            }];
            WFLOCK([self.downloadOperations setObject:downloadOperation forKey:fileKey]);
            
            [self.downloadQueue addOperation:downloadOperation];
        }
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
