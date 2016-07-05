//
//  ViewController.m
//  客户端
//
//  Created by 熊欣 on 16/6/28.
//  Copyright © 2016年 熊欣. All rights reserved.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#include<stdio.h>

/** 这个端口可以随便设置*/
#define TEST_IP_PROT 22235
/** 替换成你需要连接服务器绑定的IP地址，不能随便输*/
#define TEST_IP_ADDR "192.168.1.115"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UITextField *messageText;
@property (nonatomic, readwrite, assign) CFSocketRef socketRef;
@property (weak, nonatomic) IBOutlet UIButton *connetServer;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
   
    [self.connetServer addTarget:self action:@selector(connectServer:) forControlEvents:UIControlEventTouchUpInside];
  
    
}

#pragma mark - 方案一：使用kCFSocketNoCallBack
//- (IBAction)connectServer:(id)sender
//{
//    if (!_socketRef) {
//
//         // ----先创建一个socket
//        _socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack,nil, nil);
//        
//        // ----创建sockadd_in的结构体，该结构体作为socket的地址，IPV6需要改参数
//        struct sockaddr_in addr;
//        // ----memset：将addr中所有字节用0替换并返回addr，作用是一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法
//        memset(&addr, 0, sizeof(addr));
//        
//        /* 设置addr的具体内容
//         struct sockaddr_in {
//         __uint8_t	sin_len; 长度
//         sa_family_t	sin_family;  协议族，用AF_INET->互联网络，TCP，UDP等等
//         in_port_t	sin_port;    端口号（使用网络字节顺序)htons：将主机的无符号短整形数转换成网络字节顺序
//         struct	in_addr sin_addr; 存储IP地址 inet_addr()的功能是将一个点分十进制的IP转换成一个长整数型数（u_long类型），若字符串有效则将字符串转换为32位二进制网络字节序的IPV4地址，否则为INADDR_NONE
//         char		sin_zero[8]; 让sockaddr与sockaddr_in两个数据结构保持大小相同而保留的空字节，无需处理
//         };*/
//        addr.sin_len = sizeof(addr);
//        addr.sin_family = AF_INET;
//        addr.sin_port = htons(TEST_IP_PROT);
//        addr.sin_addr.s_addr = inet_addr(TEST_IP_ADDR);
//        
//        // ----将地址转化为CFDataRef
//        CFDataRef dataRef = CFDataCreate(kCFAllocatorDefault,(UInt8 *)&addr, sizeof(addr));
//        
//        /*!
//         *  @brief 连接socket
//         *
//         *  @param s       连接的socket
//         *  @param address 连接的socket的包含的地址参数
//         *  @param timeout 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
//         *
//         *  @return        返回CFSocketError类型
//         
//         CFSocketError	CFSocketConnectToAddress(CFSocketRef s, CFDataRef address, CFTimeInterval timeout)
//         */
//        CFSocketError connectError = CFSocketConnectToAddress(_socketRef, dataRef, 5);
//        
//        if (connectError == kCFSocketSuccess) {
//            
//            [NSThread detachNewThreadSelector:@selector(readStreamData) toTarget:self withObject:nil];
//            
//        }else {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"对不起" message:@"连接失败，请稍后再试" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
//            [alert show];
//        }
//
//    }
//}


#pragma mark - 方案二：使用kCFSocketConnectCallBack
- (void)connectServer:(id)sender
{
    if (!_socketRef) {
        
        // ----1.先创建Socket关联的上下文信息
        
        /*
        struct CFSocketContext
        {
            CFIndex version; 版本号，必须为0
            void *info; 一个指向任意程序定义数据的指针，可以在CFScocket对象刚创建的时候与之关联，被传递给所有在上下文中回调；
            CFAllocatorRetainCallBack retain; info指针中的retain回调，可以为NULL
            CFAllocatorReleaseCallBack release; info指针中的release的回调，可以为NULL
            CFAllocatorCopyDescriptionCallBack copyDescription; info指针中的回调描述，可以为NULL
        };
        typedef struct CFSocketContext CFSocketContext;
        */
        CFSocketContext sockContext = {0,(__bridge void *)(self),NULL,NULL,NULL};
        
        // ----2.先创建一个socket
        _socketRef = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack,ServerConnectCallBack, &sockContext);
        
        // ----创建sockadd_in的结构体，该结构体作为socket的地址，IPV6需要改参数
        struct sockaddr_in Socketaddr;
        // ----memset：将addr中所有字节用0替换并返回addr，作用是一段内存块中填充某个给定的值，它是对较大的结构体或数组进行清零操作的一种最快方法
        memset(&Socketaddr, 0, sizeof(Socketaddr));
        
        /* 设置addr的具体内容
         struct sockaddr_in {
         __uint8_t	sin_len; 长度
         sa_family_t	sin_family;  协议族，用AF_INET->互联网络，TCP，UDP等等
         in_port_t	sin_port;    端口号（使用网络字节顺序)htons：将主机的无符号短整形数转换成网络字节顺序
         struct	in_addr sin_addr; 存储IP地址 inet_addr()的功能是将一个点分十进制的IP转换成一个长整数型数（u_long类型），若字符串有效则将字符串转换为32位二进制网络字节序的IPV4地址，否则为INADDR_NONE
         char		sin_zero[8]; 让sockaddr与sockaddr_in两个数据结构保持大小相同而保留的空字节，无需处理
         };*/
        Socketaddr.sin_len = sizeof(Socketaddr);
        Socketaddr.sin_family = AF_INET;
        Socketaddr.sin_port = htons(TEST_IP_PROT);
        Socketaddr.sin_addr.s_addr = inet_addr(TEST_IP_ADDR);
        
        // ----将地址转化为CFDataRef
        CFDataRef dataRef = CFDataCreate(kCFAllocatorDefault,(UInt8 *)&Socketaddr, sizeof(Socketaddr));
    
        /*!
         *  @brief 连接socket
         *
         *  @param s       连接的socket
         *  @param address 连接的socket的包含的地址参数
         *  @param timeout 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
         *
         *  @return        返回CFSocketError类型
       
       CFSocketError	CFSocketConnectToAddress(CFSocketRef s, CFDataRef address, CFTimeInterval timeout)
        */
        
        // ----连接
        CFSocketConnectToAddress(_socketRef, dataRef, -1);
        
        // ----加入循环中
        
        // ----获取当前线程的RunLoop
        CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
        
        // ----把Socket包装成CFRunLoopSource，最后一个参数是指有多个runloopsource通过同一个runloop时候顺序，如果只有一个source通常为0
        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socketRef, 0);
        
        // ----加入运行循环,第三个参数表示
        CFRunLoopAddSource(runLoopRef, //运行循环管
                           sourceRef, // 增加的运行循环源, 它会被retain一次
                           kCFRunLoopCommonModes //用什么模式把source加入到run loop里面,使用kCFRunLoopCommonModes可以监视所有通常模式添加source
                           );
        // ----之前被retain一次，所以这边要释放掉
        CFRelease(sourceRef);
    }
}

#pragma mark - 读取数据
- (void)readStreamData
{
    // ----定义一个字符型变量
    char buffer[512];
    
    /** 
        int recv( SOCKET s, char FAR *buf, int len, int flags );
     
     不论是客户还是服务器应用程序都用recv函数从TCP连接的另一端接收数据。
     
     （1）第一个参数指定接收端套接字描述符；
     
     （2）第二个参数指明一个缓冲区，该缓冲区用来存放recv函数接收到的数据；
     
     （3）第三个参数指明buf的长度；
     
     （4）第四个参数一般置0。
     
     */
    
    long readData;
    //若无错误发生，recv()返回读入的字节数。如果连接已中止，返回0。如果发生错误，返回-1，应用程序可通过perror()获取相应错误信息
    while((readData = recv(CFSocketGetNative(_socketRef), buffer, sizeof(buffer), 0))) {
        
        NSString *content = [[NSString alloc] initWithBytes:buffer length:readData encoding:NSUTF8StringEncoding];
                             
        dispatch_async(dispatch_get_main_queue(), ^{
            
             self.infoLabel.text = [NSString stringWithFormat:@"%@\n%@",content,self.infoLabel.text];

        });
    }
    perror("recv");

}

#pragma mark - 发送消息
- (IBAction)sendMessage:(id)sender {
    
    if (!_socketRef) {
        [[[UIAlertView alloc] initWithTitle:@"对不起" message:@"请先连接服务器" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
        return;
    }
    NSString *stringTosend = [NSString stringWithFormat:@"%@说：%@",self.nameText.text,self.messageText.text];
    
    const char* data = [stringTosend UTF8String];
    
    /** 成功则返回实际传送出去的字符数, 失败返回-1. 错误原因存于errno*/
    long sendData = send(CFSocketGetNative(_socketRef), data, strlen(data) + 1, 0);
    
    if (sendData < 0) {
        perror("send");
    }
}


#pragma mark - 回调函数

/*!
 *  @author 熊欣, 16-06-28 17:06:59
 *
 *  @brief socket回调函数
 *
 *  @param s            socket对象；
 *  @param callbackType 这个socket对象的活动类型；
 *  @param address      socket对象连接的远程地址，CFData对象对应的是socket对象中的protocol family（struct sockaddr_in 或者 struct sockaddr_in6）， 除了type类型为kCFSocketAcceptCallBack和kCFSocketDataCallBack，否则这个值通常是NULL；
 *  @param data         跟回调类型相关的数据指针
    kCFSocketConnectCallBack：如果失败了，它指向的就是SINT32的错误代码；
    kCFSocketAcceptCallBack： 它指向的就是CFSocketNativeHandle
    kCFSocketDataCallBack：   它指向的就是将要进来的Data；
    其他情况都是NULL
 *  @param info         与Socket相关的自定义的任意数据
 */
void ServerConnectCallBack ( CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info )
{
    ViewController *vc = (__bridge ViewController *)(info);
    // ----判断是不是NULL
    if (data != NULL) {
        printf("连接失败\n");
        
        [vc performSelector:@selector(releaseSocket) withObject:nil];
        
    }else {
        printf("连接成功\n");
        
        [vc performSelectorInBackground:@selector(readStreamData) withObject:nil];
  
    }
    
  
}

#pragma mark - 关掉键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

#pragma mark - 清空socket
- (void)releaseSocket
{
    if (_socketRef) {
        CFRelease(_socketRef);
    }
    
    _socketRef = NULL;
    
    self.infoLabel.text = @"连接失败";
}


@end



