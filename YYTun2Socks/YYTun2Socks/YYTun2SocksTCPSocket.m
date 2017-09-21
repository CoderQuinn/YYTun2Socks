//
//  YYTun2SocksTCPSocket.m
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/21.
//
//

#import "YYTun2SocksTCPSocket.h"

@interface YYTun2SocksTCPSocket ()

@property (nonatomic, assign) struct tcp_pcb *pcb;

@property (nonatomic, assign) NSUInteger identity;

@property (nonatomic, assign) NSUInteger *identityAry;

@property (nonatomic, weak) id<YYTun2SocksTCPSocketDelegate> delegate;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign, getter=isSentClosedSignal) BOOL sentClosedSignal;

@property (nonatomic, assign, getter=isValid) BOOL valid;

@property (nonatomic, assign, getter=isConnected) BOOL connected;

@end

@implementation YYTun2SocksTCPSocket

static NSMutableDictionary<NSNumber *, YYTun2SocksTCPSocket *> *_socketDict;

+ (void)setSocketDict:(NSMutableDictionary<NSNumber *,YYTun2SocksTCPSocket *> *)socketDict
{
    if (socketDict != _socketDict)
    {
        _socketDict = socketDict;
    }
}

+ (NSMutableDictionary<NSNumber *,YYTun2SocksTCPSocket *> *)socketDict
{
    if (_socketDict == nil)
    {
        _socketDict = [NSMutableDictionary dictionaryWithCapacity:UINT32_MAX];
    }
    return _socketDict;
}

+ (YYTun2SocksTCPSocket *)socketForIdentity:(NSUInteger)identity
{
    return [self.socketDict objectForKey:@(identity)];
}

+ (YYTun2SocksTCPSocket *)socketForIdentityPointer:(NSUInteger *)identityPointer
{
    
    return [self.socketDict objectForKey:@(*identityPointer)];
}

+ (NSInteger)uniqueKey
{
    UInt32 randomKey = arc4random();
    while ([self socketForIdentity:randomKey] != nil)
    {
        randomKey = arc4random();
    }
    return (NSInteger)randomKey;
}

- (void)setDelegate:(id<YYTun2SocksTCPSocketDelegate>)delegate
{
    if (delegate != _delegate)
    {
        _delegate = delegate;
    }
}

- (BOOL)isValid
{
    return self.pcb != nil;
}

- (BOOL)isConnected
{
    return [self isValid] && (self.pcb->state != CLOSED);
}

- (instancetype)initWithTCPPcb:(struct tcp_pcb*)pcb delegate:(id<YYTun2SocksTCPSocketDelegate>)delegate queue:(dispatch_queue_t)queue
{
    if (self = [super init])
    {
        _pcb = pcb;
        _delegate = delegate;
        _queue = queue;
        
        _sourcePort = pcb->remote_port;
        struct in_addr sourceIP = {pcb->remote_ip.addr};
        _sourceAddress = sourceIP;
        
        _destinationPort = pcb->local_port;
        struct in_addr destinationIP = {pcb->local_ip.addr};
        _destinationAddress = destinationIP;
        
        _identity = [[self class] uniqueKey];
        _identityAry = &_identity;
        [self class].socketDict[@(_identity)] = self;
        
        [self setupTCPPcb];
    }
    return self;
}

- (void)setupTCPPcb
{
    tcp_arg(self.pcb, _identityAry);
//    tcp_recv(pcb, tcp_recv_func)
//    tcp_sent(pcb, tcp_sent_func)
//    tcp_err(pcb, tcp_err_func)
}

@end
