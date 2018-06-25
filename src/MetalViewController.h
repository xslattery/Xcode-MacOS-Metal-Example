//
//  ViewController.h
//  metal-storyboards
//
//  Created by Xavier Slattery on 23/6/18.
//  Copyright © 2018 Xavier Slattery. All rights reserved.
//

#pragma once

#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MetalView : MTKView

@end

@interface MetalViewController : NSViewController<MTKViewDelegate>

@end
