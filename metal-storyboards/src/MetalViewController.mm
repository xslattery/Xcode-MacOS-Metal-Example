//
//  ViewController.m
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#import "MetalViewController.h"
#import "Renderer.h"
#import "Scene.h"

@implementation MetalView

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

- (void)awakeFromNib {
	// Create a tracking area to keep track of the mouse movements and events:
	// NOTE(Xavier): This is required for mouseEntered/Exited to work.
	NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
	[self addTrackingArea:area];
}

@end

/////////////////////////////

@implementation MetalViewController {
	MTKView *_view;
	Renderer *_renderer;
	Scene *_scene;
}

// Setup:
- (void)viewDidLoad {
	[super viewDidLoad];
	_view = (MTKView *)self.view;
	_view.delegate = self;
	
	_view.device = MTLCreateSystemDefaultDevice();
	assert(_view.device);
	NSLog(@"GPU: %@", [_view.device name]);
	
	_view.preferredFramesPerSecond = 30;
	_view.framebufferOnly = NO;
	_view.sampleCount = 1;
	_view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
	_view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
	
	// NOTE(Xavier): To have a fixed drawable resolution that will scale with the view,
	// set the following to prevent auto rezise and choose the desired size.
	// _view.autoResizeDrawable = false;
	// _view.drawableSize = {240, 150};
	
	_scene = [[Scene alloc] initWithDevice:_view.device size:_view.drawableSize];
	_renderer = [[Renderer alloc] initWithDevice:_view.device size:_view.drawableSize];
}

// Input:
-(void)flagsChanged:(NSEvent*)event {}
-(void)keyUp:(NSEvent*)event {}
-(void)keyDown:(NSEvent*)event{}
-(void)mouseDown:(NSEvent *)event {}
-(void)mouseUp:(NSEvent *)event {}
-(void)rightMouseDown:(NSEvent *)event {}
-(void)rightMouseUp:(NSEvent *)event {}
-(void)mouseMoved:(NSEvent *)event {}
-(void)mouseDragged:(NSEvent *)event {}
-(void)rightMouseDragged:(NSEvent *)event {}
-(void)mouseExited:(NSEvent *)event {}
-(void)mouseEntered:(NSEvent *)event {}

// Resize:
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
	assert(_view = view);
	[_renderer resize:size];
	[_scene resize:size];
}

// Draw:
- (void)drawInMTKView:(nonnull MTKView *)view {
	// NOTE(Xavier): Documentation (https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html#//apple_ref/doc/uid/TP40016642-CH2-SW1)
	// recomends using an autorelease pool around the currentDrawable to
	// avoid possible deadlock situations with multiple drawables.
	@autoreleasepool {
		id<MTLDrawable> drawable = _view.currentDrawable;
		MTLRenderPassDescriptor *renderPassDescriptor = _view.currentRenderPassDescriptor;
		if (drawable != nil && renderPassDescriptor != nil) {
			[_renderer renderScene: _scene
					  withDrawable: drawable
			  renderPassDescriptor: renderPassDescriptor];
		}
	}
}

@end
