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
@property (nonatomic, strong) UIButton* button;
@end

@implementation GLViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  self.button = [[UIButton alloc] initWithFrame:CGRectMake(85, [UIScreen mainScreen].bounds.size.height - 60, 150, 40)];
  [self.button setTitle:@"glReadPixels();" forState:UIControlStateNormal];
  [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [self.button setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
  [self.button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
  [self.button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.button.layer setCornerRadius:8.0];
  [self.button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  self.view = [[GLView alloc] init];
  [self.view addSubview:self.button];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)buttonPressed {
  NSLog(@"[%@]", NSStringFromSelector(_cmd));
  
  [(GLView*)self.view captureFrame];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
