//
//  NNWExportOPMLViewController.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWExportOPMLController.h"
#import "RSDataAccount.h"
#import "RSFeed.h"
#import "RSFolder.h"
#import "RSTreeNode.h"


@interface NNWExportOPMLController ()

@property (nonatomic, retain) id<RSAccount> account;
@property (nonatomic, retain) NSMutableArray *feedsAdded;

- (void)runExportSheet;
- (NSData *)accountTreeAsOPMLData;
- (void)addTreeNodes:(NSArray *)treeNodes toString:(NSMutableString *)opmlString indentLevel:(NSUInteger)indentLevel;

@end


@implementation NNWExportOPMLController

@synthesize backgroundWindow;
@synthesize account;
@synthesize feedsAdded;


#pragma mark Dealloc

- (void)dealloc {
	[backgroundWindow release];
	[account release];
	[feedsAdded release];
	[super dealloc];
}


#pragma mark API

- (void)exportOPML:(id<RSAccount>)accountToExport {
	self.feedsAdded = [NSMutableArray array]; //this object might get re-used
	self.account = accountToExport;
	[self runExportSheet];
}


#pragma mark Export OPML Sheet

- (void)exportOPMLPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {	
	if (returnCode == NSOKButton)
		[[self accountTreeAsOPMLData] writeToFile:[(NSSavePanel *)sheet filename] atomically:YES];
}



#define NNW_EXPORT_SUBSCRIPTIONS_FILE NSLocalizedString(@"Export subscriptions file", @"Title for exporting subscriptions")

- (void)runExportSheet {	
	NSSavePanel *sp = [NSSavePanel savePanel];
	[sp setRequiredFileType:@"opml"];	
	[sp setTitle:NNW_EXPORT_SUBSCRIPTIONS_FILE];
	[sp beginSheetForDirectory:nil file:@"MySubscriptions.opml" modalForWindow:self.backgroundWindow modalDelegate:self didEndSelector:@selector(exportOPMLPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}



#pragma mark -
#pragma mark Rendering OPML

- (void)appendOPMLHeaderToString:(NSMutableString *) s {
	[s appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
	[s appendString: @"<!-- OPML generated by NetNewsWire -->\n"];
	[s appendString: @"<opml version=\"1.1\">\n"];
	[s appendString: @"\t<head>\n"];
	[s appendString: @"\t\t<title>mySubscriptions</title>\n"];
	[s appendString: @"\t\t</head>\n"];
}


- (NSString *)convertReservedCharacters:(NSString *)stringToConvert {
	NSMutableString *s = [[stringToConvert mutableCopy] autorelease];
	[s replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	[s replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [s length])];
	return s;
}



- (NSString *)fixupString:(NSString *)s {
	if (s == nil)
		return nil;
	s = [s rs_stringByTrimmingWhitespace];
	s = [self convertReservedCharacters:s];	
	return s;
}


- (void)appendTabs:(NSUInteger)ctTabs toString:(NSMutableString *)s {
	NSUInteger i;
	for (i = 0; i < ctTabs; i++)
		[s appendString:@"\t"];
}


- (void)addTreeNode:(RSTreeNode *)treeNode toString:(NSMutableString *)opmlString indentLevel:(NSUInteger)indentLevel {
	
	id<RSTreeNodeRepresentedObject> representedObject = treeNode.representedObject;
	RSFeed *feed = nil;
	RSFolder *folder = nil;
	NSString *name = [self fixupString:representedObject.nameForDisplay];
	if (RSStringIsEmpty(name))
		name = @"Untitled";
		
	if (treeNode.isGroup)
		folder = (RSFolder *)representedObject;
	else
		feed = (RSFeed *)representedObject;
	
	NSString *feedURLString = nil;
	NSString *homePageURLString = nil;
	if (feed != nil) {
		feedURLString = [self fixupString:[feed.URL absoluteString]];
		homePageURLString = [self fixupString:[feed.homePageURL absoluteString]];		
	}
	
	[self appendTabs:indentLevel toString:opmlString];
	[opmlString appendString:@"<outline text=\""];
	[opmlString appendString:name];	
	[opmlString appendString:@"\" title=\""];
	[opmlString appendString:name];
		
	if (folder != nil)
		[opmlString appendString:@"\">\n"];
	
	else {
		[opmlString appendString:@"\" type=\"rss\" version=\"RSS\" "];
		if (!RSIsEmpty(homePageURLString)) {
			[opmlString appendString:@"htmlUrl=\""];
			[opmlString appendString:homePageURLString];
			[opmlString appendString:@"\" "];
		}
		[opmlString appendString:@"xmlUrl=\""];
		[opmlString appendString:feedURLString];
		[opmlString appendString:@"\"/>\n"];
	}
	
	if (folder != nil) {
		[self addTreeNodes:treeNode.children toString:opmlString indentLevel:indentLevel + 1];
		[self appendTabs:indentLevel + 1 toString:opmlString];
		[opmlString appendString: @"</outline>\n"];
	}
	
	[self.feedsAdded addObject:representedObject];
}


- (void)addTreeNodes:(NSArray *)treeNodes toString:(NSMutableString *)opmlString indentLevel:(NSUInteger)indentLevel {
	for (RSTreeNode *oneTreeNode in treeNodes) {
		id<RSTreeNodeRepresentedObject> oneRepresentedObject = oneTreeNode.representedObject;
		if ([self.feedsAdded rs_containsObjectIdenticalTo:oneRepresentedObject])
			continue;
		[self addTreeNode:oneTreeNode toString:opmlString indentLevel:indentLevel];
	}
}


- (NSString *)accountTreeAsOPML {
	
	//TODO: use something like genx to write XML the correct way
	NSMutableString *opmlString = [[[NSMutableString alloc] init] autorelease];
	[self appendOPMLHeaderToString:opmlString];
	[opmlString appendString:@"\t<body>\n"];

	NSArray *treeNodes = ((RSDataAccount *)(self.account)).accountTreeNode.children;
	[self addTreeNodes:treeNodes toString:opmlString indentLevel:0];

	[opmlString appendString:@"\t</body>\n"];
	[opmlString appendString:@"</opml>\n"];	
	
	return opmlString;
}


- (NSData *)accountTreeAsOPMLData {
	return [[self accountTreeAsOPML] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}


@end
