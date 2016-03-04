//
//  ADImageViewController.h
//  ADIMageVc
//
//  Created by adu on 15/12/1.
//  Copyright © 2015年 adu. All rights reserved.
//

//#import <UIKit/UIKit.h>
@import UIKit;
#import "ADImageInfo.h"

@protocol ADImageViewControllerDismissalDelegate;
@protocol ADImageViewControllerOptionsDelegate;
@protocol ADImageViewControllerImteractionsDelegate;
@protocol ADImageViewControllerAccessibilityDelegate;
@protocol ADImageViewControllerAnimationDelegate;

typedef NS_ENUM(NSInteger, ADImageViewControllerMode) {
    ADImageViewControllerMode_Image,
    ADImageViewControllerMode_AltText,
};

typedef NS_ENUM(NSInteger, ADImageViewControllerTransition) {
    ADImageViewControllerTransition_FromOriginalPosition,
    ADImageViewControllerTransition_FromOffScreen,
};

typedef NS_ENUM(NSInteger, ADImageViewControllerBackgroundOptions) {
    ADImageViewControllerBackgroundOptions_None = 0,
    ADImageViewControllerBackgroundOptions_Scaled = 1 << 0,
    ADImageViewControllerBackgroundOptions_Blurred = 1 <<1,
};

extern CGFloat const ADImageViewController_DefaultAlphaForBackgroundDimmingOverlay;
extern CGFloat const ADImageViewController_DefaultBackgroundBlusRadius;

@interface ADImageViewController : UIViewController
//@property (nonatomic, strong, readonly) ADImageInfo *imageInfo;
@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, assign, readonly) ADImageViewControllerMode *mode;
@property (nonatomic, assign, readonly) ADImageViewControllerBackgroundOptions *backgroundOptions;

- (instancetype)initWithImgae:(ADImageInfo *)imageInfo
                         mode:(ADImageViewControllerMode)mode
              backgroundStyle:(ADImageViewControllerBackgroundOptions)backgroundOptions;
- (void)showFromViewController:(UIViewController *)viewController
                    transition:(ADImageViewControllerTransition)transition;

- (void)dismiss:(BOOL)animated;

- (void)showWith:(UIViewController *)viewController;

@end
