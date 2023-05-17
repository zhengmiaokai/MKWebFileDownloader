//
//  MKDownloadUitls.h
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/23.
//

#import <Foundation/Foundation.h>

@interface MKDownloadUitls : NSObject

+ (void)performOnMainThread:(void(^)(void))block available:(BOOL)available;

+ (NSString *)MD5WithString:(NSString *)content;

@end


@interface NSFileManager (FileDownload)

/** 创建文件夹
 *  folderPath 路劲
 */
+ (BOOL)creatFolderWithPath:(NSString*)folderPath;

/** 创建文件--文件夹已经创建的情况
 *  filePath 路劲
 */
+ (BOOL)creatFileWithPath:(NSString*)filePath;

/** 查询绝对路劲文件是否存在
 *  filePath 文件路劲
 */
+ (BOOL)isExistsAtPath:(NSString*)filePath;

/** 删除文件
 *  filePath 文件路劲
 */
+ (BOOL)removefile:(NSString*)filePath;

@end
