//
//  ACBlurImageView.m
//  TestBlurView
//
//  Created by LiYang on 2017/12/13.
//  Copyright © 2017年 LiYang. All rights reserved.
//

#import "ACBlurImageView.h"
#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif
@implementation UIImage (ACBlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor{
    //image must be nonzero size
    if (floorf(self.size.width) * floorf(self.size.height) <= 0.0f) return self;
    
    //boxsize must be an odd integer
    uint32_t boxSize = (uint32_t)(radius * self.scale);
    if (boxSize % 2 == 0) boxSize ++;
    
    //create image buffers
    CGImageRef imageRef = self.CGImage;
    
    //convert to ARGB if it isn't
    if (CGImageGetBitsPerPixel(imageRef) != 32 ||
        CGImageGetBitsPerComponent(imageRef) != 8 ||
        !((CGImageGetBitmapInfo(imageRef) & kCGBitmapAlphaInfoMask)))
    {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
        [self drawAtPoint:CGPointZero];
        imageRef = UIGraphicsGetImageFromCurrentImageContext().CGImage;
        UIGraphicsEndImageContext();
    }
    
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    size_t bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);
    
    if (NULL == buffer1.data || NULL == buffer2.data)
    {
        free(buffer1.data);
        free(buffer2.data);
        return self;
    }
    
    //create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                                 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    CFDataRef dataSource = CGDataProviderCopyData(provider);
    if (NULL == dataSource)
    {
        return self;
    }
    const UInt8 *dataSourceData = CFDataGetBytePtr(dataSource);
    CFIndex dataSourceLength = CFDataGetLength(dataSource);
    memcpy(buffer1.data, dataSourceData, MIN(bytes, dataSourceLength));
    CFRelease(dataSource);
    
    for (NSUInteger i = 0; i < iterations; i++)
    {
        //perform blur
        vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
        
        //swap buffers
        void *temp = buffer1.data;
        buffer1.data = buffer2.data;
        buffer2.data = temp;
    }
    
    //free buffers
    free(buffer2.data);
    free(tempBuffer);
    
    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    //apply tint
    if (tintColor && CGColorGetAlpha(tintColor.CGColor) > 0.0f)
    {
        CGContextSetFillColorWithColor(ctx, [tintColor colorWithAlphaComponent:0.25].CGColor);
        CGContextSetBlendMode(ctx, kCGBlendModePlusLighter);
        CGContextFillRect(ctx, CGRectMake(0, 0, buffer1.width, buffer1.height));
    }
    
    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return image;
}

@end

@implementation ACBlurImageView

- (void)setLayerContents:(UIImage*)image {
    self.layer.contents = (id)image.CGImage;
    self.layer.contentsScale = image.scale;
}
- (UIView*)underView {
    return _underView ? :self.superview;
}
- (CALayer*)underLayer {
    return self.underView.layer;
}
- (void)setBlurRate:(CGFloat)blurRate {
    _blurRate = blurRate;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIImage * newSnapShot = [self.blurImage blurredImageWithRadius:_blurRate iterations:2 tintColor:[UIColor clearColor]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setLayerContents:newSnapShot];
        });
    });
}
- (UIImage *)snapshotOfUnderlyingView {
    __strong CALayer * curentLayer = self.layer;
    __strong CALayer * underLayer  = [self underLayer];
    CGRect bounds = [curentLayer convertRect:curentLayer.bounds toLayer:underLayer];
    CGFloat scale = 1;
    CGSize size = bounds.size;
    if (self.contentMode == UIViewContentModeScaleToFill ||
        self.contentMode == UIViewContentModeScaleAspectFill ||
        self.contentMode == UIViewContentModeScaleAspectFit ||
        self.contentMode == UIViewContentModeRedraw)    {
        size.width = floor(size.width * scale) / scale;
        size.height = floor(size.height * scale) / scale;
    }else if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0 && [UIScreen mainScreen].scale == 1.0){
        scale = 1.0;
    }
    scale = 1;
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context){
        CGContextTranslateCTM(context, -bounds.origin.x, -bounds.origin.y);
        NSArray *hiddenViews = [self prepareUnderlyingViewForSnapshot]; // 先隐藏
        __strong UIView *underlyingView = self.underView;
        //原因是afterScreenUpdates设置为了YES.为什么会崩溃呢?因为设置为YES后,
        //这些方法会等在view update结束在执行,如果在update结束前view被release了,会出现找不到view的问题.所以需要设置为NO.
        if ([underlyingView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [underlyingView drawViewHierarchyInRect:underlyingView.bounds afterScreenUpdates:YES];
        }else{//兼容iOS 7
            [[self underLayer] renderInContext:UIGraphicsGetCurrentContext()];
        }
        [self restoreSuperviewAfterSnapshot:hiddenViews];// 显示图层
    
        UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
        self.blurImage = snapshot;
        UIGraphicsEndImageContext();
      
        return snapshot;
    }
    return nil;
}

- (NSArray *)prepareUnderlyingViewForSnapshot
{
    __strong CALayer *blurlayer       = self.layer;
    __strong CALayer *underlyingLayer = [self underLayer];
    while (blurlayer.superlayer && blurlayer.superlayer != underlyingLayer){
        blurlayer = blurlayer.superlayer;
    }
    NSMutableArray *layers = [NSMutableArray array];
    NSUInteger index = [underlyingLayer.sublayers indexOfObject:blurlayer];
    if (index != NSNotFound){
        for (NSUInteger i = index; i < [underlyingLayer.sublayers count]; i++){
            CALayer *layer = underlyingLayer.sublayers[i];
            if (!layer.hidden){
                layer.hidden = YES;
                [layers addObject:layer];
            }
        }
    }
    //also hide any sublayers with empty bounds to prevent a crash on iOS 8
    [layers addObjectsFromArray:[self hideEmptyLayers:underlyingLayer]];
    return layers;
}
- (NSArray *)hideEmptyLayers:(CALayer *)layer{
    NSMutableArray *layers = [NSMutableArray array];
    if (CGRectIsEmpty(layer.bounds) && !layer.isHidden){
        layer.hidden = YES;
        [layers addObject:layer];
    }
    for (CALayer *sublayer in layer.sublayers){
        [layers addObjectsFromArray:[self hideEmptyLayers:sublayer]];
    }
    return layers;
}
- (void)restoreSuperviewAfterSnapshot:(NSArray *)hiddenLayers{
    for (CALayer *layer in hiddenLayers){
        layer.hidden = NO;
    }
}


@end
