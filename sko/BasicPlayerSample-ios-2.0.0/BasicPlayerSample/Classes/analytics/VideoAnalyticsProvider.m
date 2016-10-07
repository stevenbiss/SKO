/*
 * ADOBE SYSTEMS INCORPORATED
 * Copyright 2015 Adobe Systems Incorporated
 * All Rights Reserved.

 * NOTICE:  Adobe permits you to use, modify, and distribute this file in accordance with the
 * terms of the Adobe license agreement accompanying it.  If you have received this file from a
 * source other than Adobe, then your use, modification, or distribution of it requires the prior
 * written permission of Adobe.
 */

#import "VideoAnalyticsProvider.h"
#import "ADBMediaHeartbeat.h"
#import "ADBMediaHeartbeatConfig.h"
#import "ADBStandardMetadataKeys.h"

NSString *const PLAYER_NAME = @"SKO iOS VOD";
NSString *const VIDEO_ID	= @"SKO iOS VOD";
NSString *const VIDEO_NAME	= @"SKO iOS VOD";

NSString *const HEARTBEAT_TRACKING_SERVER	= @"stevenbiss.hb.omtrdc.net";
NSString *const HEARTBEAT_CHANNEL			= @"test-channel";
NSString *const HEARTBEAT_OVP_NAME			= @"test-ovp";
NSString *const HEARTBEAT_APP_VERSION		= @"VHL2 Sample Player v1.0";

double const VIDEO_LENGTH = 600;

@implementation VideoAnalyticsProvider
{
	ADBMediaHeartbeat *_mediaHeartbeat;
	__weak id<VideoPlayerDelegate> _playerDelegate;
}

#pragma mark Initializer & dealloc

- (instancetype)initWithPlayerDelegate:(id<VideoPlayerDelegate>)playerDelegate
{
    if (self = [super init])
    {
        _playerDelegate = playerDelegate;
		
		// Media Heartbeat Initialization
		ADBMediaHeartbeatConfig *config = [[ADBMediaHeartbeatConfig alloc] init];

		config.trackingServer = HEARTBEAT_TRACKING_SERVER;
		config.channel = HEARTBEAT_CHANNEL;
		config.appVersion = HEARTBEAT_APP_VERSION;
        config.ovp = HEARTBEAT_OVP_NAME;
		config.playerName = PLAYER_NAME;
		config.ssl = NO;
		config.debugLogging = NO;
		
		_mediaHeartbeat = [[ADBMediaHeartbeat alloc] initWithDelegate:self config:config];
		
        [self setupPlayerNotifications];
    }

    return self;
}

- (void)dealloc
{
    [self destroy];
}

- (ADBMediaObject *)getQoSObject
{
	return [ADBMediaHeartbeat createQoSObjectWithBitrate:500000 startupTime:2 fps:24 droppedFrames:10];
}

- (NSTimeInterval)getCurrentPlaybackTime
{
	return [_playerDelegate getCurrentPlaybackTime];
}


#pragma mark Public methods

- (void)destroy
{
    // Detach from the notification center.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _mediaHeartbeat = nil;
	_playerDelegate = nil;
}


#pragma mark VideoPlayer notification handlers

- (void)onMainVideoLoaded:(NSNotification *)notification
{
    ADBMediaObject *mediaObject = [ADBMediaHeartbeat createMediaObjectWithName:VIDEO_NAME
                                                                       mediaId:VIDEO_ID
                                                                        length:VIDEO_LENGTH
                                                                    streamType:ADBMediaHeartbeatStreamTypeVOD];
    // Sample implementation for using standard metadata keys
    NSMutableDictionary *standardVideoMetadata = [[NSMutableDictionary alloc] init];
    [standardVideoMetadata setObject:@"Sample show" forKey:ADBVideoMetadataKeySHOW];
    [standardVideoMetadata setObject:@"Sample Season" forKey:ADBVideoMetadataKeySEASON];
    [mediaObject setValue:standardVideoMetadata forKey:ADBMediaObjectKeyStandardVideoMetadata];
    
    //Attaching custom metadata
    NSMutableDictionary *videoMetadata = [[NSMutableDictionary alloc] init];
    [videoMetadata setObject:@"false" forKey:@"isUserLoggedIn"];
    [videoMetadata setObject:@"Sample TV station" forKey:@"tvStation"];
    [videoMetadata setObject:@"iOS SDK" forKey:@"sko_source"];
    [videoMetadata setObject:@"SKO.VHLSample.iOS" forKey:@"pageName"];
    [videoMetadata setObject:@"VOD" forKey:@"streamType"];
        
	[_mediaHeartbeat trackSessionStart:mediaObject data:videoMetadata];
}

- (void)onMainVideoUnloaded:(NSNotification *)notification
{
    [_mediaHeartbeat trackSessionEnd];
}

- (void)onPlay:(NSNotification *)notification
{
    [_mediaHeartbeat trackPlay];
}

- (void)onStop:(NSNotification *)notification
{
    [_mediaHeartbeat trackPause];
}

- (void)onSeekStart:(NSNotification *)notification
{
	[_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventSeekStart mediaObject:nil data:nil];
}

- (void)onSeekComplete:(NSNotification *)notification
{
    [_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventSeekComplete mediaObject:nil data:nil];
}

- (void)onComplete:(NSNotification *)notification
{
    [_mediaHeartbeat trackComplete];
}

- (void)onChapterStart:(NSNotification *)notification
{
    NSMutableDictionary *chapterDictionary = [[NSMutableDictionary alloc] init];
    [chapterDictionary setObject:@"Sample segment type" forKey:@"segmentType"];
	
	NSDictionary *chapterData = notification.userInfo;
	id chapterObject = [ADBMediaHeartbeat createChapterObjectWithName:[chapterData objectForKey:@"name"]
														 position:[[chapterData objectForKey:@"position"] doubleValue]
														   length:[[chapterData objectForKey:@"length"] doubleValue]
														startTime:[[chapterData objectForKey:@"time"] doubleValue]];
	
    
	[_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventChapterStart mediaObject:chapterObject	data:chapterDictionary];
}

- (void)onChapterComplete:(NSNotification *)notification
{
    [_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventChapterComplete mediaObject:nil data:nil];
}

- (void)onAdStart:(NSNotification *)notification
{
	NSDictionary *adData = [notification.userInfo objectForKey:@"ad"];
	NSDictionary *adBreakData = [notification.userInfo objectForKey:@"adbreak"];
	
	id adBreakObject = [ADBMediaHeartbeat createAdBreakObjectWithName:[adBreakData objectForKey:@"name"]
														 position:[[adBreakData objectForKey:@"position"] doubleValue]
														startTime:[[adBreakData objectForKey:@"time"] doubleValue]];
	
	id adObject = [ADBMediaHeartbeat createAdObjectWithName:[adData objectForKey:@"name"]
												   adId:[adData objectForKey:@"id"]
											   position:[[adData objectForKey:@"position"] doubleValue]
												 length:[[adData objectForKey:@"time"] doubleValue]];
	
    // Sample implementation for using standard metadata keys for Ad
    NSMutableDictionary *standardAdMetadata = [[NSMutableDictionary alloc] init];
    [standardAdMetadata setObject:@"Sample Advertiser" forKey:ADBAdMetadataKeyADVERTISER];
    [standardAdMetadata setObject:@"Sample Campaign" forKey:ADBAdMetadataKeyCAMPAIGN_ID];
    [adObject setValue:standardAdMetadata forKey:ADBMediaObjectKeyStandardAdMetadata];
    
    //Attach custom metadata parameters (context data)
    NSMutableDictionary *adDictionary = [[NSMutableDictionary alloc] init];
    [adDictionary setObject:@"Sample affiliate" forKey:@"affiliate"];
    
	[_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdBreakStart mediaObject:adBreakObject data:nil];
	[_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdStart mediaObject:adObject data:adDictionary];
}

- (void)onAdComplete:(NSNotification *)notification
{
    [_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdComplete mediaObject:nil data:nil];
    [_mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdBreakComplete mediaObject:nil data:nil];
}

#pragma mark - Private helper methods

- (void)setupPlayerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMainVideoLoaded:)
                                                 name:PLAYER_EVENT_VIDEO_LOAD
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMainVideoUnloaded:)
                                                 name:PLAYER_EVENT_VIDEO_UNLOAD
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlay:)
                                                 name:PLAYER_EVENT_PLAY
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStop:)
                                                 name:PLAYER_EVENT_PAUSE
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSeekStart:)
                                                 name:PLAYER_EVENT_SEEK_START
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSeekComplete:)
                                                 name:PLAYER_EVENT_SEEK_COMPLETE
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onComplete:)
                                                 name:PLAYER_EVENT_COMPLETE
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onChapterStart:)
                                                 name:PLAYER_EVENT_CHAPTER_START
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onChapterComplete:)
                                                 name:PLAYER_EVENT_CHAPTER_COMPLETE
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAdStart:)
                                                 name:PLAYER_EVENT_AD_START
                                               object:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAdComplete:)
                                                 name:PLAYER_EVENT_AD_COMPLETE
                                               object:NULL];
}

@end
