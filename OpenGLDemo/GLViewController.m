//
//  MainViewController.m
//  OpenGLDemo
//
//  Created by Allen Wu on 3/12/14.
//  Copyright (c) 2014 Originate. All rights reserved.
//

#import "GLViewController.h"
#import "GLView.h"


@interface GLViewController ()
@property (nonatomic, strong) UIButton* captureButton;
@property (nonatomic, strong) UIButton* colorButton;
@end

@implementation GLViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // create buttons
  self.captureButton = [[UIButton alloc] initWithFrame:CGRectMake(15, [UIScreen mainScreen].bounds.size.height - 80, 130, 40)];
  [self.captureButton setTitle:@"glReadPixels();" forState:UIControlStateNormal];
  [self.captureButton addTarget:self action:@selector(captureButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  self.colorButton = [[UIButton alloc] initWithFrame:CGRectMake(175, [UIScreen mainScreen].bounds.size.height - 80, 130, 40)];
  [self.colorButton setTitle:@"Random Color" forState:UIControlStateNormal];
  [self.colorButton addTarget:self action:@selector(colorButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  for (UIButton* button in @[self.captureButton, self.colorButton]) {
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button.layer setCornerRadius:8.0];
  }

  self.view = [[GLView alloc] init];
  [self.view addSubview:self.captureButton];
  [self.view addSubview:self.colorButton];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)captureButtonPressed {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [(GLView*)self.view captureFrame];
}

- (void)colorButtonPressed {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  CGFloat red   = drand48();
  CGFloat blue  = drand48();
  CGFloat green = drand48();
  UIColor* randomColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
  
  [(GLView*)self.view setBackgroundColor:randomColor];
  [(GLView*)self.view drawViewAndPresent];
  
  [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"#%02x%02x%02x", (int)(255 * red), (int)(255 * green), (int)(255 * blue)]
                              message:@"Redrew OpenGL context with random background color"
                             delegate:nil
                    cancelButtonTitle:@"Ok"
                    otherButtonTitles:nil] show];
}


@end
