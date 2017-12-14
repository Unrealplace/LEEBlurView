//
//  ViewController.m
//  TestBlurView
//
//  Created by LiYang on 2017/12/13.
//  Copyright © 2017年 LiYang. All rights reserved.
//

#import "ViewController.h"
#import "ACBlurImageView.h"

@interface ViewController ()
@property (strong, nonatomic)  UIImageView *backImageView;
@property (nonatomic, strong) ACBlurImageView    *blurView;
@property (nonatomic, strong)UISlider   * slider;
@property (nonatomic, strong)UIView    * animationView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.backImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.backImageView];
    self.backImageView.image = [UIImage imageNamed:@"cat1.png"];
    
    self.animationView = [[UIView alloc] initWithFrame:CGRectMake(10, 400, 40, 40)];
    self.animationView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.animationView];
    
    self.blurView = [[ACBlurImageView alloc] initWithFrame:self.view.bounds];
    self.blurView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.blurView];
    
    
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 30, 300, 40)];
    [self.slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.slider];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.blurView snapshotOfUnderlyingView];
}
- (void)sliderValueChange:(UISlider*)slider{
    
    self.blurView.blurRate = slider.value * 60;
    self.animationView.frame = CGRectMake(10, 400, self.view.bounds.size.width * slider.value, self.view.bounds.size.height * slider.value);
    if (slider.value <= 0) {
        self.blurView.hidden = YES;
        self.animationView.frame = CGRectMake(10, 400, 40, 40);
    }else {
        self.blurView.hidden = NO;
        
    }
    
}




@end

