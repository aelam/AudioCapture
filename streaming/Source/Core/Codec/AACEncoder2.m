//
//  AACEncoder.m
//  VTH264Demo
//
//  Created by MOON on 2018/7/23.
//  Copyright © 2018年 MOON. All rights reserved.
//

#import "AACEncoder2.h"


NSData *ADTSDataWithPacketLength(NSInteger packetLength) {
    
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

@interface AACEncoder2 ()

@property (nonatomic, assign) AudioConverterRef audioConverter;

@end

@implementation AACEncoder2

- (void)startEncode:(CMSampleBufferRef)sampleBuffer
{
//    CFRetain(sampleBuffer);
//    dispatch_async(self.dataCallbackQueue, ^{
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

        char aacData[4096] = {0};
        int aacLen = sizeof(aacData);
        
        if ([self encoderAAC:sampleBuffer aacData:aacData aacLen:&aacLen] == YES)
        {
            NSData *rawAAC = [NSData dataWithBytes:aacData length:aacLen];
            NSData *adtsHeader = ADTSDataWithPacketLength(aacLen);
            NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
            [fullData appendData:rawAAC];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(getEncodedAudioData:timeStamp:)])
            {
                [self.delegate getEncodedAudioData:fullData timeStamp:timestamp];
            }
        }
//        CFRelease(sampleBuffer);
//    });
}

- (BOOL)createAudioConvert:(CMSampleBufferRef)sampleBuffer
{
    // 根据输入样本初始化一个编码转换器
    if (self.audioConverter != nil)
    {
        return TRUE;
    }
    
    CMFormatDescriptionRef des = CMSampleBufferGetFormatDescription(sampleBuffer);
    // 输入音频格式
    AudioStreamBasicDescription inputFormat = *(CMAudioFormatDescriptionGetStreamBasicDescription(des));
    
    // 这里开始是输出音频格式
    AudioStreamBasicDescription outputFormat = {0}; //
    //memset(&outputFormat, 0, sizeof(outputFormat));
    outputFormat.mSampleRate = inputFormat.mSampleRate; // 采样率保持一致
    outputFormat.mFormatID = kAudioFormatMPEG4AAC; // AAC编码
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC; //用这个硬解码偶尔会失败
    outputFormat.mChannelsPerFrame = self.channelsPerFrame; // 1:单声道；2:立体声
    outputFormat.mFramesPerPacket = 1024; // 每个Packet的帧数量, AAC一帧是1024个字节

    //3.编码器参数
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };

    
    // 硬编码
//    AudioClassDescription *desc = [self getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleHardwareAudioCodecManufacturer];
    OSStatus result = AudioConverterNewSpecific(&inputFormat, &outputFormat, 2, requestedCodecs, &_audioConverter);
    if (result != noErr)
    {
        NSLog(@"AudioConverterNewSpecific failed %@", @(result));
        return NO;
    }

    // 设置编码器属性
    UInt32 temp = kAudioConverterQuality_Medium;
    result = AudioConverterSetProperty(_audioConverter, kAudioConverterCodecQuality, sizeof(temp), &temp);
    if (result != noErr)
    {
        NSLog(@"设置质量失败");
    }

    // 设置比特率 需要注意，AAC并不是随便的码率都可以支持。
    // 比如如果PCM采样率是44100KHz，那么码率可以设置64000bps，如果是16K，可以设置为32000bps。
    UInt32 bitRate = 64000;
    result = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, sizeof(bitRate), &bitRate);
    if (result != noErr)
    {
        NSLog(@"设置比特率失败");
    }
   
    UInt32 value = 0;
    UInt32 size = sizeof(value);
    result = AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &value);
    if (result == noErr)
    {
        NSLog(@"max packet size %@", @(value));
    }
    
    return YES;
}

- (BOOL)encoderAAC:(CMSampleBufferRef)sampleBuffer aacData:(char *)aacData aacLen:(int *)aacLen
{
    // 编码PCM成AAC
    if ([self createAudioConvert:sampleBuffer] != YES)
    {
        return NO;
    }
    
    CMBlockBufferRef blockBuffer = nil;
    AudioBufferList inBufferList;
    if (CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &inBufferList, sizeof(inBufferList), NULL, NULL, 0, &blockBuffer) != noErr)
    {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed");
        return NO;
    }
    
    // 初始化一个输出缓冲列表
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = self.channelsPerFrame;
    outBufferList.mBuffers[0].mDataByteSize = *aacLen; // 设置缓冲区大小
    outBufferList.mBuffers[0].mData = aacData; // 设置AAC缓冲区
    UInt32 outputDataPacketSize = 1;
    OSStatus result = AudioConverterFillComplexBuffer(self.audioConverter, inputDataProc2, &inBufferList, &outputDataPacketSize, &outBufferList, NULL);
    if (result != noErr)
    {
        NSLog(@"AudioConverterFillComplexBuffer failed %@", @(result));
        return NO;
    }
    
    *aacLen = outBufferList.mBuffers[0].mDataByteSize; //设置编码后的AAC大小
    CFRelease(blockBuffer);
    return YES;
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type fromManufacturer:(UInt32)manufacturer
{
    // 获得相应的编码器
    static AudioClassDescription audioDesc;
    
    UInt32 encoderSpecifier = type, size = 0;
    OSStatus status;
    
    memset(&audioDesc, 0, sizeof(audioDesc));
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (status)
    {
        return nil;
    }
    
    uint32_t count = size / sizeof(AudioClassDescription);
    AudioClassDescription descs[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descs);
    for (uint32_t i = 0; i < count; i++)
    {
        if ((type == descs[i].mSubType) && (manufacturer == descs[i].mManufacturer))
        {
            memcpy(&audioDesc, &descs[i], sizeof(audioDesc));
            break;
        }
    }
    
    return &audioDesc;
}

- (void)endEncode
{
    self.audioConverter = nil;
}

#pragma - mark - AudioConverterComplexInputDataProc

static OSStatus inputDataProc2(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    //AudioConverterFillComplexBuffer 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据

    AudioBufferList inBufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = inBufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = inBufferList.mBuffers[0].mDataByteSize;

    return noErr;
}

@end


