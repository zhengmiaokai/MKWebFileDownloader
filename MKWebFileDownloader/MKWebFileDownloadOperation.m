//
//  MKWebFileDownloadOperation.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import "MKWebFileDownloadOperation.h"
#import "MKDownloadUitls.h"

#define WFLOCK(...) dispatch_semaphore_wait(self.lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(self.lock);

@interface MKWebFileDownLoadHandler : NSObject

@property (nonatomic, copy) MKWebFileDownloadProgressHandler progressHandler;

@property (nonatomic, copy) MKWebFileDownloadCompletionHandler completionHandler;

@end

@implementation MKWebFileDownLoadHandler

@end


@interface MKWebFileDownloadOperation ()

@property (nonatomic, strong) NSURLSession *downloadSession;

@property (nonatomic, strong) NSMutableArray *downloadHandlers;
@property (nonatomic, strong) dispatch_semaphore_t lock;

@property (nonatomic, copy) NSURL *downloadURL;

@property (nonatomic, strong) NSMutableData *downloadData;
@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, assign) NSInteger totalBytesWritten;
@property (nonatomic, assign) NSInteger totalBytesExpectedToWrite;

@end

@implementation MKWebFileDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithDownloadSession:(NSURLSession *)downloadSession {
    self = [super init];
    if (self) {
        self.downloadSession = downloadSession;
        self.downloadHandlers = [NSMutableArray arrayWithCapacity:1];
        self.lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    // 释放下载任务
}

- (void)addProgressHandler:(MKWebFileDownloadProgressHandler)progressHandler completionHandler:(MKWebFileDownloadCompletionHandler)completionHandler {
    MKWebFileDownLoadHandler* downloadHandler = [[MKWebFileDownLoadHandler alloc] init];
    downloadHandler.progressHandler = progressHandler;
    downloadHandler.completionHandler = completionHandler;
    WFLOCK([_downloadHandlers addObject:downloadHandler]);
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)URL {
    self.downloadURL = URL;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    if (_supportResume) {
        self.downloadData = [[NSMutableData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:_tmpFilePath]];
        self.totalBytesWritten = _downloadData.length;
        
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", _totalBytesWritten];
        [request setValue:range forHTTPHeaderField:@"Range"];
    }
   
    NSURLSessionDataTask *dataTask = [_downloadSession dataTaskWithRequest:request];
    _dataTask = dataTask;
    
    return dataTask;;
}

- (void)start {
    [_dataTask resume];
}

- (void)cancel {
    [_dataTask cancel];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    
    if (_completionHandler) {
        _completionHandler();
    }
}

#pragma mark - NSURLSessionDelegate -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self handleCompletion:nil fileData:nil error:error];
    } else {
        if (_supportResume) {
            [self.writeHandle closeFile];
            self.writeHandle = nil;
            
            // 移动文件时，如果文件已存在会报错
            NSError *fileError = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:_downloadFilePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:_downloadFilePath error:&fileError];
            }
            [[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:_tmpFilePath] toURL:[NSURL fileURLWithPath:_downloadFilePath] error:&fileError];
            
            if (fileError) { // 文件操作失败时，回调异常信息，结束Operation
                [self handleCompletion:nil fileData:nil error:fileError];
                [self done];
                return;
            }
        } else {
            [_downloadData writeToFile:_downloadFilePath atomically:YES];
        }
        
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        
        if ((response.statusCode >= 200 && response.statusCode <= 299) && (_totalBytesExpectedToWrite == NSURLResponseUnknownLength || _downloadData.length == _totalBytesExpectedToWrite)) {
            [self handleCompletion:_downloadFilePath fileData:[_downloadData copy] error:nil];
        } else {
            // 删除本地缓存
            if ([[NSFileManager defaultManager] fileExistsAtPath:_downloadFilePath]) {
                NSError *fileError = nil;
                [[NSFileManager defaultManager] removeItemAtPath:_downloadFilePath error:&fileError];
            }
            
            NSError *netError = [NSError errorWithDomain:_downloadURL.absoluteString code:response.statusCode userInfo:@{@"message": @"download fail"}];
            [self handleCompletion:nil fileData:nil error:netError];
        }
    }
    [self done];
}

- (void)handleCompletion:(NSString *)filePath fileData:(NSData *)fileData error:(NSError *)error {
    [MKDownloadUitls performOnMainThread:^{
        WFLOCK(NSArray* downloadHandlers = [self.downloadHandlers copy]);
        for (MKWebFileDownLoadHandler *downLoadHandler in downloadHandlers) {
            if (downLoadHandler.completionHandler) {
                downLoadHandler.completionHandler(filePath, fileData, error);
            }
        }
    } available:_delegateOnMainThread];
    
    self.totalBytesWritten = 0;
    self.totalBytesExpectedToWrite = 0;
}

#pragma mark - NSURLSessionDataTaskDelegate -
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_downloadData appendData:data];
    self.totalBytesWritten += data.length;
    
    if (_supportResume) {
        [self.writeHandle seekToEndOfFile];
        [self.writeHandle writeData:data];
    }
    
    [MKDownloadUitls performOnMainThread:^{
        WFLOCK(NSArray* downloadHandlers = [self.downloadHandlers copy]);
        for (MKWebFileDownLoadHandler *downLoadHandler in downloadHandlers) {
            if (downLoadHandler.progressHandler) {
                downLoadHandler.progressHandler(self.totalBytesWritten, self.totalBytesExpectedToWrite);
            }
        }
    } available:_delegateOnMainThread];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (!_downloadData) {
        _downloadData = [[NSMutableData alloc] init];
    }
    self.totalBytesExpectedToWrite = response.expectedContentLength + _totalBytesWritten;
    
    if (_supportResume) {
        if ([NSFileManager creatFileWithPath:_tmpFilePath]) {
            self.writeHandle = [NSFileHandle fileHandleForWritingAtPath:_tmpFilePath];
        }
    } else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:_tmpFilePath]) {
            // 移除tmp缓存
            NSError *fileError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:_tmpFilePath error:&fileError];
        }
    }
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

@end
