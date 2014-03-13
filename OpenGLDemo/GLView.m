//
//  GLView.m
//  OpenGLDemo
//
//  Created by Allen Wu on 3/12/14.
//  Copyright (c) 2014 Originate. All rights reserved.
//

#import "GLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

// swtich between context backing-types (layer vs. data)
#define BACKING_TYPE_LAYERBACKED 1

@implementation GLView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
      
      eaglLayer.opaque = YES;
      eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO,
                                       kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
      
      self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
      
      if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
        return nil;
      }
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (BOOL)createBuffers{
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  // generate buffers
  glGenFramebuffersOES(1, &_framebuffer);
  glGenRenderbuffersOES(1, &_renderbuffer);
  
  // bind buffers
  glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
  
  // attach renderbuffer to framebuffer
  glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _renderbuffer);
  
  // specify buffer backing (layer or data)
#if BACKING_TYPE_LAYERBACKED
  
  [self.context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
  glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
  glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);
  
  NSLog(@"   * layer-backed: {w = %i, h = %i}", _backingWidth, _backingHeight);
  
#else
  
  NSLog(@"   * data-backed");
  
  [self.context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:nil];
  glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_RGBA8_OES, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
  
#endif


  // check for errors
  if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
    NSAssert(NO, @"Framebuffer status != GL_FRAMEBUFFER_COMPLETE_OES");
    return NO;
  }
  
  return YES;
}

- (void)destroyBuffers {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  glDeleteFramebuffersOES(1, &_framebuffer);
  _framebuffer = 0;
  glDeleteRenderbuffersOES(1, &_renderbuffer);
  _renderbuffer = 0;
}

- (void)layoutSubviews {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [EAGLContext setCurrentContext:self.context];
  [self destroyBuffers];
  [self createBuffers];
  [self drawView];
}

- (void)drawView {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
  
  glClearColor(1.0, 0, 0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

@end
