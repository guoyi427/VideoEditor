//
//  VideoEditor.m
//  GYCompositionVideo
//
//  Created by guo yi on 10/31/19.
//  Copyright © 2019 guo yi. All rights reserved.
//

#import "VideoEditor.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoEditor ()
{
    CGSize _videoSize;
}
@end

@implementation VideoEditor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoAssets = [[NSMutableArray alloc] init];
        _videoRanges = [[NSMutableArray alloc] init];
        
        _composition = [AVMutableComposition composition];
        _videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:_composition];
        
        _videoSize = UIScreen.mainScreen.bounds.size;
    }
    return self;
}

#pragma mark - Public Methods

/// 合成视频
- (void)compositionVideos {
    _composition.naturalSize = _videoSize;
    
    //  音视频轨道各准备两个，其实一个就够，但如果后期需要做过场动画，就需要让视频重叠
    NSMutableArray<AVMutableCompositionTrack *> *videoTrackList = [[NSMutableArray alloc] initWithCapacity:2];
    NSMutableArray<AVMutableCompositionTrack *> *audioTrackList = [[NSMutableArray alloc] initWithCapacity:2];
    
    //  将空白的音视频轨道，加到空白的composition内
    for (int i = 0; i < 2; i ++) {
        AVMutableCompositionTrack *videoTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoTrackList addObject:videoTrack];
        
        AVMutableCompositionTrack *audioTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrackList addObject:audioTrack];
    }
    
    NSInteger assetsCount = _videoAssets.count;
    /// 视频说明数组
    NSMutableArray<AVMutableVideoCompositionInstruction *> *instructionList = [[NSMutableArray alloc] initWithCapacity:assetsCount];
    
    CMTime startTime = kCMTimeZero;
    for (int i = 0; i < _videoAssets.count; i ++) {
        AVAsset *asset = [_videoAssets objectAtIndex:i];
        //  视频源音视频轨
        AVAssetTrack *assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        if (!assetVideoTrack || !assetAudioTrack) {
            continue;
        }
        
        //  按奇偶依次取轨道
        AVMutableCompositionTrack *videoTrack = videoTrackList[i%2];
        AVMutableCompositionTrack *audioTrack = audioTrackList[i%2];
        
        //  将视频按照用户剪辑的range插入到轨道中
        CMTimeRange videoRange = [_videoRanges[i] CMTimeRangeValue];
        [videoTrack insertTimeRange:videoRange ofTrack:assetVideoTrack atTime:startTime error:nil];
        [audioTrack insertTimeRange:videoRange ofTrack:assetAudioTrack atTime:startTime error:nil];
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        //  视频时间点说明
        instruction.timeRange = CMTimeRangeMake(startTime, videoRange.duration);
        
        //  视频涂层说明
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        //  视频size
        [self resetSizeCompositionLayer:layerInstruction asset:asset];
        
        instruction.layerInstructions = @[layerInstruction];
        [instructionList addObject:instruction];
        
        //  时间偏移
        startTime = CMTimeAdd(startTime, videoRange.duration);
    }
    
    _videoComposition.instructions = instructionList;
    _videoComposition.frameDuration = CMTimeMake(1, 30);
    _videoComposition.renderSize = _videoSize;
}

#pragma mark - Private Methods

/// 视频角度
/// @param asset 视频源
- (NSInteger)degreesFromAsset:(AVAsset *)asset {
    NSInteger degrees = 0;
    
    CGAffineTransform transform = asset.tracks.firstObject.preferredTransform;
    if (transform.a == 1 && transform.b == 0 && transform.c == 0 && transform.d == 1) {
        degrees = 0;
    } else if (transform.a == 0 && transform.b == 1 && transform.c == -1 && transform.d == 0) {
        degrees = 90;
    } else if (transform.a == -1 && transform.b == 0 && transform.c == 0 && transform.d == -1) {
        degrees = 180;
    } else if (transform.a == 0 && transform.b == -1 && transform.c == 1 && transform.d == 0) {
        degrees = 270;
    }
    
    return degrees;
}

- (void)resetSizeCompositionLayer:(AVMutableVideoCompositionLayerInstruction *)layerInstruction asset:(AVAsset *)asset {
    CGSize naturalSize = asset.tracks.firstObject.naturalSize;
    NSInteger degrees = [self degreesFromAsset:asset];
    if (degrees == 90) {
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    }
    
    if ((int)(naturalSize.width) % 2 != 0) {
        naturalSize.width += 1.0;
    }

    if (YES) {
        if ([self degreesFromAsset:asset] == 90) {
            CGFloat height = _videoSize.width * naturalSize.height / naturalSize.width;
            CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(_videoSize.width, _videoSize.height/2 - naturalSize.height/4);
            CGAffineTransform t = CGAffineTransformScale(translateToCenter, _videoSize.width/naturalSize.width, height/naturalSize.height);
            
            CGAffineTransform mixedTransform = CGAffineTransformRotate(t, M_PI_2);
            [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
            
        }else{
            CGFloat height = _videoSize.width * naturalSize.height / naturalSize.width;
            CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(0, _videoSize.height/2 - height/2);
            CGAffineTransform t = CGAffineTransformScale(translateToCenter, _videoSize.width/naturalSize.width, height/naturalSize.height);
            [layerInstruction setTransform:t atTime:kCMTimeZero];
        }
    } else {/*
        if (degrees == 90) {
            CGFloat width = _videoSize.height * naturalSize.width/naturalSize.height;
            CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(_videoSize.width/2 + width/2, 0);
            CGAffineTransform t = CGAffineTransformScale(translateToCenter, width/naturalSize.width, _videoSize.height/naturalSize.height);
            
            CGAffineTransform mixedTransform = CGAffineTransformRotate(t, M_PI_2);
            [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
            
        }else{
            CGFloat width = _videoSize.height * naturalSize.width/naturalSize.height;
            CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(_videoSize.width/2 - width/2, 0);
            CGAffineTransform t = CGAffineTransformScale(translateToCenter, width/naturalSize.width, _videoSize.height/naturalSize.height);
            [layerInstruction setTransform:t atTime:kCMTimeZero];
        }*/
    }
}

@end
