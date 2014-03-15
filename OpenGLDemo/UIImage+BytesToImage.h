//
//  UIImage+BytesToImage.h
//  OpenGLDemo
//
//  Created by Allen Wu on 3/13/14.
//  Copyright (c) 2014 Originate. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (BytesToImage)

+ (UIImage*)imageFromBytes:(void*)bytes
                bufferSize:(int)bufferSize
                     width:(int)width
                    height:(int)height;

@end
