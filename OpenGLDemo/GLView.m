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
#import "UIImage+BytesToImage.h"

// swtich between context backing-types
 // 0 = data-backed, 1 = layer-backed
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
      
      self.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    }
    return self;
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)layoutSubviews {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [EAGLContext setCurrentContext:self.context];
  [self destroyBuffers];
  [self createBuffers];
  [self drawViewAndPresent];
}

#pragma mark - OpenGL methods (buffer setup)

- (BOOL)createBuffers {
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
  
    _backingWidth  = [UIScreen mainScreen].bounds.size.width;
    _backingHeight = [UIScreen mainScreen].bounds.size.height;
  
    [self.context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:nil];
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_RGBA8_OES, _backingWidth, _backingHeight);
  
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


#pragma mark - OpenGL methods (drawing)

- (void)bindBuffers {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
}

- (void)drawView {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [self bindBuffers];
  [self drawOpenGL];
}

- (void)drawViewAndPresent {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [self drawView];
  
  #if BACKING_TYPE_LAYERBACKED
    [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
  #endif
}

- (void)drawOpenGL {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  // if no color, default to gray
  CGFloat red   = 0.5;
  CGFloat green = 0.5;
  CGFloat blue  = 0.5;
  CGFloat alpha = 1.0;
  
  [self.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
  
  // clear opengl stuff
  glLoadIdentity();
  
  // background color
  glClearColor(red, green, blue, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
}


#pragma mark - OpenGL capture frame

- (void)captureFrame {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [self drawView];
  
  int bytesPerPixel = 4;
  int bufferSize = _backingWidth * _backingHeight * bytesPerPixel;
  void* pixelBuffer = malloc(bufferSize);

  glReadPixels(0, 0, _backingWidth, _backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);
  
  UIImage* image = [UIImage imageFromBytes:pixelBuffer bufferSize:bufferSize width:_backingWidth height:_backingHeight];
  
  // print to console and UIAlertView
  [self debugCapture:pixelBuffer];

  free(pixelBuffer);
}

#pragma mark - Misc

- (void)debugCapture:(void*)bytes {
  NSMutableString* memoryString = [NSMutableString string];
  
  // print first 5 pixels (20 bytes)
  NSLog(@"glReadPixels() -- first 5 pixels (20 bytes)");
  for (int i = 0; i < 5; i++) {
    printf("[ ");
    [memoryString appendString:@"[ "];
    
    for (int j = 0; j < 4; j++) {
      GLubyte byte = *((GLubyte*)bytes + (i*4) + j);
      printf("%x ", byte);
      [memoryString appendString:[NSString stringWithFormat:@"%x ", byte]];
    }
    
    printf("]\n");
    [memoryString appendString:@"]\n"];
  }
  
  [[[UIAlertView alloc] initWithTitle:@"First 20 bytes"
                              message:memoryString
                             delegate:nil
                    cancelButtonTitle:@"Ok"
                    otherButtonTitles:nil] show];
}

@end
