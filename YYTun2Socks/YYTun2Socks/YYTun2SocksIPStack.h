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

/**
 This is the IP stack that receives and outputs IP packets.
 
 `outputBlock` and `delegate` should be set before any input.
 Then call `receivedPacket(_:)` when a new IP packet is read from the TUN interface.
 
 There is a timer running internally. When the device is going to sleep (which means the timer will not fire for some time), then the timer must be paused by calling `suspendTimer()` and resumed by `resumeTimer()` when the deivce wakes up.
 
 - note: This class is NOT thread-safe.
 */
@interface YYTun2SocksIPStack : NSObject

@property (nonatomic, weak, readonly) id<YYTun2SocksIPStackDelegate> delegate;

@property (nonatomic, copy, readonly) outputPacketCallback outputCallback;

+ (instancetype)defaultTun2SocksIPStack;

- (void)setDelegate:(id<YYTun2SocksIPStackDelegate>)delegate;

- (void)setOutputCallback:(outputPacketCallback)outputCallback;

/**
 Suspend the timer. The timer should be suspended when the device is going to sleep.
 */
- (void)suspendTimer;

/**
 Resume the timer when the device is awoke.
 
 - warning: Do not call this unless the stack is not resumed or you suspend the timer.
 */
- (void)resumeTimer;


/**
 Input an IP packet.
 
 @param packet the data containing the whole IP packet.
 */
- (void)receivedPacket:(NSData *)packet;

@end

@protocol YYTun2SocksIPStackDelegate <NSObject>

/**
 A new TCP socket is accepted. This means we received a new TCP packet containing SYN signal.
 
 @param socket the socket object.
 */
- (void)didAcceptTCPSocket:(YYTun2SocksTCPSocket *)socket;

@end



