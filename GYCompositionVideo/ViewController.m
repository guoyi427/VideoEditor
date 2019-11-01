//
//  ViewController.m
//  GYCompositionVideo
//
//  Created by guo yi on 10/31/19.
//  Copyright © 2019 guo yi. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "VideoEditor.h"
#import "AVUtilities.h"

@interface ViewController ()
{
    AVPlayer *_player;
    AVPlayerLayer *_playerLayer;
    VideoEditor *_editor;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareEditor];
    [self prepareUI];
}

#pragma mark - Setup UI

- (void)prepareEditor {
    _editor = [[VideoEditor alloc] init];
    
    for (int i = 1; i <= 4; i ++) {
        NSString *videoName = [NSString stringWithFormat:@"test%d", i];
        NSURL *url = [NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:videoName ofType:@"MP4"]];
        AVAsset *asset = [AVAsset assetWithURL:url];
        [_editor.videoAssets addObject:asset];
        
//        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, CMTimeMake((CMTimeGetSeconds(asset.duration) - 0.5) * 600, 600));
        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, CMTimeMake(5 * 600, 600));
        [_editor.videoRanges addObject:[NSValue valueWithCMTimeRange:range]];
    }
    [_editor compositionVideos];
}

- (void)prepareUI {
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:_editor.composition];
    playerItem.videoComposition = _editor.videoComposition;
    
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.view.bounds;
    _playerLayer.position = self.view.center;
    [self.view.layer addSublayer:_playerLayer];
    
    [_player play];
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    playButton.frame = CGRectMake(0, CGRectGetMaxY(self.view.bounds) - 100, 100, 40);
    [playButton addTarget:self action:@selector(playButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [playButton setTitle:@"play" forState:UIControlStateNormal];
    [playButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [self.view addSubview:playButton];
}

- (void)prepareRevers {
    NSString *videoName = [NSString stringWithFormat:@"test%d", 1];
    NSURL *url = [NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:videoName ofType:@"MP4"]];
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    NSString *reversVideoName = [NSString stringWithFormat:@"reversTest%d.MP4", 1];
    NSString *reversPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:reversVideoName];
    NSURL *reversUrl = [NSURL fileURLWithPath: reversPath];
    
    [AVUtilities assetByReversingAsset:asset outputURL:reversUrl complete:^(AVAsset *outputAsset) {
        [self->_editor.videoAssets addObject:outputAsset];
        CMTimeRange reversRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake((CMTimeGetSeconds(outputAsset.duration) - 0.5) * 600, 600));
        [self->_editor.videoRanges addObject:[NSValue valueWithCMTimeRange:reversRange]];
    }];
}

#pragma mark - Button Action

- (void)playButtonAction {
    [_player seekToTime:kCMTimeZero];
    [_player play];
}

@end
