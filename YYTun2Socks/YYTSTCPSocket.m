//
//  YYTSTCPSocket.m
//  YYTun2Socks
//
//  Created by Hmyy on 2017/9/21.
//
//

#import "YYTSTCPSocket.h"
#include "lwip/tcp.h"

@interface YYTSTCPSocket ()

@property (nonatomic, assign) struct tcp_pcb *pcb;

@property (nonatomic, assign) NSUInteger identity;

@property (nonatomic, assign) NSUInteger *identityAry;

@property (nonatomic, weak) id<YYTSTCPSocketDelegate> delegate;

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign, getter=isSentClosedSignal) BOOL sentClosedSignal;

@property (nonatomic, assign, getter=isValid) BOOL valid;

@property (nonatomic, assign, getter=isConnected) BOOL connected;

@end

@implementation YYTSTCPSocket

static NSMutableDictionary<NSNumber *, YYTSTCPSocket *> *_socketDict;

+ (void)setSocketDict:(NSMutableDictionary<NSNumber *,YYTSTCPSocket *> *)socketDict
{
    if (socketDict != _socketDict)
    {
        _socketDict = socketDict;
    }
}

+ (NSMutableDictionary<NSNumber *,YYTSTCPSocket *> *)socketDict
{
    if (_socketDict == nil)
    {
        _socketDict = [NSMutableDictionary dictionaryWithCapacity:UINT32_MAX];
    }
    return _socketDict;
}

+ (YYTSTCPSocket *)socketForIdentity:(NSUInteger)identity
{
    return [self.socketDict objectForKey:@(identity)];
}

+ (YYTSTCPSocket *)socketForIdentityPointer:(NSUInteger *)identityPointer
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

- (void)setDelegate:(id<YYTSTCPSocketDelegate>)delegate
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

- (instancetype)initWithTCPPcb:(struct tcp_pcb*)pcb queue:(dispatch_queue_t)queue
{
    if (self = [super init])
    {
        _pcb = pcb;
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
    tcp_arg(self.pcb, self.identityAry);
    tcp_recv(self.pcb, tcp_recv_callback);
    tcp_sent(self.pcb, tcp_sent_callback);
    tcp_err(self.pcb, tcp_err_callback);
}

- (void)errorOccurred:(err_t)error
{
    [self invalidate];
    switch (error)
    {
        case ERR_RST:
        {
            if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidReset:)])
            {
                [self.delegate socketDidReset:self];
            }
            break;
        }
        case ERR_ABRT:
        {
            if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidReset:)])
            {
                [self.delegate socketDidAbort:self];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)invalidate
{
    self.pcb = NULL;
    self.identityAry = NULL;
    [[self class].socketDict removeObjectForKey:@(self.identity)];
}

- (void)sendDataOfLength:(NSUInteger)length
{
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidReset:)])
    {
        [self.delegate socket:self didWriteDataOfLength:length];
    }
}

- (void)writeData:(NSData *)data
{
    if (![self isValid]) return;
    assert(data.length <= UINT16_MAX);
    
    const void *dataptr = [data bytes];
    UInt16 length = data.length;
    
    err_t error = tcp_write(self.pcb, dataptr, length, TCP_WRITE_FLAG_COPY);
    if (error != ERR_OK)
    {
        [self close];
    }
    else
    {
        tcp_output(self.pcb);
    }
}

- (void)receivedBuf:(struct pbuf *)pbuf
{
    if (pbuf == NULL)
    {
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidCloseLocally:)])
        {
            [self.delegate socketDidCloseLocally:self];
        }
    }
    else
    {
        uint16_t totalLength = pbuf->tot_len;
        NSMutableData *packetData = [NSMutableData dataWithLength:totalLength];
        void *dataptr = [packetData mutableBytes];
        pbuf_copy_partial(pbuf, dataptr, totalLength, 0);
        
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socket:didReadData:)])
        {
            [self.delegate socket:self didReadData:packetData];
        }
        
        if ([self isValid])
        {
            tcp_recved(self.pcb, totalLength);
        }
        pbuf_free(pbuf);
        
    }
}

- (void)close
{
    if (![self isValid]) return;
    
    tcp_arg(self.pcb, NULL);
    tcp_recv(self.pcb, NULL);
    tcp_sent(self.pcb, NULL);
    tcp_err(self.pcb, NULL);
    
    err_t error = tcp_close(self.pcb);
    assert(error == ERR_OK);
    
    [self invalidate];
    
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidClose:)])
    {
        [self.delegate socketDidClose:self];
    }
}

- (void)reset
{
    if (![self isValid]) return;
    
    tcp_arg(self.pcb, NULL);
    tcp_recv(self.pcb, NULL);
    tcp_sent(self.pcb, NULL);
    tcp_err(self.pcb, NULL);
    
    tcp_abort(self.pcb);
    [self invalidate];
    
    if (nil != self.delegate && [self.delegate respondsToSelector:@selector(socketDidClose:)])
    {
        [self.delegate socketDidClose:self];
    }
}

/** Function prototype for tcp receive callback functions. Called when data has
 * been received.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb which received data
 * @param p The received data (or NULL when the connection has been closed!)
 * @param err An error code if there has been an error receiving
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
static err_t tcp_recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{
    assert(err == ERR_OK);
    assert(arg != nil);
    YYTSTCPSocket *socket = [YYTSTCPSocket socketForIdentityPointer:arg];
    if (nil == socket)
    {
        // we do not know what this socket is, abort it
        tcp_abort(tpcb);
        return ERR_ABRT;
    }
    
    [socket receivedBuf:p];
    return ERR_OK;
}

/** Function prototype for tcp sent callback functions. Called when sent data has
 * been acknowledged by the remote side. Use it to free corresponding resources.
 * This also means that the pcb has now space available to send new data.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb for which data has been acknowledged
 * @param len The amount of bytes acknowledged
 * @return ERR_OK: try to send some data by calling tcp_output
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
static err_t tcp_sent_callback(void *arg, struct tcp_pcb *tpcb,
                               u16_t len)
{
    assert(arg != nil);
    YYTSTCPSocket *socket = [YYTSTCPSocket socketForIdentityPointer:arg];
    if (nil == socket)
    {
        // we do not know what this socket is, abort it
        tcp_abort(tpcb);
        return ERR_ABRT;
    }

    [socket sendDataOfLength:len];
    return ERR_OK;
}

/** Function prototype for tcp error callback functions. Called when the pcb
 * receives a RST or is unexpectedly closed for any other reason.
 *
 * @note The corresponding pcb is already freed when this callback is called!
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param err Error code to indicate why the pcb has been closed
 *            ERR_ABRT: aborted through tcp_abort or by a TCP timer
 *            ERR_RST: the connection was reset by the remote host
 */
static void tcp_err_callback(void *arg, err_t err)
{
    assert(arg != nil);
    
    YYTSTCPSocket *socket = [YYTSTCPSocket socketForIdentityPointer:arg];
    if (nil != socket)
    {
        [socket errorOccurred:err];
    }
}

@end
