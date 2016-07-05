//
//  ViewController.m
//  服务端
//
//  Created by 熊欣 on 16/6/29.
//  Copyright © 2016年 熊欣. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

/** 这个端口可以随便设置*/
#define TEST_IP_PROT 22235
/** 替换成你当前连接的WIFI的IP地址*/
#define TEST_IP_ADDR "192.168.1.115"

@interface ViewController ()
@end

@implementation ViewController

CFWriteStreamRef writeStreamRef;
CFReadStreamRef  readStreamRef;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self initSocket];
    
    
  
    
    
    
}

-(void)initSocket {
    
    @autoreleasepool {
        
        //创建Socket，指定TCPServerAcceptCallBack
        //作为kCFFSocketAcceptCallBack事件的监听函数
        CFSocketRef _socket = CFSocketCreate(kCFAllocatorDefault,
                                             PF_INET,/*指定协议族，如果参数为0或者负数，则默认为PF_INET*/
                                             SOCK_STREAM,/*指定Socket类型，如果协议族为PF_INET，且该参数为0或者负数，则它会默认为SOCK_STREAM,如果要使用UDP协议，则该参数指定为SOCK_DGRAM*/
                                             IPPROTO_TCP ,/*指定通讯协议。如果前一个参数为SOCK_STREAM,则默认为使用TCP协议，如果前一个参数为SOCK_DGRAM,则默认使用UDP协议*/
                                             kCFSocketAcceptCallBack,/*指定下一个函数所监听的事件类型*/
                                             TCPServerAcceptCallBack,
                                             NULL);
        
        if (_socket == NULL) {
            
            NSLog(@"创建Socket失败！");
            return;
        }
        
        BOOL reused = YES;
//        //设置允许重用本地地址和端口
        setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (const void *)&reused, sizeof(reused));
        
        //定义sockaddr_in类型的变量，该变量将作为CFSocket的地址
        struct sockaddr_in Socketaddr;
        memset(&Socketaddr, 0, sizeof(Socketaddr));
        Socketaddr.sin_len = sizeof(Socketaddr);
        Socketaddr.sin_family = AF_INET;
        //设置该服务器监听本机任意可用的IP地址
//                addr4.sin_addr.s_addr = htonl(INADDR_ANY);
        //设置服务器监听地址
        Socketaddr.sin_addr.s_addr = inet_addr(TEST_IP_ADDR);
        //设置服务器监听端口
        Socketaddr.sin_port = htons(TEST_IP_PROT);
        
        //将IPv4的地址转换为CFDataRef
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&Socketaddr, sizeof(Socketaddr));
        //将CFSocket绑定到指定IP地址
        if (CFSocketSetAddress(_socket, address) != kCFSocketSuccess) {
        
            //如果_socket不为NULL，则释放_socket
            if (_socket) {
                
                CFRelease(_socket);
                exit(1);
            }
            _socket = NULL;
            
        }
        
        NSLog(@"----启动循环监听客户端连接---");
        //获取当前线程的CFRunLoop
        CFRunLoopRef cfRunLoop = CFRunLoopGetCurrent();
        //将_socket包装成CFRunLoopSource
        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
        //为CFRunLoop对象添加source
        CFRunLoopAddSource(cfRunLoop, source, kCFRunLoopCommonModes);
        CFRelease(source);
        //运行当前线程的CFRunLoop
        CFRunLoopRun();
        
    }
    
    
    
}


void readStream(CFReadStreamRef readStream,
                CFStreamEventType evenType,
                void *clientCallBackInfo)
{
    UInt8 buff[2048];
    
    NSString *aaa = (__bridge NSString *)(clientCallBackInfo);
    
    NSLog(@"%@", aaa);
    
    // ----从可读的数据流中读取数据，返回值是多少字节读到的，如果为0就是已经全部结束完毕，如果是-1则是数据流没有打开或者其他错误发生
    CFIndex hasRead = CFReadStreamRead(readStream, buff, sizeof(buff));
    
    if (hasRead > 0) {
        printf("接收到数据：%s\n",buff);
        
        const char *str = "for the lich king！！\n";
        //向客户端输出数据
        CFWriteStreamWrite(writeStreamRef, (UInt8 *)str, strlen(str) + 1);
    }
    
}

//有客户端连接进来的回调函数
void TCPServerAcceptCallBack(CFSocketRef socket,
                             CFSocketCallBackType type,
                             CFDataRef address,
                             const void *data,
                             void *info)
{
    //如果有客户端Socket连接进来
    if (kCFSocketAcceptCallBack == type) {
        
        //获取本地Socket的Handle，这个回调事件的类型是kCFSocketAcceptCallBack，这个data就是一个CFSocketNativeHandle类型指针
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        
        //定义一个255数组接收这个新的data转成的socket的地址，SOCK_MAXADDRLEN意思是最长的可能的地址
        uint8_t name[SOCK_MAXADDRLEN];
        //这个地址数组的长度
        socklen_t namelen = sizeof(name);
        
        /**
            int	getpeername(int,已经连接的Socket
                            struct sockaddr * __restrict,用来接收地址信息
                            socklen_t * __restrict 地址长度
                            )
         作用是从已经连接的Socket中获得地址信息，存到参数2中，地址长度放到参数3中
         
         成功是返回0，如果失败了则返回别的数字，对应不同错误码
         
         */
        //获取Socket信息
        if (getpeername(nativeSocketHandle,
                        (struct sockaddr *)name,
                        &namelen) != 0 ) {
            
            perror("getpeername:");
            exit(1);
        }
        
        //获取连接信息
        struct sockaddr_in *addr_in = (struct sockaddr_in *)name;
        // ----inet_ntoa将网络地址转换成“.”点隔的字符串格式
        NSLog(@"%s:%d连接进来了",inet_ntoa(addr_in->sin_addr),addr_in->sin_port);
        
        //创建一组可读/写的CFStream
        readStreamRef  = NULL;
        writeStreamRef = NULL;
        
        // ----创建一个和Socket对象相关联的读取数据流
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, //内存分配器
                                     nativeSocketHandle, //准备使用输入输出流的socket
                                     &readStreamRef, //输入流
                                     &writeStreamRef);//输出流
        
        // ----CFStreamCreatePairWithSocket(）操作成功后，readStreamRef和writeStreamRef都指向有效的地址，因此判断是不是还是之前设置的NULL就可以了
        if (readStreamRef && writeStreamRef) {
            
            //打开输入流和输出流
            CFReadStreamOpen(readStreamRef);
            CFWriteStreamOpen(writeStreamRef);
            
            // ----一个结构体包含程序定义数据和回调用来配置客户端数据流行为
            NSString *aaa = @"earth，wind，fire，be my call";
            
            CFStreamClientContext context = {0,(__bridge void *)(aaa),NULL,NULL};
            
            /** 
             指定客户端的数据流，当特定事件发生的时候，接受回调
             Boolean CFReadStreamSetClient ( CFReadStreamRef stream, 需要指定的数据流
                                             CFOptionFlags streamEvents, 具体的事件，如果为NULL，当前客户端数据流就会被移除
                                             CFReadStreamClientCallBack clientCB, 事件发生回调函数，如果为NULL，同上
                                             CFStreamClientContext *clientContext 一个为客户端数据流保存上下文信息的结构体，为NULL同上
                                            );
             返回值为TRUE就是数据流支持异步通知，FALSE就是不支持
             */
            if (!CFReadStreamSetClient(readStreamRef,
                                       kCFStreamEventHasBytesAvailable,
                                       readStream,
                                       &context)) {
                exit(1);
            }
            
            // ----将数据流加入循环
            CFReadStreamScheduleWithRunLoop(readStreamRef,
                                            CFRunLoopGetCurrent(),
                                            kCFRunLoopCommonModes);
            
            const char *str = "welcome！\n";
            
            //向客户端输出数据
            CFWriteStreamWrite(writeStreamRef, (UInt8 *)str, strlen(str) + 1);
            
        }else {
            // ----如果失败就销毁已经连接的Socket
            close(nativeSocketHandle);
        }
        
    }
    
}

@end



