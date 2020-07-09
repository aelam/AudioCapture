//
//  TSClient.mm
//  HTTPLiveStreaming
//
//  Created by Byeongwook Park on 2016. 1. 14..
//  Copyright © 2016년 . All rights reserved.
//
//  https://en.wikipedia.org/wiki/Real_Time_Streaming_Protocol
//  http://stackoverflow.com/questions/17896008/can-ffmpeg-library-send-the-live-h264-ios-camera-stream-to-wowza-using-rtsp
//  https://github.com/goertzenator/lwip/blob/master/contrib-1.4.0/apps/rtp/rtp.c

@import CocoaAsyncSocket;

#import "RTPClient.h"


struct rtpbits {
    int     sequence:16;     /* sequence number: random */
    int     pt:7;            /* payload type: 14 for MPEG audio */
    int     m:1;             /* marker: 0 */
    int     cc:4;            /* number of CSRC identifiers: 0 */
    int     x:1;             /* number of extension headers: 0 */
    int     p:1;             /* is there padding appended: 0 */
    int     v:2;             /* version: 2 */
};

struct rtpheader {           /* in network byte order */
    struct rtpbits b;
    int     timestamp;       /* start: random */
    int     ssrc;            /* random */
    int     iAudioHeader;    /* =0?! */
};

struct rtpheader RTPheader;



@interface RTPClient()
{
    GCDAsyncUdpSocket *socket_rtp;
    
    uint16_t seqNum;
    
    dispatch_queue_t queue;
    uint32_t start_t;
    
    int ssrc;
}
@end

@implementation RTPClient

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        socket_rtp = [[GCDAsyncUdpSocket alloc] init];
        [socket_rtp setDelegateQueue:queue];
        self.address = nil;
        self.port = 554;
        seqNum = 0;
        start_t = 0;
        
        ssrc = rand();
    }
    return self;
}

- (void)dealloc {
    [self reset];
    [socket_rtp closeAfterSending];
}

- (void)reset
{
    start_t = 0;
    seqNum = 0;
}

#pragma mark - Publish

- (void)publish:(NSData *)data timestamp:(CMTime)timestamp payloadType:(NSInteger)payloadType
{
    int32_t t = ((float)timestamp.value / timestamp.timescale) * 1000;
    if(start_t == 0) start_t = t;
    
    if (1){
        NSMutableData *nsdata = nil;
        struct rtpheader *foo = &RTPheader;
        
        foo->b.v = 2;
        foo->b.p = 0;
        foo->b.x = 0;
        foo->b.cc = 0;
        foo->b.m = 0;
        foo->b.pt = 97;  // AAC   /* MPEG Audio */
        foo->b.sequence = t - start_t; //rand() & 65535;
        foo->timestamp = t;
        foo->ssrc = ssrc;
        foo->iAudioHeader = 0;
        
        int len = (int)data.length;
        unsigned char const *cdata = data.bytes;
        
        char   *buffer = malloc(len + sizeof(struct rtpheader));
        int    *cast = (int *) foo;
        int    *outcast = (int *) buffer;
        int    size;
        
        outcast[0] = htonl(cast[0]);
        outcast[1] = htonl(cast[1]);
        outcast[2] = htonl(cast[2]);
        outcast[3] = htonl(cast[3]);
        memmove(buffer + sizeof(struct rtpheader), cdata, len);
        size = len + sizeof(*foo);
        
        // SET THE AU HEADER LENGTH AND AU HEADER
        buffer[12] = 0x00;
        buffer[13] = 0x10;
        buffer[14] = ((len & 0x1fe0) >> 5); //高位
        buffer[15] = ((len & 0x1f) << 3); //低位
        
        nsdata = [[NSMutableData alloc] initWithBytes:buffer length:size];
        [nsdata appendData:data];
        
        free(buffer);
        
        [socket_rtp sendData:nsdata toHost:self.address port:self.port withTimeout:-1 tag:seqNum];
        
    }
    
    seqNum++;
    
}

@end
