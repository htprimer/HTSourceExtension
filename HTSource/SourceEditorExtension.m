//
//  SourceEditorExtension.m
//  HTSource
//
//  Created by John on 2018/5/22.
//  Copyright © 2018年 John. All rights reserved.
//

#import "SourceEditorExtension.h"

@implementation SourceEditorExtension

/*
- (void)extensionDidFinishLaunching
{
    // If your extension needs to do any work at launch, implement this optional method.
}
*/


- (NSArray <NSDictionary <XCSourceEditorCommandDefinitionKey, id> *> *)commandDefinitions
{
    // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
	return @[@{
				 XCSourceEditorCommandNameKey:@"Help",
				 XCSourceEditorCommandIdentifierKey:@"htprimer.help",
				 XCSourceEditorCommandClassNameKey:@"SourceEditorCommand"
				 },
			 @{
				 XCSourceEditorCommandNameKey:@"Generate",
				 XCSourceEditorCommandIdentifierKey:@"htprimer.source",
				 XCSourceEditorCommandClassNameKey:@"SourceEditorCommand"
				 }];
}


@end
