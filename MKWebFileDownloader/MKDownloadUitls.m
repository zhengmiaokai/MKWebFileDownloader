//
//  MKDownloadUitls.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/23.
//

#import "MKDownloadUitls.h"
#include <CommonCrypto/CommonCrypto.h>

@implementation MKDownloadUitls

+ (void)performOnMainThread:(void(^)(void))block available:(BOOL)available {
    if (!block) return;
    
    if (!available) {
        block();
    } else {
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block();
            });
        }
    }
}

+ (NSString *)MD5WithString:(NSString *)content {
    if (content.length == 0) return @"";
    
    const char *cStr = [content UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *ret = [NSMutableString string];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02X",result[i]]; //X为大写
    }
    return [ret lowercaseString];
}

@end


@implementation NSFileManager (FileDownload)

/** 创建文件夹
 *  folderPath 路劲
 */
+ (BOOL)creatFolderWithPath:(NSString*)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    if(!(isDirExist && isDir)) {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            return NO;
        }
    }
    return YES;
}

/** 创建文件--文件夹已经创建的情况
 *  filePath 路劲
 */
+ (BOOL)creatFileWithPath:(NSString*)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if(!isDirExist) {
        BOOL bCreateDir = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        if(!bCreateDir){
            return NO;
        }
    }
    return YES;
}

/** 查询绝对路劲文件是否存在
 *  filePath 文件路劲
 */
+ (BOOL)isExistsAtPath:(NSString*)filePath {
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return isExists;
}

/** 删除文件
 *  filePath 文件路劲
 */
+ (BOOL)removefile:(NSString*)filePath {
    NSError* error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    
    if (error == nil) {
        return YES;
    } else {
        return NO;
    }
}

@end

