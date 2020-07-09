//
//  AudioConverter.m
//  streaming
//
//  Created by 汪伦 on 2020/7/2.
//  Copyright © 2020 Naor Lugasi. All rights reserved.
//

#import "AudioConverter.h"

NSData *DataFromAACSample2(CMSampleBufferRef sampleBuffer) {
    
    AudioBufferList audioBufferList;
    NSMutableData *data = [NSMutableData data];
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    
    for( int y=0; y< audioBufferList.mNumberBuffers; y++ ){
        
        AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
        Float32 *frame = (Float32*)audioBuffer.mData;
        
        [data appendBytes:frame length:audioBuffer.mDataByteSize];
        
    }
    
    CFRelease(blockBuffer);
//    CFRelease(ref);
    
    return data;
}

NSData *DataFromAACSample(CMSampleBufferRef sampleBuffer) {
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t lengthAtOffset;
    size_t totalLength;
    char *data;
    CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffset, &totalLength, &data);
    
    NSData *audioData = [NSData dataWithBytes:data length:totalLength];
    
    return audioData;
}

@implementation AudioConverter

- (NSData *)encoderAAC:(CMSampleBufferRef)sampleBuffer {
    char szBuf[450];
    UInt32 nSize = sizeof(szBuf);
    
    [self encoderAAC:sampleBuffer aacData:szBuf aacLen:&nSize];
    return [[NSData alloc] initWithBytes:szBuf length:nSize];
}

- (BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer {
    
    if (m_converter != nil) {
        return TRUE;
    }
    
    AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)));
    AudioStreamBasicDescription outputFormat;
    memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate = inputFormat.mSampleRate;
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;
    outputFormat.mChannelsPerFrame = 2;
    outputFormat.mFramesPerPacket = 1024;
    
    AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    if (AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, desc, &m_converter) != noErr) {
        NSLog(@"AudioConverterNewSpecific failed");
        return NO;
    }
    
    return YES;
}

- (void)disposeConverter {
    AudioConverterDispose(m_converter);
}

- (BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char *)aacData aacLen:(UInt32 *)aacLen {
    
    if ([self createAudioConvert:sampleBuffer] != YES) {
        return NO;
    }
    
    CMBlockBufferRef blockBuffer = nil;
    AudioBufferList inBufferList;
    if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr) {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
        [self disposeConverter];
        return NO;
    }
    
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = 2;
    outBufferList.mBuffers[0].mDataByteSize = (UInt32) * aacLen;
    outBufferList.mBuffers[0].mData = aacData;
    UInt32 outputDataPacketSize = 1;
    if (AudioConverterFillComplexBuffer(m_converter, inputDataProc, &inBufferList, &outputDataPacketSize, &outBufferList, NULL) != noErr) {
        NSLog(@"AudioConverterFillComplexBuffer failed");
        [self disposeConverter];
        return NO;
    }
    
    *aacLen = outBufferList.mBuffers[0].mDataByteSize;
    CFRelease(blockBuffer);
    return YES;
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer { // 获得相应的编码器
    static AudioClassDescription audioDesc;
    
    UInt32 encoderSpecifier = type, size = 0;
    OSStatus status;
    
    memset(&audioDesc, 0, sizeof(audioDesc));
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (status) {
        return nil;
    }
    
    uint32_t count = size / sizeof(AudioClassDescription);
    AudioClassDescription descs[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
    for (uint32_t i = 0; i < count; i++) {
        if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer)) {
            memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
            break;
        }
    }
    return &audioDesc;
}

OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    
    AudioBufferList bufferList = *(AudioBufferList *) inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}

- (void)dealloc {
    NSLog(@"converter dealloc");
}

@end
