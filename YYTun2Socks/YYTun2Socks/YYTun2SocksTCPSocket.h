//
//  YYTun2SocksTCPSocket.h
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/21.
//
//

#import <Foundation/Foundation.h>
#include <netinet/in.h>
#include "lwip/tcp.h"

@protocol YYTun2SocksTCPSocketDelegate;

@interface YYTun2SocksTCPSocket : NSObject

@property (nonatomic, assign, readonly) struct in_addr sourceAddress;

@property (nonatomic, assign, readonly) struct in_addr destinationAddress;

@property (nonatomic, assign, readonly) UInt16 sourcePort;

@property (nonatomic, assign, readonly) UInt16 destinationPort;

- (instancetype)initWithTCPPcb:(struct tcp_pcb*)pcb delegate:(id<YYTun2SocksTCPSocketDelegate>)delegate queue:(dispatch_queue_t)queue;

- (void)setDelegate:(id<YYTun2SocksTCPSocketDelegate>)delegate;

@end

@protocol YYTun2SocksTCPSocketDelegate <NSObject>

/**
 The socket is closed on tx side (FIN received). We will not read any data.
 */
- (void)socketDidCloseLocally:(YYTun2SocksTCPSocket *)socket;

/**
 The socket is reseted (RST received), it should be released immediately.
 */
- (void)socketDidReset:(YYTun2SocksTCPSocket *)socket;

/**
 The socket is aborted (RST sent), it should be released immediately.
 */
- (void)socketDidAbort:(YYTun2SocksTCPSocket *)socket;

/**
 The socket is closed. This will only be triggered if the socket is closed actively by calling `close()`. It should be released immediately.
 */
- (void)socketDidClose:(YYTun2SocksTCPSocket *)socket;

/**
 Socket read data from local tx side.

 @param socket The socket object.
 @param data The read data.
 */
- (void)socket:(YYTun2SocksTCPSocket *)socket didReadData:(NSData *)data;

/**
 The socket has sent the specific length of data.

 @param socket The socket object.
 @param length The length of data being ACKed.
 */
- (void)socket:(YYTun2SocksTCPSocket *)socket didWriteDataOfLength:(NSUInteger)length;

@end
