//
//  NSFileManager+FileDownload.m
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/23.
//

#import "NSFileManager+FileDownload.h"

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
    }
    else{
        return NO;
    }
    return success;
}

@end


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

@end
