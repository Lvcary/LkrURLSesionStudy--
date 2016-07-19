//
//  LkrSessionManager.h
//  LkrURLSesionStudy
//
//  Created by 刘康蕤 on 16/6/17.
//  Copyright © 2016年 刘康蕤. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LkrSessionManager : NSObject

/**
 *  创建断点续传的管理对象，启动下载请求
 *
 *  @param url        文件资源地址
 *  @param targetPath 文件存放路径
 *  @param success    文件下载成功的回调块
 *  @param failure    文件下载失败的回调块
 *  @param progress   文件下载进度的回调块
 *
 *  @return 断点续传的管理对象
 */
+ (LkrSessionManager *)sessionManagerWithURL:(NSURL *)url
                                  targetPath:(NSString *)targetPath
                                     success:(void (^)())success
                                     failure:(void (^)(NSError * error))failure
                                    progress:(void (^)(long long totalReceiveContentLenght, long long totalContentLenght))progress;
/**
 *  启动断电续传下载请求
 */
- (void)start;
/**
 *  取消断点续传下载请求
 */
- (void)cancel;

@end
