//
//  AudioConverter.h
//  streaming
//
//  Created by 汪伦 on 2020/7/2.
//  Copyright © 2020 Naor Lugasi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioConverter : NSObject {
    AudioConverterRef m_converter;
}

- (NSData *)encoderAAC:(CMSampleBufferRef)sampleBuffer;

@end

NSData *DataFromAACSample2(CMSampleBufferRef sampleBuffer);
NSData *DataFromAACSample(CMSampleBufferRef sampleBuffer);

