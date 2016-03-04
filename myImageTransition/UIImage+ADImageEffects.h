//
//  UIImage+ADImageEffects.h
//  ADIMageVc
//
//  Created by adu on 15/12/1.
//  Copyright © 2015年 adu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ADImageEffects)
- (UIImage *)AD_applyBlurWithRadius:(CGFloat)blurRadius
                          tintColor:(UIColor *)tintColor
              saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                          maskImage:(UIImage *)maskImage;
@end
