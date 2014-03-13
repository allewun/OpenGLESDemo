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
#import <AVFoundation/AVFoundation.h>

// swtich between context backing-types (layer vs. data)
#define BACKING_TYPE_LAYERBACKED 1

// switch between OpenGL ES v1.1 and v2.0
#define OPENGLES_VERSION_1 0


typedef struct {
  float Position[3];
  float Color[4];
} Vertex;

const Vertex Vertices[] = {
  {{1, -1, 0}, {1, 0, 0, 1}},
  {{1, 1, 0}, {0, 1, 0, 1}},
  {{-1, 1, 0}, {0, 0, 1, 1}},
  {{-1, -1, 0}, {0, 0, 0, 1}}
};

const GLubyte Indices[] = {
  0, 1, 2,
  2, 3, 0
};

@interface GLView ()

@property GLuint positionSlot;
@property GLuint colorSlot;

@end

@implementation GLView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    
#if OPENGLES_VERSION_1
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO,
                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
      return nil;
    }
    
#else
    
    CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO,
                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context || ![EAGLContext setCurrentContext:self.context]) {
      return nil;
    }
    
    [self compileShaders];
    [self setupVBOs];
    
#endif
    
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
  [self drawView];
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

- (void)drawView {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
  
  [self drawOpenGL];
  
  [self.context presentRenderbuffer:GL_RENDERBUFFER_OES];
}


- (void)drawOpenGL {
  
#if OPENGLES_VERSION_1
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
	
  // define triangle vertices
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
  
#else
  
  glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);
  
  // 1
  glViewport(0, 0, self.frame.size.width, self.frame.size.height);
  
  // 2
  glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                        sizeof(Vertex), 0);
  glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                        sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
  
  // 3
  glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
                 GL_UNSIGNED_BYTE, 0);
#endif
}


#pragma mark - OpenGL capture frame

- (void)captureFrame {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  int bytesPerPixel = 4;
  int bufferSize = _backingWidth * _backingHeight * bytesPerPixel;
  void* pixelBuffer = malloc(bufferSize);
  
  
  glReadPixels(0, 0, _backingWidth, _backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);
  
  UIImage* image = [UIImage imageFromBytes:pixelBuffer bufferSize:bufferSize width:_backingWidth height:_backingHeight];
  
  free(pixelBuffer);
}

- (void)compileShaders {
  
  // 1
  GLuint vertexShader = [self compileShader:@"Vertex"
                                   withType:GL_VERTEX_SHADER];
  GLuint fragmentShader = [self compileShader:@"Fragment"
                                     withType:GL_FRAGMENT_SHADER];
  
  // 2
  GLuint programHandle = glCreateProgram();
  glAttachShader(programHandle, vertexShader);
  glAttachShader(programHandle, fragmentShader);
  glLinkProgram(programHandle);
  
  // 3
  GLint linkSuccess;
  glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
  if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"%@", messageString);
    exit(1);
  }
  
  // 4
  glUseProgram(programHandle);
  
  // 5
  _positionSlot = glGetAttribLocation(programHandle, "Position");
  _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
  glEnableVertexAttribArray(_positionSlot);
  glEnableVertexAttribArray(_colorSlot);
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
  
  // 1
  NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                         ofType:@"glsl"];
  NSError* error;
  NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                     encoding:NSUTF8StringEncoding error:&error];
  if (!shaderString) {
    NSLog(@"Error loading shader: %@", error.localizedDescription);
    exit(1);
  }
  
  // 2
  GLuint shaderHandle = glCreateShader(shaderType);
  
  // 3
  const char * shaderStringUTF8 = [shaderString UTF8String];
  int shaderStringLength = [shaderString length];
  glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
  
  // 4
  glCompileShader(shaderHandle);
  
  // 5
  GLint compileSuccess;
  glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
  if (compileSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"%@", messageString);
    exit(1);
  }
  
  return shaderHandle;
  
}

- (void)setupVBOs {
  
  GLuint vertexBuffer;
  glGenBuffers(1, &vertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
  
  GLuint indexBuffer;
  glGenBuffers(1, &indexBuffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
  
}

@end
