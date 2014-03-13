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
#define BACKING_TYPE_LAYERBACKED 0

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
  
  [self drawOpenGL];
  
  [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}



- (void)drawOpenGL {
  const GLfloat zNear = 0.01,
                zFar = 1000.0,
                fieldOfView = 45.0;
  
  // setup camera
	glEnable(GL_DEPTH_TEST);
	glMatrixMode(GL_PROJECTION);
  GLfloat size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0);
	CGRect rect = self.bounds;
	glFrustumf(-size, size, -size / (rect.size.width / rect.size.height), size /
             (rect.size.width / rect.size.height), zNear, zFar);
	glViewport(0, 0, rect.size.width, rect.size.height);
	glMatrixMode(GL_MODELVIEW);
	
  
  Vertex3D   vertex1  = Vertex3DMake( 0.0,  1.0, -3.0);
  Vertex3D   vertex2  = Vertex3DMake( 1.0,  0.0, -3.0);
  Vertex3D   vertex3  = Vertex3DMake(-1.0,  0.0, -3.0);
  Triangle3D triangle = Triangle3DMake(vertex1, vertex2, vertex3);
  
  // clear opengl stuff
  glLoadIdentity();
  
  // background color
  glClearColor(0.5, 0.5, 0.5, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  glEnableClientState(GL_VERTEX_ARRAY);
  
  // red color
  glColor4f(1.0, 0.0, 0.0, 1.0);
  
  glVertexPointer(3, GL_FLOAT, 0, &triangle);
  glDrawArrays(GL_TRIANGLES, 0, 9);
  
  glDisableClientState(GL_VERTEX_ARRAY);
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)captureFrame {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  int bufferSize = _backingWidth * _backingHeight * 4;
  void* pixelBuffer = malloc(bufferSize);

  glReadPixels(0, 0, _backingWidth, _backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);
  
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixelBuffer, bufferSize, NULL);
  size_t bitsPerComponent = 8;
  size_t bitsPerPixel = 32;
  size_t bytesPerRow = 4 * _backingWidth;
  
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  if(colorSpaceRef == NULL) {
    NSLog(@"Error allocating color space");
    CGDataProviderRelease(provider);
    return;
  }
  
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
  CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
  
  CGImageRef iref = CGImageCreate(_backingWidth,
                                  _backingHeight,
                                  bitsPerComponent,
                                  bitsPerPixel,
                                  bytesPerRow,
                                  colorSpaceRef,
                                  bitmapInfo,
                                  provider,   // data provider
                                  NULL,       // decode
                                  YES,            // should interpolate
                                  renderingIntent);
  
  uint32_t* pixels = (uint32_t*)malloc(bufferSize);
  
  if(pixels == NULL) {
    NSLog(@"Error: Memory not allocated for bitmap");
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    return;
  }
  
  CGContextRef context = CGBitmapContextCreate(pixels,
                                               _backingWidth,
                                               _backingHeight,
                                               bitsPerComponent,
                                               bytesPerRow,
                                               colorSpaceRef,
                                               bitmapInfo);
  
  if(context == NULL) {
    NSLog(@"Error context not created");
    free(pixels);
  }
  
  UIImage *image = nil;
  if(context) {
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, _backingWidth, _backingHeight), iref);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
    if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
      float scale = [[UIScreen mainScreen] scale];
      image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    } else {
      image = [UIImage imageWithCGImage:imageRef];
    }
    
    CGImageRelease(imageRef);
    CGContextRelease(context);
  }
  
  CGColorSpaceRelease(colorSpaceRef);
  CGImageRelease(iref);
  CGDataProviderRelease(provider);
  
  if(pixels) {
    free(pixels);
  }

  
  free(pixelBuffer);
}

@end
