# README 

## Preparation

### ffmpeg
We need ffmpeg to pusblish streaming and listen stream
Install ffmpeg `brew install ffmpeg` 
Test port is `10001` 
`ffplay 10001acc.sdp -protocol_whitelist file,udp,rtp` 

### iOS App 

1. Set the IP address where we will publish the streaming
2. 


### Connector
The connector as a 




```
CMSampleBuffer 0x101848880 retainCount: 1 allocator: 0x7fff8bc36b60
    invalid = NO
    dataReady = YES
    makeDataReadyCallback = 0x0
    makeDataReadyRefcon = 0x0
    buffer-level attachments:
        com.apple.cmio.buffer_attachment.source_audio_format_description(P) = <CMAudioFormatDescription 0x6000033052c0 [0x7fff8bc36b60]> {
    mediaType:'soun' 
    mediaSubType:'lpcm' 
    mediaSpecific: {
        ASBD: {
            mSampleRate: 44100.000000 
            mFormatID: 'lpcm' 
            mFormatFlags: 0x9 
            mBytesPerPacket: 4 
            mFramesPerPacket: 1 
            mBytesPerFrame: 4 
            mChannelsPerFrame: 1 
            mBitsPerChannel: 32     } 
        cookie: {(null)} 
        ACL: {(null)}
        FormatList Array: {
            Index: 0 
            ChannelLayoutTag: 0x640001 
            ASBD: {
            mSampleRate: 44100.000000 
            mFormatID: 'lpcm' 
            mFormatFlags: 0x9 
            mBytesPerPacket: 4 
            mFramesPerPacket: 1 
            mBytesPerFrame: 4 
            mChannelsPerFrame: 1 
            mBitsPerChannel: 32     }} 
    } 
    extensions: {(null)}
}
        com.apple.cmio.buffer_attachment.sequence_number(P) = 0
        com.apple.cmio.buffer_attachment.discontinuity_flags(P) = 131072
        com.apple.cmio.buffer_attachment.client_sequence_id(P) = 0x600000280660 : 13 : 0 : 2 : 3
        com.apple.cmio.buffer_attachment.audio.core_audio_audio_time_stamp(P) = <CFData 0x600002c49000 [0x7fff8bc36b60]>{length = 64, capacity = 64, bytes = 0x000000000004cf40e0b66023d8ca0000 ... 0300000000000000}
    formatDescription = <CMAudioFormatDescription 0x600003304f00 [0x7fff8bc36b60]> {
    mediaType:'soun' 
    mediaSubType:'aac ' 
    mediaSpecific: {
        ASBD: {
            mSampleRate: 44100.000000 
            mFormatID: 'aac ' 
            mFormatFlags: 0x0 
            mBytesPerPacket: 0 
            mFramesPerPacket: 1024 
            mBytesPerFrame: 0 
            mChannelsPerFrame: 1 
            mBitsPerChannel: 0     } 
        cookie: {<CFData 0x600002938850 [0x7fff8bc36b60]>{length = 39, capacity = 39, bytes = 0x03808080220000000480808014401400 ... 1208068080800102}} 
        ACL: {Mono}
        FormatList Array: {
            Index: 0 
            ChannelLayoutTag: 0x640001 
            ASBD: {
            mSampleRate: 44100.000000 
            mFormatID: 'aac ' 
            mFormatFlags: 0x0 
            mBytesPerPacket: 0 
            mFramesPerPacket: 1024 
            mBytesPerFrame: 0 
            mChannelsPerFrame: 1 
            mBitsPerChannel: 0     }} 
    } 
    extensions: {(null)}
}
    sbufToTrackReadiness = 0x0
    numSamples = 1
    outputPTS = {9835607286/44100 = 223029.644, rounded}(based on cachedOutputPresentationTimeStamp)
    sampleTimingArray[1] = {
        {PTS = {9835607286/44100 = 223029.644, rounded}, DTS = {INVALID}, duration = {1024/44100 = 0.023}},
    }
    sampleSizeArray[1] = {
        sampleSize = 4,
    }
    dataBuffer = 0x600003006f40

```
