//
//  RSFeedbackHUDViewController.m
//  bobcat
//
//  Created by Brent Simmons on 3/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSFeedbackHUDViewController.h"


#define kHUDMessageWidth 200
#define kHUDMessageHeight 240
#define kHUDMargin 20
#define kHUDMessageFontSize 22
#define KHUDDisplayBeforeFadingDuration 1

@interface BCHUDView : UIView {
@protected
	CGRect _messageRect;
	NSString *_message;
	UIActivityIndicatorView *_activityIndicator;
}
@property (nonatomic, assign) CGRect messageRect;
@property (nonatomic, retain) NSString *message;
@end

@implementation BCHUDView

@synthesize messageRect = _messageRect, message = _message;


- (void)dealloc {
	[_message release];
	[super dealloc];
}


- (void)addActivityIndicatorIfNeeded {
	if (!_activityIndicator) {
		_activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
		[self addSubview:_activityIndicator];
		[_activityIndicator startAnimating];
	}
}


- (void)removeActivityIndicatorIfNeeded {
	if (_activityIndicator) {
		[_activityIndicator stopAnimating];
		[_activityIndicator removeFromSuperview];
		_activityIndicator = nil;
	}
}


- (void)layoutSubviews {
	if (!_activityIndicator)
		return;
	CGRect r = self.bounds;
	CGRect rActivity = CGRectCenteredHorizontallyInRect([_activityIndicator bounds], r);
	rActivity.origin.y = (CGRectGetMaxY(r) - rActivity.size.height) - 16;
	[_activityIndicator setFrame:rActivity];
}


- (UIColor *)backgroundColor {
	return [UIColor clearColor];
}


- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(CGRect)frame {
	
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	CGContextSaveGState(context);
	NSUInteger strokeWidth = 1;
	CGContextSetLineWidth(context, strokeWidth);
	CGRect rBounds = self.bounds;
	
	CGRect r = CGRectMake(3.5f, 3.5f, rBounds.size.width - 7.0f, rBounds.size.height - 7.0f);
	CGFloat radius = 10.0f;
	if (radius > rBounds.size.width/2.0f)
		radius = rBounds.size.width/2.0f;
	if (radius > rBounds.size.height/2.0f)
		radius = rBounds.size.height/2.0f;    
	
	CGFloat minx = CGRectGetMinX(r);// + 0.5;
	CGFloat midx = CGRectGetMidX(r);
	CGFloat maxx = CGRectGetMaxX(r);// - 0.5;
	CGFloat miny = CGRectGetMinY(r);// + 0.5;
	CGFloat midy = CGRectGetMidY(r);
	CGFloat maxy = CGRectGetMaxY(r);// - 0.5;
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
	
	CGContextSaveGState(context);
	[[UIColor blackColor] set];
	CGContextClip(context);	
	
	
	CGGradientRef myGradient;
	CGColorSpaceRef myColorspace;
	size_t num_locations = 3;
	CGFloat locations[3] = {0.0f, 0.5f, 1.0f};
	CGFloat startGray = 0.12f;
	CGFloat middleGray = 0.05f;
	CGFloat endGray = 0.0f;
	CGFloat components[12] = {startGray, startGray, startGray, 0.9f, middleGray, middleGray, middleGray, 0.9f, endGray, endGray, endGray, 0.9f};
	
	myColorspace = CGColorSpaceCreateDeviceRGB();
	myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	CGPoint myStartPoint, myEndPoint;
	myStartPoint.x = 0.0f;
	myStartPoint.y = 0.0f;
	myEndPoint.x = 0.0f;
	myEndPoint.y = CGRectGetMaxY(r);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), myGradient, myStartPoint, myEndPoint, 0);
	CGColorSpaceRelease(myColorspace);
	CGGradientRelease(myGradient);
	
	CGContextRestoreGState(context);
	
	[[UIColor colorWithWhite:1.0f alpha:1.0f] set];
	CGContextSetLineWidth(context, 1);
	[[UIColor blackColor] set];
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	CGContextClosePath(context);
	CGContextStrokePath(context);
	
	CGContextRestoreGState(context);
	
	if (RSStringIsEmpty(self.message) || !CGRectIntersectsRect(frame, self.messageRect))
		goto drawRect_exit;
	static UIFont *messageFont = nil;
	if (!messageFont)
		messageFont = [[UIFont boldSystemFontOfSize:kHUDMessageFontSize] retain];
	CGContextSaveGState(context);
	CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, 1), 1.0f, [[UIColor colorWithWhite:0.0f alpha:0.6f] CGColor]);
	[[UIColor whiteColor] set];
	[self.message drawInRect:self.messageRect withFont:messageFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
	CGContextRestoreGState(context);
	
drawRect_exit:
	CGContextRelease(context);
}

@end


@interface RSFeedbackHUDViewController()

@property (nonatomic, retain) NSString *message;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) BOOL useActivityIndicator;
@property (nonatomic, retain) UIWindow *window;

- (void)displayHUD;
- (void)_invalidateTimer;
- (void)tile;
- (void)closeWindow;

@end


@implementation RSFeedbackHUDViewController

@synthesize message = _message, duration = _duration, useActivityIndicator = _useActivityIndicator;
@synthesize window;


#pragma mark Class Methods

static RSFeedbackHUDViewController *gHudController = nil;

+ (RSFeedbackHUDViewController *)displayWithMessage:(NSString *)message duration:(NSTimeInterval)duration useActivityIndicator:(BOOL)useActivityIndicator window:(UIWindow *)aWindow {
	if (!gHudController)
		gHudController = [[RSFeedbackHUDViewController alloc] initWithNibName:nil bundle:nil];
	gHudController.message = message;
	gHudController.duration = duration;
	gHudController.useActivityIndicator = useActivityIndicator;
	gHudController.window = aWindow;
	(void)(gHudController.view); /*Force load, then call on main thread -- otherwise interfaceOrientation is wrong*/
	[gHudController performSelectorOnMainThread:@selector(displayHUD) withObject:nil waitUntilDone:NO];
	return gHudController;
}


+ (void)closeWindow {
	if (gHudController)
		[gHudController closeWindow];
}


#pragma mark Init

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle {
	self = [super initWithNibName:nibName bundle:bundle];
	if (self) {
		//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleWillChangeInterfaceOrientation:) name:UIApplicationWillChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleDidChangeInterfaceOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:[UIApplication sharedApplication]];
	}
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_message release];
	[self _invalidateTimer];
	[window release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)loadView {
	self.view = [[[BCHUDView alloc] initWithFrame:CGRectZero] autorelease];
}


- (void)_handleDidChangeInterfaceOrientation:(NSNotification *)note {
	[self tile];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
	//	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark Display/Animate

static const CGFloat pi_float = 3.14159265358979323846264338327950288f;

- (CGAffineTransform)_transformForOrientation:(UIInterfaceOrientation)orientation {
	if (orientation == UIInterfaceOrientationPortrait)
		return CGAffineTransformIdentity;
	if (orientation == UIInterfaceOrientationPortraitUpsideDown)
		return CGAffineTransformRotate(self.view.transform, (0.0f - pi_float));
    if (orientation == UIInterfaceOrientationLandscapeLeft)
		return CGAffineTransformRotate(self.view.transform, 3.0f * (pi_float / 2.0f));
    return CGAffineTransformRotate(self.view.transform, (pi_float / 2.0f)); /*UIInterfaceOrientationLandscapeRight*/
}


- (void)tile {
	UIInterfaceOrientation orientation = [UIDevice currentDevice].orientation;
	if (orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown)
		orientation = self.interfaceOrientation;
	static UIFont *messageFont = nil;
	if (!messageFont)
		messageFont = [[UIFont boldSystemFontOfSize:kHUDMessageFontSize] retain];
	CGSize messageSize = [self.message sizeWithFont:messageFont constrainedToSize:CGSizeMake(kHUDMessageWidth, kHUDMessageHeight) lineBreakMode:UILineBreakModeTailTruncation];
	CGSize viewSize = CGSizeMake(messageSize.width + (2 * kHUDMargin), messageSize.height + (2 * kHUDMargin));
	if (_useActivityIndicator)
		viewSize.height += 60;
	CGRect appFrame = [UIScreen mainScreen].applicationFrame;
	self.view.bounds = CGRectIntegral(CGRectMake(0, 0, viewSize.width, viewSize.height));
	self.view.transform = CGAffineTransformIdentity;
	self.view.transform = [self _transformForOrientation:orientation];
	self.view.center = CGPointMake(appFrame.size.width / 2.0f, appFrame.size.height / 2.0f);
	((BCHUDView *)(self.view)).messageRect = CGRectIntegral(CGRectMake(kHUDMargin, kHUDMargin, messageSize.width, messageSize.height));
	((BCHUDView *)(self.view)).message = self.message;
	if (_useActivityIndicator)
		[(BCHUDView *)(self.view) addActivityIndicatorIfNeeded];		
	[self.view setNeedsDisplay];
}


- (void)displayHUD {
	/*Resize view with message. Center in window; add to window. Set alpha to 1. Show for KHUDDisplayBeforeFadingDuration seconds. Animate it to 0 for duration - KHUDDisplayBeforeFadingDuration seconds. When animation is over, remove from window.*/
	(void)(self.view); /*Need to load it first, else interfaceOrientation returns wrong answer*/
	self.view.hidden = NO;
	[self.window addSubview:self.view];
	[self _invalidateTimer];
	[self tile];
	self.view.alpha = 1.0f;
	[self.window bringSubviewToFront:self.view];
	if (self.duration > 0.1)
		_timer = [[NSTimer scheduledTimerWithTimeInterval:KHUDDisplayBeforeFadingDuration target:self selector:@selector(_timerDidFire:) userInfo:nil repeats:NO] retain];
}


- (void)closeWindow {
	[self _invalidateTimer];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDelegate:self]; 
	[UIView setAnimationDidStopSelector:@selector(_animationDidComplete:finished:context:)];
	self.view.alpha = 0.0f;
	[UIView commitAnimations];
	[self performSelectorOnMainThread:@selector(_invalidateTimer) withObject:nil waitUntilDone:NO];
}


- (void)_invalidateTimer {
	[_timer rs_invalidateIfValid];
	[_timer release];
	_timer = nil;
}


- (void)_timerDidFire:(NSTimer *)timer {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:self.duration - KHUDDisplayBeforeFadingDuration];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDelegate:self]; 
	[UIView setAnimationDidStopSelector:@selector(_animationDidComplete:finished:context:)];
	self.view.alpha = 0.0f;
	[UIView commitAnimations];
	[self performSelectorOnMainThread:@selector(_invalidateTimer) withObject:nil waitUntilDone:NO];
}


- (void)_animationDidComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	[(BCHUDView *)(self.view) removeActivityIndicatorIfNeeded];
	[self.view removeFromSuperview];
	self.view.hidden = YES;
}


@end
