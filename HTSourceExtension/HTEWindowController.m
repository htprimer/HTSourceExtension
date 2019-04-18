//
//  HTEWindowController.m
//  HTSourceExtension
//
//  Created by John on 2018/5/24.
//  Copyright © 2018年 John. All rights reserved.
//

#import "HTEWindowController.h"
#import "HTEHelpViewController.h"
#import "HTEPanelViewController.h"

@interface HTEWindowController ()

@end

@implementation HTEWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
	self.window.alphaValue = 0;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if (self.window.contentViewController == nil) {
			self.window.alphaValue = 1;
			self.window.contentViewController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"Help"];
		}
	});
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(receiveInfo:) name:@"SourceExtensionInfo" object:nil];
}

- (void)receiveInfo:(NSNotification *)noti
{
	NSArray *urlArray = noti.userInfo[@"urls"];
	if (urlArray.count) {
		NSURL *urlString = urlArray.firstObject;
		NSURLComponents *url = [NSURLComponents componentsWithString:urlString.absoluteString];
		if ([url.queryItems.firstObject.name isEqualToString:@"color"]) {
			NSString *hexString = url.queryItems.firstObject.value;
			self.window.title = @"Color Check";
			HTEPanelViewController *panel = [[HTEPanelViewController alloc] init];
			panel.hexColorStr = hexString;
			self.window.alphaValue = 1;
			self.window.contentViewController = panel;
		} else if ([url.queryItems.firstObject.name isEqualToString:@"image"]) {
			NSString *imageName = url.queryItems.firstObject.value;
			self.window.title = @"Image Check";
			HTEPanelViewController *panel = [[HTEPanelViewController alloc] init];
			panel.imageName = imageName;
			self.window.alphaValue = 1;
			self.window.contentViewController = panel;
		}
	}
}

@end
