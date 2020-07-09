//© Copyright 2014 – 2020 Micro Focus or one of its affiliates

// The only warranties for products and services of Micro Focus and its affiliates and licensors (“Micro Focus”) are as may be set forth in the express warranty statements accompanying such products and services. Nothing herein should be construed as constituting an additional warranty. Micro Focus shall not be liable for technical or editorial errors or omissions contained herein. The information contained herein is subject to change without notice.

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StreamFFp : NSObject <NSStreamDelegate> {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSMutableData *globalData;
    BOOL _isConnected;
    AudioConverterRef m_converter;
}

- (void)initialSocket;

- (void)close;

//- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)sendAudioData:(NSData *)data;


@end

NS_ASSUME_NONNULL_END
