//
//  HTEPanelViewController.m
//  HTSourceExtension
//
//  Created by John on 2018/5/24.
//  Copyright © 2018年 John. All rights reserved.
//

#import "HTEPanelViewController.h"

@interface HTEPanelViewController () <NSTextFieldDelegate>

@property (weak) IBOutlet NSColorWell *colorWell;
@property (weak) IBOutlet NSTextField *colorTextField;
@property (nonatomic) NSButton *finderButton;
@property (nonatomic) NSButton *xcodeButton;
@property (nonatomic) NSImageView *imageView;
@property (nonatomic) NSString *imagePath;
@property (nonatomic) BOOL shouldChangeTextField;

@end

@implementation HTEPanelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (self.hexColorStr) {
		self.colorTextField.stringValue = self.hexColorStr;
		self.colorWell.color = [self colorWithHexString:self.hexColorStr];
		self.colorWell.color = [self colorWithHexString:self.hexColorStr];
		[self.colorWell addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionNew context:nil];
		self.colorTextField.delegate = self;
		self.shouldChangeTextField = YES;
	} else if (self.imageName) {
		self.colorTextField.hidden = self.colorWell.hidden = YES;
		self.view.frame = NSMakeRect(0, 0, 300, 300);
		self.finderButton = [NSButton buttonWithTitle:@"在Finder中查看" target:self action:@selector(openInFinder)];
		self.finderButton.frame = NSMakeRect(90, 40, 120, 40);
		self.finderButton.hidden = YES;
		[self.view addSubview:self.finderButton];
		
		self.xcodeButton = [NSButton buttonWithTitle:@"在Xcode中查看" target:self action:@selector(openInXcode)];
		self.xcodeButton.frame = NSMakeRect(90, 10, 120, 40);
		self.xcodeButton.hidden = YES;
		[self.view addSubview:self.xcodeButton];
		
		self.imageView = [[NSImageView alloc] init];
		self.imageView.frame = NSMakeRect(50, 90, 200, 200);
		[self.view addSubview:self.imageView];
		[self runSearchScript];
	}
}

- (void)openInXcode
{
	NSString *cmd = @"osascript -e 'tell application \"Xcode\" to open \"%@\" '";
	cmd = [NSString stringWithFormat:cmd, self.imagePath];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		system(cmd.UTF8String);
	});
	[self.view.window close];
}

- (void)openInFinder
{
	NSURL *fileUrl = [NSURL fileURLWithPath:self.imagePath];
	[NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[fileUrl]];
	[self.view.window close];
}

- (void)runSearchScript
{
	NSURL *scriptUrl = [[NSBundle mainBundle] URLForResource:@"SourceHelper" withExtension:@"scpt"];
	NSUserAppleScriptTask *task = [[NSUserAppleScriptTask alloc] initWithURL:scriptUrl error:nil];
	[task executeWithAppleEvent:nil completionHandler:^(NSAppleEventDescriptor * _Nullable result, NSError * _Nullable error) {
		[self searchImageInWorkspace:result.stringValue.stringByDeletingLastPathComponent];
	}];
}

- (void)searchImageInWorkspace:(NSString *)workspacePath
{
	if ([NSFileManager.defaultManager fileExistsAtPath:workspacePath]) {
		NSMutableArray *imageArray = [NSMutableArray new];
		NSMutableArray *imageSetArray = [NSMutableArray new];
//		NSDirectoryEnumerator *workSpaceEnum = [NSFileManager.defaultManager enumeratorAtPath:workspacePath];
		NSDirectoryEnumerator *workSpaceEnum = [NSFileManager.defaultManager enumeratorAtURL:[NSURL fileURLWithPath:workspacePath]
																  includingPropertiesForKeys:@[NSURLIsDirectoryKey]
																					 options:NSDirectoryEnumerationSkipsHiddenFiles
																				errorHandler:nil];
		for (NSURL *fileUrl in workSpaceEnum) {
			NSNumber *isDirectory = nil;
			[fileUrl getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
			if (isDirectory.boolValue) {
				if ([fileUrl.pathExtension isEqualToString:@"imageset"]) {
					[imageSetArray addObject:fileUrl.path];
					[workSpaceEnum skipDescendents];
				}
			} else {
				NSString *ext = fileUrl.pathExtension;
				if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"jpg"] ||
					[ext isEqualToString:@"jpeg"]) {
					[imageArray addObject:fileUrl.path];
				}
			}
		}
		NSMutableArray *possibleImageArray = [NSMutableArray new];
		for (NSString *itemPath in imageArray) {
			if ([itemPath.lastPathComponent hasPrefix:self.imageName]) {
				[possibleImageArray addObject:itemPath];
			}
		}
		for (NSString *setPath in imageSetArray) {
			if ([setPath.lastPathComponent hasPrefix:self.imageName]) {
				NSArray *contentArray = [NSFileManager.defaultManager contentsOfDirectoryAtPath:setPath error:nil];
				for (NSString *setItem in contentArray) {
					if ([setItem hasSuffix:@".png"] || [setItem hasSuffix:@".jpg"] || [setItem hasSuffix:@".jpeg"]) {
						[possibleImageArray addObject:[setPath stringByAppendingPathComponent:setItem]];
						break;
					}
				}
			}
		}
		NSLog(@"%@", possibleImageArray);
		if (possibleImageArray.count) {
			self.imagePath = possibleImageArray.firstObject;
			NSImage *image = [[NSImage alloc] initWithContentsOfFile:self.imagePath];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.xcodeButton.hidden = self.finderButton.hidden = NO;
				self.imageView.image = image;
			});
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				NSTextField *textField = [[NSTextField alloc] init];
				textField.editable = NO;
				textField.alignment = NSTextAlignmentCenter;
				textField.bordered = NO;
				textField.backgroundColor = NSColor.clearColor;
				textField.stringValue = @"找不到图片";
				textField.frame = NSMakeRect(90, 120, 120, 40);
				[self.view addSubview:textField];
			});
		}
	}
}

- (NSColor *)colorWithHexString:(NSString *)hex
{
	unsigned int hexColor = 0;
	[[NSScanner scannerWithString:hex] scanHexInt:&hexColor];
	float red = ((float)((hexColor & 0xFF0000) >> 16))/255.0;
	float green = ((float)((hexColor & 0xFF00) >> 8))/255.0;
	float blue = ((float)(hexColor & 0xFF))/255.0;
	return [NSColor colorWithRed:red green:green blue:blue alpha:1];
}

- (void)controlTextDidChange:(NSNotification *)obj
{
	self.shouldChangeTextField = NO;
	self.colorWell.color = [self colorWithHexString:self.colorTextField.stringValue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"color"]) {
		NSColor *newColor = change[NSKeyValueChangeNewKey];
		int red = newColor.redComponent * 255 + 0.5;  //四舍五入
		int green = newColor.greenComponent * 255 + 0.5;
		int blue = newColor.blueComponent * 255 + 0.5;
		if (self.shouldChangeTextField) {
			self.colorTextField.stringValue = [NSString stringWithFormat:@"0x%02X%02X%02X", red, green, blue];
		}
		self.shouldChangeTextField = YES;
	}
}

@end
