# LkrURLSesionStudy--
断点续传
```
使用NSURLSession和NSURLSessionDataTask实现断点续传的过程是：
1.配置NSMutableURLRequest对象的Range请求头字段信息
2.创建使用代理的NSURLSession对象
3.使用NSURLSession对象和NSMutableURLRequest对象创建NSURLSessionDataTask对象，启动任务。
4.在NSURLSessionDataDelegate的didReceiveData方法中追加获取下载数据到目标文件。
