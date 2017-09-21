//
//  YYTun2SocksIPStack.h
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/20.
//
//

#import <Foundation/Foundation.h>

typedef void(^outputPacketCallback)(NSData *packet, int family);

@class YYTun2SocksTCPSocket;
@protocol YYTun2SocksIPStackDelegate;

@interface YYTun2SocksIPStack : NSObject

@property (nonatomic, weak, readonly) id<YYTun2SocksIPStackDelegate> delegate;

@property (nonatomic, copy, readonly) outputPacketCallback outputCallback;

+ (instancetype)defaultTun2SocksIPStack;

- (void)setDelegate:(id<YYTun2SocksIPStackDelegate>)delegate;

- (void)setOutputCallback:(outputPacketCallback)outputCallback;

- (void)suspendTimer;

- (void)resumeTimer;

- (void)receivedPacket:(NSData *)packet;

@end

@protocol YYTun2SocksIPStackDelegate <NSObject>

- (void)didAcceptTCPSocket:(YYTun2SocksTCPSocket *)socket;

@end



