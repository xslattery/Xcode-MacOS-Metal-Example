//
//  ViewController.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "MetalViewController.h"
#import "Renderer.h"

@implementation MetalView

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

- (void)awakeFromNib {
	// Create a tracking area to keep track of the mouse movements and events:
	NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:area];
}

@end

/////////////////////////////

@implementation MetalViewController {
	MTKView *_view;
	Renderer *_renderer;
}

// Setup:
- (void)viewDidLoad {
	[super viewDidLoad];
	_view = (MTKView *)self.view;
	_view.delegate = self;
	
	_view.device = MTLCreateSystemDefaultDevice();
	assert(_view.device);
	NSLog(@"GPU: %@", [_view.device name]);
	
	_view.framebufferOnly = NO;
	_view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
	_view.sampleCount = 1;
	_view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
	_view.preferredFramesPerSecond = 60;
	
	_renderer = [[Renderer alloc] initWithDevice:_view.device size:_view.drawableSize];
}

// Input:
-(void)flagsChanged:(NSEvent*)event {}
-(void)mouseExited:(NSEvent *)event {}
-(void)rightMouseDown:(NSEvent *)event {}
-(void)rightMouseUp:(NSEvent *)event {}
-(void)mouseDown:(NSEvent *)event {}
-(void)mouseUp:(NSEvent *)event {}
-(void)mouseMoved:(NSEvent *)event {}
-(void)mouseDragged:(NSEvent *)event {}
-(void)rightMouseDragged:(NSEvent *)event {}
-(void)keyUp:(NSEvent*)event {}
-(void)keyDown:(NSEvent*)event{}

// Resize:
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
	assert(_view = view);
	[_renderer resize:size];
}

// Draw:
- (void)drawInMTKView:(nonnull MTKView *)view {
	@autoreleasepool {
		id<MTLDrawable> drawable = _view.currentDrawable;
		MTLRenderPassDescriptor *renderPassDescriptor = _view.currentRenderPassDescriptor;
		if (drawable != nil && renderPassDescriptor != nil) {
			[_renderer renderWithDrawable: drawable
					 renderPassDescriptor: renderPassDescriptor];
		}
	}
}

@end
