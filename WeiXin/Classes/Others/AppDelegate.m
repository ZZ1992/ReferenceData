//
//  AppDelegate.m
//  WeiXin
//
//  Created by Yong Feng Guo on 14-11-18.
//  Copyright (c) 2014年 Fung. All rights reserved.
//

#import "AppDelegate.h"
#import "XMPPFramework.h"
#import "WXUserInfo.h"

/*
 1 初始化XmppStream核心类
 2 连接到服务器【连接服务器已经传送了账号】
 3 发送登录密码到服务器【代理返回连接成功才执行此步骤】
 4 登录成功 通知用户上线
 5 登录成功 进入主界面
 6 登录失败提示用户名密码错误
 */

@interface AppDelegate ()<XMPPStreamDelegate>

/**
 1 初始化XmppStream核心类
 */

-(void)setupXmppStream;

/**
 2 连接到服务器【连接服务器已经传送了账号】
 */
-(void)connectToServer;

/**
 3 发送登录密码到服务器【代理返回连接成功才执行此步骤】
 */
-(void)sendLoginPwdToServer;

/**
  发送注册密码到服务器【代理返回连接成功才执行此步骤】
 */
-(void)sendRegisterPwdToServer;

/**
 4 登录成功 通知用户上线
 */
-(void)notifyUserOnline;
/**
 5 登录成功进入主界面
 */
-(void)enterMainStoryboard;



#pragma mark 成员属性
@property(nonatomic,strong)XMPPStream *xmppStream;

//登录或者注册结果的回调block
@property(nonatomic,copy)ResultBlock resultBlock;
@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}


#pragma mark -私有方法
#pragma mark 1 初始化XmppStream核心类
-(void)setupXmppStream{
    // 创建xmppStream对象
    self.xmppStream = [[XMPPStream alloc] init];
    
    // 设置代理【所有跟服务交互后，返回结果通过代理方式通知】
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
}

#pragma mark 2 连接到服务器【连接服务器已经传送了账号】
-(void)connectToServer{
    WXLog(@"连接服务器");
    // 如果xmppStream没有值，创建对象
    if (!self.xmppStream) {
        [self setupXmppStream];
    }
    
    // 获取用户信息单例对象
    WXUserInfo *userInfo = [WXUserInfo sharedWXUserInfo];
    
    // 提交服务器前
    // 1.设置xmppStream要交互的主机地址与端口
    self.xmppStream.hostName = userInfo.xmppDomain;
    // 默认是5222 可以不用设置
    self.xmppStream.hostPort = 5222;
    
    
    // 2.设置登录的账号
    XMPPJID *myJid = nil;
    if (!self.isUserRegister) {
         myJid = [XMPPJID jidWithUser:userInfo.loginUserName domain:userInfo.xmppDomain resource:nil];
    }else{
        // 设置注册账号
        myJid = [XMPPJID jidWithUser:userInfo.registerUserName domain:userInfo.xmppDomain resource:nil];
    }
    
    self.xmppStream.myJID = myJid;
    
    /**
     Error Domain=XMPPStreamErrorDomain Code=1 "Attempting to connect while already connected or connecting." UserInfo=0x7be9ac40 {NSLocalizedDescription=Attempting to connect while already connected or connecting.
     */
    // 如果之前的连接过，断开连接，否则用新的用户名连接时，会报连接已存在的错误
    if (self.xmppStream.isConnected) {
        [self.xmppStream disconnect];
    }
    
    // 3.执行请求连接服务器
    NSError *error = nil;
    [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
    WXLog(@"%@",error);
}

#pragma mark 3 发送登录密码到服务器【代理返回连接成功才执行此步骤】
-(void)sendLoginPwdToServer{
    WXLog(@"发送登录密码到服务器");
    WXUserInfo *userInfo = [WXUserInfo sharedWXUserInfo];
    NSError *error = nil;
    [self.xmppStream authenticateWithPassword:userInfo.loginPwd error:&error];
    
    WXLog(@"%@",error);
    
    
}
#pragma mark 4 通知用户上线
-(void)notifyUserOnline{
    WXLog(@"通知用户上线");
    XMPPPresence *presence = [XMPPPresence presence];
    [self.xmppStream sendElement:presence];
}

#pragma mark 5 登录成功进入主界面
-(void)enterMainStoryboard{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // 切换跟控制器
    dispatch_async(dispatch_get_main_queue(), ^{
        
        id initalVc = [storyboard instantiateInitialViewController];
        self.window.rootViewController = initalVc;
    });
    
}

#pragma mark 发送注册密码到服务器
-(void)sendRegisterPwdToServer{
    WXUserInfo *userInfo = [WXUserInfo sharedWXUserInfo];
    NSError *error = nil;
    [self.xmppStream registerWithPassword:userInfo.registerPwd error:&error];
    
    WXLog(@"发送注册密码到服务器 %@",error);
}

#pragma mark -公共方法
#pragma mark 用户登录
-(void)userLoginWithResultBlock:(ResultBlock)resultBlock{
    
    // 赋值给成员属性
    self.resultBlock = resultBlock;
    
    // 连接到服务器，成功后，发送密码授权
    [self connectToServer];
}

#pragma mark 用户注册
-(void)userRegisterWithResultBlock:(ResultBlock)resultBlock{
    // 赋值给成员属性
    self.resultBlock = resultBlock;
    
    // 连接到服务器，成功后，发送密码授权
    [self connectToServer];
}

#pragma mark -XMPPStream代理

#pragma mark 客户端与连接主机成功
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    WXLog(@"与服务器连接成功");
    if (!self.isUserRegister) {
        // 连接成功后 发送密码到服务器，进行授权验证
        [self sendLoginPwdToServer];
    }else{
        // 连接成功后 发送注册密码到服务器
        [self sendRegisterPwdToServer];
    }
    
}

#pragma mark 客户端断开与主机的连接
-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    WXLog(@"与服务器断开连接");
}

#pragma mark 授权失败
-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    WXLog(@"授权失败%@",error);
    if (self.resultBlock) {
        _resultBlock(XMPPResultTypeLoginFailure);
    }
}

#pragma mark 授权成功
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    WXLog(@"授权成功【即成功登录】");
    
    [self notifyUserOnline];
    
    if (self.resultBlock) {
        _resultBlock(XMPPResultTypeLoginSuccess);
    }
    
}
#pragma mark 注册成功
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    WXLog(@"注册成功");
    if (self.resultBlock) {
        _resultBlock(XMPPResultTypeRegisterSuccess);
    }
}


#pragma mark 注册失败
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error{
    WXLog(@"注册失败 %@",error);
    if (self.resultBlock) {
        _resultBlock(XMPPResultTypeRegisterFailure);
    }
}
@end