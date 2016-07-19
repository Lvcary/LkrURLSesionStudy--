//
//  LkrSessionManager.m
//  LkrURLSesionStudy
//
//  Created by 刘康蕤 on 16/6/17.
//  Copyright © 2016年 刘康蕤. All rights reserved.
//

#import "LkrSessionManager.h"

typedef void(^completionBlock)();
typedef void(^pregressBlock)();

@interface LkrSessionManager()<NSURLSessionDelegate,NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;    //注意一个session只能有一个请求任务
@property (nonatomic, strong) NSURL * url;                          ///< 文件资源地址
@property (nonatomic, strong) NSString * targetPath;                ///< 文件储存地址

@property(nonatomic, readwrite, retain) NSError *error; //请求出错
@property (nonatomic, copy) completionBlock completionBlock;
@property (nonatomic, copy) pregressBlock pregressBlock;

@property (nonatomic, assign) long long totalContentLeght;          ///< 文件的总大小
@property (nonatomic, assign) long long totalReceiveContentLenght;  ///< 文件接收到的总大小

/**
 *  设置成功、失败回调block
 *
 *  @param success 成功回调block
 *  @param failure 失败回调block
 */
- (void)setcompletionWithSuccess:(void (^)())success
                         failure:(void (^)(NSError *))failure;

/**
 *  设置进度回调block
 *
 *  @param progress 进度值
 */
- (void)setprogrssBlockWithProgress:(void (^)(long long totalReceivedContentLenght, long long totalContentLenght))progress;

/**
 *  获取文件的大小
 *
 *  @param path 文件路径
 *
 *  @return 文件大小
 */
- (long long)fileSizeForPath:(NSString *)path;

@end

@implementation LkrSessionManager


/**
 *  设置成功、失败回调block
 *
 *  @param success 成功回调block
 *  @param failure 失败回调block
 */
- (void)setcompletionWithSuccess:(void (^)())success
                         failure:(void (^)(NSError *))failure {
    
    __weak typeof(self) weakSelf = self;
    
    self.completionBlock = ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (weakSelf.error) {
                if (failure) {
                    failure(weakSelf.error);
                }
            }else {
                if (success) {
                    success();
                }
            }
        });
    };
}

/**
 *  设置进度回调block
 *
 *  @param progress
 */
- (void)setprogrssBlockWithProgress:(void (^)(long long totalReceivedContentLenght, long long totalContentLenght))progress {
    
    __weak typeof(self) weakSelf = self;
    self.pregressBlock = ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            progress(weakSelf.totalReceiveContentLenght, weakSelf.totalContentLeght);
        });
    };
}

/**
 *  获取文件的大小
 *
 *  @param path 文件路径
 *
 *  @return 文件大小
 */
- (long long)fileSizeForPath:(NSString *)path {

    long long fileSize = 0;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        
        NSError * error = nil;
        NSDictionary * fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (fileDict && !error) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

#pragma mark   /********  断点续传对象的  创建 启动 取消  ********/
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
                                     failure:(void (^)(NSError *))failure
                                    progress:(void (^)(long long totalReceiveContentLenght, long long totalContentLenght))progress {
    
    LkrSessionManager * manager = [[LkrSessionManager alloc] init];
    
    manager.url = url;
    manager.targetPath = targetPath;
    
    [manager setcompletionWithSuccess:success failure:failure];
    [manager setprogrssBlockWithProgress:progress];
    
    manager.totalContentLeght = 0;
    manager.totalReceiveContentLenght = 0;
    
    return manager;
}

/**
 *  启动断点续传下载请求
 */
- (void)start {
    
    // 下载请求
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:self.url];
    
    // 下载好的文件大小
    long long downloadBytes = self.totalReceiveContentLenght = [self fileSizeForPath:self.targetPath];
    
    if (downloadBytes > 0) {
        
        // 设置请求头
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-",downloadBytes];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }else {
        
        int fileDescriptor = open([self.targetPath UTF8String], O_CREAT | O_EXCL | O_RDWR, 0666);
        if (fileDescriptor > 0) {
            close(fileDescriptor);
        }
    }
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:queue];
    
    NSURLSessionDataTask * dataTask = [self.session dataTaskWithRequest:request];
    [dataTask resume];
}

/**
 *  取消断点续传下载请求
 */
- (void)cancel {
    if (self.session) {
        
        [self.session invalidateAndCancel];
        self.session = nil;
    }
}

#pragma mark /******* NSURLSessionDelegate ********/
/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {

    NSLog(@"didBecomeInvalidWithError");
}


#pragma mark /********** NSURLSessionDataDelegate ***********/
/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {

    NSLog(@"didCompleteWithError");
    if (error == nil && self.error == nil) {
    
        self.completionBlock();
    }else if (error != nil){
        
        if (error.code != -999) {
            
            self.error = error;
            self.completionBlock();
        }
    }else if (self.error != nil) {
        self.completionBlock();
    }
}

/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    // 根据status code的不同。做相应的处理
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)dataTask.response;
    if (response.statusCode == 200) {
        
        self.totalContentLeght = dataTask.countOfBytesExpectedToReceive;
    }else if (response.statusCode == 206) {
        // 206——服务器已经完成了部分用户的GET请求
        NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
        if ([contentRange hasPrefix:@"bytes"]) {
            NSArray * bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            if (bytes.count == 4) {
                self.totalContentLeght = [[bytes objectAtIndex:3] longLongValue];
            }
        }
    }else if (response.statusCode == 416) {
    
        NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
        if ([contentRange hasPrefix:@"bytes"]) {
            NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
            if ([bytes count] == 3) {
                
                self.totalContentLeght = [[bytes objectAtIndex:2] longLongValue];
                if (self.totalContentLeght == self.totalReceiveContentLenght) {
                    
                    // 说明已下载完  更新进度
                    self.pregressBlock();
                }else {
                    // 请求中包含Range请求头字段，在当前请求资源范围内没有range指示值，请求
                    // 也不包含If-Range请求头字段
                    self.error = [[NSError alloc] initWithDomain:[self.url absoluteString]
                                                            code:416
                                                        userInfo:response.allHeaderFields];
                }
            }
        }
        return;
    }else {
        
        // 其他情况
    }
    
    // 向文件追加数据
    NSFileHandle * fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.targetPath];
    [fileHandle seekToEndOfFile];  // 将节点跳到文件的末尾
    
    [fileHandle writeData:data]; // 追加写入数据
    [fileHandle closeFile];
    
    // 更新进度
    self.totalReceiveContentLenght += data.length;
    self.pregressBlock();
}

@end
