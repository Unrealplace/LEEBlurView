//
//  ACBlurImageView.h
//  TestBlurView
//
//  Created by LiYang on 2017/12/13.
//  Copyright © 2017年 LiYang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>


#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#import <Availability.h>
#undef weak_ref
#if __has_feature(objc_arc) && __has_feature(objc_arc_weak)
#define weak_ref weak
#else
#define weak_ref unsafe_unretained
#endif


@interface UIImage (FXBlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;

@end
@interface ACBlurImageView : UIView

@property (nonatomic, strong) UIView    *underView;
@property (nonatomic, assign) CGFloat    blurRate;
@property (nonatomic, strong) UIImage   *blurImage;

- (UIImage *)snapshotOfUnderlyingView;


@end
#pragma GCC diagnostic pop
