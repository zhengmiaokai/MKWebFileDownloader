//
//  MKWebFileDownloadOperation.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/19.
//

#import "MKWebFileDownloadOperation.h"
#import "NSFileManager+FileDownload.h"

@interface MKWebFileDownloadOperation ()

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, copy) NSURL *downloadURL;

@property (nonatomic, strong) NSMutableData *downloadData;
@property (nonatomic, strong) NSFileHandle *writeHandle;
@property (nonatomic, assign) NSInteger totalBytesWritten;
@property (nonatomic, assign) NSInteger totalBytesExpectedToWrite;

@end

@implementation MKWebFileDownloadOperation

- (instancetype)initWithDownloadSession:(NSURLSession *)downloadSession {
    self = [super init];
    if (self) {
        self.downloadSession = downloadSession;
    }
    return self;
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
    self.dataTask = dataTask;
    
    return dataTask;;
}

- (void)start {
    [_dataTask resume];
}

- (void)cancel {
    [_dataTask cancel];
}

#pragma mark - NSURLSessionDelegate -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        if (_completionHandler) {
            _completionHandler(_downloadFilePath, nil, error);
        }
    } else {
        if (_supportResume) {
            [self.writeHandle closeFile];
            
            // 移动文件时，如果文件已存在会报错
            NSError *fileError = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:_downloadFilePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:_downloadFilePath error:&fileError];
            }
            [[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:_tmpFilePath] toURL:[NSURL fileURLWithPath:_downloadFilePath] error:&fileError];
        } else {
            [_downloadData writeToFile:_downloadFilePath atomically:YES];
        }
        
        self.totalBytesWritten = 0;
        self.totalBytesExpectedToWrite = 0;
        
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSError *netError = nil;
        if (response.statusCode/200 != 1) {
            // 删除本地缓存
            if ([[NSFileManager defaultManager] fileExistsAtPath:_downloadFilePath]) {
                NSError *fileError = nil;
                [[NSFileManager defaultManager] removeItemAtPath:_downloadFilePath error:&fileError];
            }
            
            if (_downloadData.length) {
                NSString* desc = [[NSString alloc] initWithData:_downloadData encoding:NSUTF8StringEncoding];
                netError = [NSError errorWithDomain:_downloadURL.absoluteString code:response.statusCode userInfo:@{@"message": desc}];
            } else {
                netError = [NSError errorWithDomain:_downloadURL.absoluteString code:response.statusCode userInfo:@{@"message": @"download fail"}];
            }
            
            if (_completionHandler) {
                _completionHandler(nil, nil, netError);
            }
        } else {
            if (_completionHandler) {
                _completionHandler(_downloadFilePath, [_downloadData copy], nil);
            }
        }
    }
}

#pragma mark - NSURLSessionDataTaskDelegate -
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [_downloadData appendData:data];
    self.totalBytesWritten += data.length;
    
    if (_supportResume) {
        [self.writeHandle seekToEndOfFile];
        [self.writeHandle writeData:data];
    }
    
    if (_progressHandler) {
        _progressHandler(_totalBytesWritten, _totalBytesExpectedToWrite);
    }
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
