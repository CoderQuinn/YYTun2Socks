//
//  YYTSIPStack.h
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/20.
//
//

#import <Foundation/Foundation.h>

typedef void(^outputPacketCallback)(NSData * _Nullable packet, int family);

@class YYTSTCPSocket;
@protocol YYTSIPStackDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface YYTSIPStack : NSObject

@property (nullable, nonatomic, weak, readonly) id<YYTSIPStackDelegate> delegate;

@property (nonatomic, copy, readonly) outputPacketCallback outputCallback;

+ (instancetype)defaultTun2SocksIPStack;

- (void)setDelegate:(nullable id<YYTSIPStackDelegate>)delegate;

- (void)setOutputCallback:(nullable outputPacketCallback)outputCallback;

- (void)suspendTimer;

- (void)resumeTimer;

- (void)receivedPacket:(NSData *)packet;

@end

@protocol YYTSIPStackDelegate <NSObject>

- (void)didAcceptTCPSocket:(YYTSTCPSocket *)socket;

@end

NS_ASSUME_NONNULL_END



