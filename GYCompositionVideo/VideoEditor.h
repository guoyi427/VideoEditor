//
//  VideoEditor.h
//  GYCompositionVideo
//
//  Created by guo yi on 10/31/19.
//  Copyright © 2019 guo yi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AVMutableComposition, AVMutableVideoComposition, AVAsset;
@interface VideoEditor : NSObject

@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;

@property (nonatomic, strong) NSMutableArray<AVAsset *> *videoAssets;
@property (nonatomic, strong) NSMutableArray *videoRanges;

/// 合成视频
- (void)compositionVideos;

@end

NS_ASSUME_NONNULL_END
