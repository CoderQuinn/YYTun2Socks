//
//  YYTSTCPSocket.h
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/21.
//
//

#import <Foundation/Foundation.h>

@protocol YYTSTCPSocketDelegate;

@interface YYTSTCPSocket : NSObject

@property (nonatomic, assign, readonly) struct in_addr sourceAddress;

@property (nonatomic, assign, readonly) struct in_addr destinationAddress;

@property (nonatomic, assign, readonly) UInt16 sourcePort;

@property (nonatomic, assign, readonly) UInt16 destinationPort;

- (instancetype)initWithTCPPcb:(struct tcp_pcb*)pcb queue:(dispatch_queue_t)queue;

- (void)setDelegate:(id<YYTSTCPSocketDelegate>)delegate;

@end

@protocol YYTSTCPSocketDelegate <NSObject>

- (void)socketDidCloseLocally:(YYTSTCPSocket *)socket;

- (void)socketDidReset:(YYTSTCPSocket *)socket;

- (void)socketDidAbort:(YYTSTCPSocket *)socket;

- (void)socketDidClose:(YYTSTCPSocket *)socket;

- (void)socket:(YYTSTCPSocket *)socket didReadData:(NSData *)data;

- (void)socket:(YYTSTCPSocket *)socket didWriteDataOfLength:(NSUInteger)length;

@end
