//© Copyright 2014 – 2020 Micro Focus or one of its affiliates

// The only warranties for products and services of Micro Focus and its affiliates and licensors (“Micro Focus”) are as may be set forth in the express warranty statements accompanying such products and services. Nothing herein should be construed as constituting an additional warranty. Micro Focus shall not be liable for technical or editorial errors or omissions contained herein. The information contained herein is subject to change without notice.

#import "StreamFFp.h"


@implementation StreamFFp


- (void)initialSocket {
    //Use socket
    printf("initialSocket\n");
    
    //    NSString *ip = @"192.168.0.20";
    //    int port = 8003;
    
//    NSString *host = @"10.30.28.26";
//    NSString *host = @"10.5.35.222";
//    int port = 9999;
    NSString *host = @"10.30.28.34";
    int port = 1234;

    
    // 1.创建输入输出流，设置代理
    CFReadStreamRef readStreamRef;
    CFWriteStreamRef writeStreamRef;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStreamRef, &writeStreamRef);
    inputStream = (__bridge NSInputStream *)(readStreamRef);
    outputStream = (__bridge NSOutputStream *)(writeStreamRef);

//    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef) ip, port, &readStream, &writeStream);
    if (inputStream && outputStream) {
//        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        //CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
//        inputStream = (__bridge NSInputStream *) readStream;
        [inputStream setDelegate:self];
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inputStream open];
        
//        outputStream = (__bridge NSOutputStream *) writeStream;
        [outputStream setDelegate:self];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream open];
        _isConnected = YES;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    NSLog(@"Handle Event - ");
    if (aStream == inputStream) {
        NSLog(@"Handle Event - input:");
        switch (eventCode) {
            case NSStreamEventOpenCompleted:{
                NSLog(@"Stream opened");
                break;}
            case NSStreamEventHasBytesAvailable: {
                NSLog(@"Bytes Available!");
                NSLog(@"inputStream is ready.");
                break;
            }
            case NSStreamEventErrorOccurred: {
                NSLog(@"Can not connect to the host!");
                break;}
            case NSStreamEventEndEncountered:{
                NSLog(@"End Encountered");
                break;}
            case NSStreamEventHasSpaceAvailable: {
                NSLog(@"Space Availible.");
                break;
            }
            default:
                NSLog(@"Unknown event- %lu", (unsigned long) eventCode);
        }
        
    } else {
        NSLog(@"Handle Event - output:");
        switch (eventCode) {
            case NSStreamEventOpenCompleted:{
                NSLog(@"Stream opened");
                break;}
            case NSStreamEventHasBytesAvailable: {
                NSLog(@"Bytes Available!");
                NSLog(@"outputStream is ready.");
                break;
            }
            case NSStreamEventErrorOccurred: {
                NSLog(@"Can not connect to the host!");
                break;}
            case NSStreamEventEndEncountered:{
                NSLog(@"End Encountered");
                break;}
            case NSStreamEventHasSpaceAvailable: {
                NSLog(@"Space Availible.");
                break;
            }
            default:
                NSLog(@"Unknown event- %lu", (unsigned long) eventCode);

        }
    }
}

- (void)close {
    _isConnected = NO;
    [outputStream close];
    [inputStream close];
    
    [inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
}

- (void)sendAudioData:(NSData *)data {
    if (_isConnected == YES) { // to stream the status has to be NSStreamStatusOpen = 2
        if ([outputStream streamStatus] == NSStreamStatusOpen) {
            [outputStream write:data.bytes maxLength:data.length];
        }
    }
}

- (void)sendAudioData:(char *)buffer len:(int)len channel:(UInt32)channel {
    Float32 *frame = (Float32 *) buffer;
    [globalData appendBytes:frame length:len];
    
    //Status list error code:
    //    NSStreamStatusNotOpen = 0,
    //    NSStreamStatusOpening = 1,
    //    NSStreamStatusOpen = 2,
    //    NSStreamStatusReading = 3,
    //    NSStreamStatusWriting = 4,
    //    NSStreamStatusAtEnd = 5,
    //    NSStreamStatusClosed = 6,
    //    NSStreamStatusError = 7
    NSLog(@"Stream Status: %lu", (unsigned long) [outputStream streamStatus]);
    if (_isConnected == YES) { // to stream the status has to be NSStreamStatusOpen = 2
        if ([outputStream streamStatus] == NSStreamStatusOpen) {
            [outputStream write:globalData.mutableBytes maxLength:globalData.length];
            globalData = [[NSMutableData alloc] init];
        }
    }
    
}

//-(void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
//    char szBuf[450];
//    int  nSize = sizeof(szBuf);
//
//    if ([self encoderAAC:sampleBuffer aacData:szBuf aacLen:&nSize] == YES)
//    {
//        [self sendAudioData:szBuf len:nSize channel:0];
//    }
//}

//-(BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer {
//
//    if (m_converter != nil)
//    {
//        return TRUE;
//    }
//
//    AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)));
//    AudioStreamBasicDescription outputFormat;
//    memset(&outputFormat, 0, sizeof(outputFormat));
//    outputFormat.mSampleRate       = inputFormat.mSampleRate;
//    outputFormat.mFormatID         = kAudioFormatMPEG4AAC;
//    outputFormat.mChannelsPerFrame = 2;
//    outputFormat.mFramesPerPacket  = 1024;
//
//    AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
//    if (AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, desc, &m_converter) != noErr)
//    {
//        NSLog(@"AudioConverterNewSpecific failed");
//        return NO;
//    }
//
//    return YES;
//}
//
//-(BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char*)aacData aacLen:(int*)aacLen {
//
//    if ([self createAudioConvert:sampleBuffer] != YES)
//    {
//        return NO;
//    }
//
//    CMBlockBufferRef blockBuffer = nil;
//    AudioBufferList  inBufferList;
//    if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr)
//    {
//        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
//        return NO;
//    }
//
//    AudioBufferList outBufferList;
//    outBufferList.mNumberBuffers              = 1;
//    outBufferList.mBuffers[0].mNumberChannels = 2;
//    outBufferList.mBuffers[0].mDataByteSize   = *aacLen;
//    outBufferList.mBuffers[0].mData           = aacData;
//    UInt32 outputDataPacketSize               = 1;
//    if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr)
//    {
//        NSLog(@"AudioConverterFillComplexBuffer failed");
//        return NO;
//    }
//
//    *aacLen = outBufferList.mBuffers[0].mDataByteSize;
//    CFRelease(blockBuffer);
//    return YES;
//}
//
//-(AudioClassDescription*)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer { // 获得相应的编码器
//    static AudioClassDescription audioDesc;
//
//    UInt32 encoderSpecifier = type, size = 0;
//    OSStatus status;
//
//    memset(&audioDesc, 0, sizeof(audioDesc));
//    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
//    if (status)
//    {
//        return nil;
//    }
//
//    uint32_t count = size / sizeof(AudioClassDescription);
//    AudioClassDescription descs[count];
//    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
//    for (uint32_t i = 0; i < count; i++)
//    {
//        if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer))
//        {
//            memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
//            break;
//        }
//    }
//    return &audioDesc;
//}
//
//OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData,AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
//
//    AudioBufferList bufferList = *(AudioBufferList*)inUserData;
//    ioData->mBuffers[0].mNumberChannels = 1;
//    ioData->mBuffers[0].mData           = bufferList.mBuffers[0].mData;
//    ioData->mBuffers[0].mDataByteSize   = bufferList.mBuffers[0].mDataByteSize;
//    return noErr;
//}

@end
