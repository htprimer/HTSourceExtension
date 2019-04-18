//
//  AppDelegate.m
//  HTSourceExtension
//
//  Created by John on 2018/5/22.
//  Copyright © 2018年 John. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls
{
	[NSNotificationCenter.defaultCenter postNotificationName:@"SourceExtensionInfo" object:nil userInfo:@{@"urls":urls}];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

@end
