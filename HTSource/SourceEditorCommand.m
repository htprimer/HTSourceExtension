//
//  SourceEditorCommand.m
//  HTSource
//
//  Created by John on 2018/5/22.
//  Copyright © 2018年 John. All rights reserved.
//

#import "SourceEditorCommand.h"
#import <AppKit/AppKit.h>
#import "SourcewindowController.h"

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
	if ([invocation.commandIdentifier isEqualToString:@"htprimer.help"]) {
		[self showHelp];
	} else {
		XCSourceTextRange *selectedRange = invocation.buffer.selections.firstObject;
		NSInteger currentIndex = selectedRange.start.line;
		NSString *selectedLine = invocation.buffer.lines[currentIndex];
		NSString *lineStr = [selectedLine stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
		NSString *selectedStr = [selectedLine substringWithRange:NSMakeRange(selectedRange.start.column, selectedRange.end.column-selectedRange.start.column)];
		if (selectedRange.start.line == selectedRange.end.line) {
			if ([lineStr hasPrefix:@"#import"]) {
				[self import:invocation.buffer];
			} else if ([selectedStr hasPrefix:@"0x"] || [selectedStr hasPrefix:@"0X"]) {
				[self showColorWithHexColor:selectedStr];
			} else if ([lineStr hasSuffix:@"Button"]) {
				[self createButton:invocation.buffer];
			} else if ([lineStr hasSuffix:@"View"]) {
				[self createView:invocation.buffer];
			} else if (selectedStr.length && ![selectedStr containsString:@" "]) {
				[self showImageWithImageName:selectedStr];
			} else if (lineStr.length) {
				[self runCommand:invocation.buffer];
			}
		}
	}
	completionHandler(nil);
}

- (void)import:(XCSourceTextBuffer *)buffer
{
	XCSourceTextRange *selectedRange = buffer.selections.firstObject;
	NSInteger currentIndex = selectedRange.start.line;
	NSString *selectedLine = buffer.lines[currentIndex];
	NSString *lineStr = [selectedLine stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	int lastImportLine = 0;
	for (int i = 0; i < buffer.lines.count; i++) {
		if ([buffer.lines[i] hasPrefix:@"#import"]) {
			lastImportLine = i;
		} else if ([buffer.lines[i] hasPrefix:@"@"]) {
			break;
		}
	}
	[buffer.lines removeObjectAtIndex:currentIndex];
	[buffer.lines insertObject:lineStr atIndex:lastImportLine+1];
	[buffer.selections removeAllObjects];
	[buffer.selections addObject:[[XCSourceTextRange alloc] initWithStart:selectedRange.start end:selectedRange.start]];
}

- (void)showHelp
{
	system("open /Applications/HTSourceExtension.app");
}

- (void)insertCode:(NSString *)code tab:(NSString *)tab atIndex:(NSUInteger)index InBuffer:(XCSourceTextBuffer *)buffer
{
	if (index >= buffer.lines.count) {
		index = buffer.lines.count;
		[buffer.lines addObject:@"\n"];
	}
	NSArray<NSString *> *lineArray = [code componentsSeparatedByString:@"\n"];
	for (NSInteger i = lineArray.count-1; i >= 0; i--) {
		NSString *line = lineArray[i];
		[buffer.lines insertObject:[tab stringByAppendingString:line] atIndex:index];
	}
}

- (void)showColorWithHexColor:(NSString *)hexColor
{
	NSURL *scheme = [NSURL URLWithString:[@"HTSource://extension?color=" stringByAppendingString:hexColor]];
	[NSWorkspace.sharedWorkspace openURL:scheme];
}

- (void)showImageWithImageName:(NSString *)imageName
{
	NSURL *scheme = [NSURL URLWithString:[@"HTSource://extension?image=" stringByAppendingString:imageName]];
	[NSWorkspace.sharedWorkspace openURL:scheme];
}

- (void)createButton:(XCSourceTextBuffer *)buffer
{
	XCSourceTextRange *selectedRange = buffer.selections.firstObject;
	NSInteger currentIndex = selectedRange.start.line;
	NSString *selectedLine = buffer.lines[currentIndex];
	NSString *buttonName = [selectedLine stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	
	NSArray<NSString *> *nameArray = [buttonName componentsSeparatedByString:@"."];
	if (nameArray.count > 2) {
		return;
	}
	NSString *varName = nameArray.lastObject;
	NSString *methodName = [[varName stringByReplacingOccurrencesOfString:@"Button" withString:@""] stringByAppendingString:@"Action"];
	
	NSString *tab = [selectedLine substringToIndex:selectedRange.end.column-buttonName.length];
	NSString *createStr = @"%@ = [UIButton buttonWithType:UIButtonTypeCustom];";
	NSString *addStr = @"[<#%@ addSubview:%@];";
	NSString *targetStr = @"[%@ addTarget:self action:@selector(%@) forControlEvents:UIControlEventTouchUpInside];";
	NSString *titleStr = @"[%@ setTitle:@\"<#%@ forState:UIControlStateNormal];";
	NSString *masonry = @"[%@ mas_makeConstraints:^(MASConstraintMaker *make) {\n\t<#%@\n}];";
	if (nameArray.count == 1) createStr = @"UIButton *%@ = [UIButton buttonWithType:UIButtonTypeCustom];";
	
	createStr = [NSString stringWithFormat:createStr, buttonName];
	addStr = [NSString stringWithFormat:addStr, @"self.view#>", buttonName];
	targetStr = [NSString stringWithFormat:targetStr, buttonName, methodName];
	titleStr = [NSString stringWithFormat:titleStr, buttonName, @"title#>\""];
	masonry = [NSString stringWithFormat:masonry, buttonName, @"make#>"];
	
	if (currentIndex == buffer.lines.count - 1) [buffer.lines addObject:@"\n"];
	
	buffer.lines[currentIndex] = [tab stringByAppendingString:createStr];
	[buffer.lines insertObject:[tab stringByAppendingString:addStr] atIndex:currentIndex+1];
	[buffer.lines insertObject:[tab stringByAppendingString:targetStr] atIndex:currentIndex+2];
	[buffer.lines insertObject:[tab stringByAppendingString:titleStr] atIndex:currentIndex+3];
	[self insertCode:masonry tab:tab atIndex:currentIndex+4 InBuffer:buffer];
	
	NSInteger methodIndex = currentIndex + 3;
	if (methodIndex < buffer.lines.count) {
		for (NSInteger index = currentIndex+3; index < buffer.lines.count; index++) {
			NSString *line = buffer.lines[index];
			if ([line hasPrefix:@"}"]) {
				methodIndex = index + 1;
				break;
			}
		}
	}
	NSString *methodStr = [NSString stringWithFormat:@"- (void)%@", methodName];
	methodStr = [@"\n" stringByAppendingFormat:@"%@\n{\n\t<#code", methodStr];
	methodStr = [methodStr stringByAppendingString:@"#>\n}"];
	[self insertCode:methodStr tab:@"" atIndex:methodIndex InBuffer:buffer];
	
	[buffer.selections removeAllObjects];
	[buffer.selections addObject:[[XCSourceTextRange alloc] initWithStart:selectedRange.start end:selectedRange.start]];
}

- (void)createView:(XCSourceTextBuffer *)buffer
{
	XCSourceTextRange *selectedRange = buffer.selections.firstObject;
	NSInteger currentIndex = selectedRange.start.line;
	NSString *selectedLine = buffer.lines[currentIndex];
	NSString *viewName = [selectedLine stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	
	NSArray<NSString *> *nameArray = [viewName componentsSeparatedByString:@"."];
	if (nameArray.count > 2) {
		return;
	}
	NSString *tab = [selectedLine substringToIndex:selectedRange.end.column-viewName.length];
	NSString *code = @"%@ = [[UIView alloc] init];\n"
	"[<#self.view#> addSubview:%@];\n"
	"%@.backgroundColor = <#color#>;\n"
	"[%@ mas_makeConstraints:^(MASConstraintMaker *make) {\n"
	"	make.<#top#>.equalTo(@<#0#>);\n"
	"	make.<#left#>.equalTo(@<#0#>);\n"
	"}];";
	if (nameArray.count == 1) {
		code = [NSString stringWithFormat:code, [@"UIView *" stringByAppendingString:viewName], viewName, viewName, viewName];
	} else {
		code = [NSString stringWithFormat:code, viewName, viewName, viewName, viewName];
	}
	[buffer.lines removeObjectAtIndex:currentIndex];
	[self insertCode:code tab:tab atIndex:currentIndex InBuffer:buffer];
	
	[buffer.selections removeAllObjects];
	[buffer.selections addObject:[[XCSourceTextRange alloc] initWithStart:selectedRange.start end:selectedRange.start]];
}

- (void)runCommand:(XCSourceTextBuffer *)buffer
{
	XCSourceTextRange *selectedRange = buffer.selections.firstObject;
	NSInteger currentIndex = selectedRange.start.line;
	NSString *selectedLine = buffer.lines[currentIndex];
	NSString *cmd = [selectedLine stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
	if ([cmd hasPrefix:@"g "]) {
		NSArray *cmdArray = [cmd componentsSeparatedByString:@" "];
		if (cmdArray.count == 2) {
			NSString *code = @"open https://www.google.com.hk/search?q=%@";
			code = [NSString stringWithFormat:code, cmdArray.lastObject];
			system([code UTF8String]);
			buffer.lines[currentIndex] = @"\t";
		}
	} else if ([cmd hasPrefix:@"b "]) {
		NSArray *cmdArray = [cmd componentsSeparatedByString:@" "];
		if (cmdArray.count == 2) {
			NSString *code = @"open https://www.baidu.com/s?wd=%@";
			code = [NSString stringWithFormat:code, cmdArray.lastObject];
			system([code UTF8String]);
			buffer.lines[currentIndex] = @"\t";
		}
	} else if ([cmd hasPrefix:@"e "]) {
		NSArray *cmdArray = [cmd componentsSeparatedByString:@" "];
		if (cmdArray.count == 2) {
			NSString *code = @"open http://www.iciba.com/%@";
			code = [NSString stringWithFormat:code, cmdArray.lastObject];
			system([code UTF8String]);
			buffer.lines[currentIndex] = @"\t";
		}
	} else if ([cmd isEqualToString:@"qq"]) {
		system("open /Applications/QQ.app");
		buffer.lines[currentIndex] = @"\t";
	} else if ([cmd isEqualToString:@"wx"]) {
		system("open /Applications/WeChat.app");
		buffer.lines[currentIndex] = @"\t";
	} else if ([cmd isEqualToString:@"dx"]) {
		system("open /Applications/大象.app");
		buffer.lines[currentIndex] = @"\t";
	} else if ([cmd isEqualToString:@"help"] || [cmd isEqualToString:@"?"]) {
		[self showHelp];
		buffer.lines[currentIndex] = @"\t";
	}
}


@end
