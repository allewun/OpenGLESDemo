//
//  GLView.h
//  OpenGLDemo
//
//  Created by Allen Wu on 3/12/14.
//  Copyright (c) 2014 Originate. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface GLView : UIView

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic) GLuint framebuffer;
@property (nonatomic) GLuint renderbuffer;
@property (nonatomic) GLint backingWidth;
@property (nonatomic) GLint backingHeight;

@property (nonatomic, strong) UIColor* backgroundColor;

- (void)captureFrame;
- (void)drawView;
- (void)drawViewAndPresent;

@end
