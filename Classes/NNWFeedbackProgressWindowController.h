//
//  NNWFeedbackProgressWindowController.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWFeedbackProgressWindowController : NSWindowController {
@private
	BOOL showingSuccessMessage;
	NSImage *image;
	NSImageView *imageView;
	NSProgressIndicator *progressIndicator;
	NSString *title;
	NSTextField *titleTextField;
}


@property (nonatomic, retain) IBOutlet NSImageView *imageView;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet NSTextField *titleTextField;

+ (void)runWindowWithTitle:(NSString *)aTitle image:(NSImage *)anImage;
+ (void)runWindowWithSuccessMessage:(NSString *)aSuccessMessage image:(NSImage *)anImage;
+ (void)closeWindow;
	
@end
