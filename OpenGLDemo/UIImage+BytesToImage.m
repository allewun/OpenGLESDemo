//
//  UIImage+BytesToImage.m
//  OpenGLDemo
//
//  Created by Allen Wu on 3/13/14.
//  Copyright (c) 2014 Originate. All rights reserved.
//

#import "UIImage+BytesToImage.h"

@implementation UIImage (BytesToImage)

// http://stackoverflow.com/q/17674409

+ (UIImage*)imageFromBytes:(void*)bytes
                bufferSize:(int)bufferSize
                     width:(int)width
                    height:(int)height {
  
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bytes, bufferSize, NULL);
  size_t bitsPerComponent = 8;
  size_t bitsPerPixel = 32;
  size_t bytesPerRow = 4 * width;
  
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  if (colorSpaceRef == NULL) {
    NSLog(@"Error allocating color space");
    CGDataProviderRelease(provider);
    return nil;
  }
  
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
  CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
  
  CGImageRef iref = CGImageCreate(width,
                                  height,
                                  bitsPerComponent,
                                  bitsPerPixel,
                                  bytesPerRow,
                                  colorSpaceRef,
                                  bitmapInfo,
                                  provider,   // data provider
                                  NULL,       // decode
                                  YES,        // should interpolate
                                  renderingIntent);
  
  uint32_t* pixels = (uint32_t*)malloc(bufferSize);
  
  if (pixels == NULL) {
    NSLog(@"Error: Memory not allocated for bitmap");
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    return nil;
  }
  
  CGContextRef context = CGBitmapContextCreate(pixels,
                                               width,
                                               height,
                                               bitsPerComponent,
                                               bytesPerRow,
                                               colorSpaceRef,
                                               bitmapInfo);
  
  if (context == NULL) {
    NSLog(@"Error context not created");
    free(pixels);
    return nil;
  }
  
  UIImage *image = nil;
  
  if (context) {
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
    if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
      float scale = [[UIScreen mainScreen] scale];
      image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    }
    else {
      image = [UIImage imageWithCGImage:imageRef];
    }
    
    CGImageRelease(imageRef);
    CGContextRelease(context);
  }
  
  CGColorSpaceRelease(colorSpaceRef);
  CGImageRelease(iref);
  CGDataProviderRelease(provider);
  
  if (pixels) {
    free(pixels);
  }
  
  return image;
}

@end
