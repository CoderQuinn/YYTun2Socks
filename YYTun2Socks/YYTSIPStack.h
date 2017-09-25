//
//  YYTSIPStack.h
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/20.
//
//

#import <Foundation/Foundation.h>

typedef void(^outputPacketCallback)(NSData *packet, int family);

@class YYTSTCPSocket;
@protocol YYTSIPStackDelegate;

@interface YYTSIPStack : NSObject

@property (nonatomic, weak, readonly) id<YYTSIPStackDelegate> delegate;

@property (nonatomic, copy, readonly) outputPacketCallback outputCallback;

+ (instancetype)defaultTun2SocksIPStack;

- (void)setDelegate:(id<YYTSIPStackDelegate>)delegate;

- (void)setOutputCallback:(outputPacketCallback)outputCallback;

- (void)suspendTimer;

- (void)resumeTimer;

- (void)receivedPacket:(NSData *)packet;

@end

@protocol YYTSIPStackDelegate <NSObject>

- (void)didAcceptTCPSocket:(YYTSTCPSocket *)socket;

@end



