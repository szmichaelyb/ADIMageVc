//
//  ADImageViewController.m
//  ADIMageVc
//
//  Created by adu on 15/12/1.
//  Copyright © 2015年 adu. All rights reserved.
//

#import "ADImageViewController.h"
#import "UIImage+ADImageEffects.h"

typedef struct {
    BOOL isAnimatingAPresentationOrDismissal;
    BOOL isDismissing;
    BOOL isTransitioningFromInitialModalToInteractiveState;
    BOOL viewHasAppeared;
    BOOL isRotating;
    BOOL isPresented;
    BOOL rotationTransformIsDirty;
    BOOL imageIsFlickingAwayForDismissal;
    BOOL isDraggingImage;
    BOOL scrollViewIsAnimatingAZoom;
    BOOL imageIsBeingReadFromDisk;
    BOOL isManuallyResizingTheScrollViewFrame;
    BOOL imageDownloadFailed;
} ADImageViewControllerFlags;

@interface ADImageViewController ()
<
    UIScrollViewDelegate,
    UITextViewDelegate,
    UIViewControllerTransitioningDelegate,
    UIGestureRecognizerDelegate
>

//General Info
@property (nonatomic, strong, readwrite) ADImageInfo *imageInfo;
@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign) ADImageViewControllerFlags flags;

//views
@property (nonatomic, strong) UIView *snapshotView;//上一界面的截图
@property (nonatomic, strong) UIView *blurredSnapshotView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *blackBackdrop;
@property (strong, nonatomic) UIScrollView *scrollView;

//UIDynamics
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIAttachmentBehavior *attachmentBehavior;
@property (nonatomic, assign) CGPoint imageDragStartingPoint;
@property (nonatomic, assign) UIOffset imageDragOffsetFromActualTranslation;
@property (nonatomic, assign) UIOffset imageDragOffsetFromImageCenter;

@end

@implementation ADImageViewController

- (instancetype)initWithImgae:(ADImageInfo *)imageInfo mode:(ADImageViewControllerMode)mode backgroundStyle:(ADImageViewControllerBackgroundOptions)backgroundOptions{
    self = [super initWithNibName:nil bundle:nil];
    NSLog(@"init");
    if (self) {
        _imageInfo = imageInfo;
    }
    
    return self;
}

- (void)showWith:(UIViewController *)viewController{
    self.view.userInteractionEnabled = NO;
    self.snapshotView = [self snapshotFromParentViewController:viewController];
    
    if (ADImageViewControllerBackgroundOptions_Blurred) {
        self.blurredSnapshotView = [self blurredSnapshotFromParentmostViewController:viewController];
        [self.snapshotView addSubview:self.blurredSnapshotView];
        self.blurredSnapshotView.alpha = 0;
    }
    
    [self.view insertSubview:self.snapshotView atIndex:0];
    [self.view addSubview:self.imageView];
    
    [viewController presentViewController:self animated:NO completion:^{
//        CGRect referenceFrameInWindow = [self.imageInfo.referenceView convertRect:self.imageInfo.referenceRect toView:nil];
//        CGRect referenceFrameInMyView = [self.view convertRect:referenceFrameInWindow fromView:nil];
//        self.imageView.frame = referenceFrameInMyView;
//        self.imageView.layer.masksToBounds = self.imageInfo.referenceCornerRadius;
        CGFloat duration = 0.3;
        __weak ADImageViewController *weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CABasicAnimation *cornerRadiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
            cornerRadiusAnimation.fromValue = @(weakSelf.imageView.layer.cornerRadius);
            cornerRadiusAnimation.toValue = @(0.0);
            cornerRadiusAnimation.duration = duration;
            [weakSelf.imageView.layer addAnimation:cornerRadiusAnimation forKey:@"cornerRadius"];
            weakSelf.imageView.layer.cornerRadius = 0.0;
            
            [UIView
             animateKeyframesWithDuration:duration
             delay:0
             options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
             animations:^{
                 self.blurredSnapshotView.alpha = 1.0;
                 weakSelf.imageView.transform = CGAffineTransformIdentity;
                 
                 CGRect endFrameForImageView;
                 if (weakSelf.image) {
                     endFrameForImageView = [weakSelf resizedFrameForAutorotatingImgaeView:weakSelf.image.size];
                 }else{
                     endFrameForImageView = [weakSelf resizedFrameForAutorotatingImgaeView:weakSelf.imageInfo.referenceRect.size];
                 }
                 weakSelf.imageView.frame = endFrameForImageView;
                 
                 CGPoint endCenterForImageView = CGPointMake(weakSelf.view.bounds.size.width * 0.5, weakSelf.view.bounds.size.height * 0.5);
                 weakSelf.imageView.center = endCenterForImageView;
                 
             } completion:^(BOOL finished) {
                 self.view.userInteractionEnabled = YES;
            }];
        });
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.mode == ADImageViewControllerMode_Image) {
        [self viewDidLoadForImageMode];
    }
   
}

- (void)viewDidLoadForImageMode{

    self.blackBackdrop = [[UIView alloc] initWithFrame:CGRectInset(self.view.bounds, -511, -511)];
    self.blackBackdrop.backgroundColor = [UIColor blackColor];
    self.blackBackdrop.alpha = 0.6;
    [self.view addSubview:self.blackBackdrop];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.delegate = self;
    self.scrollView.zoomScale = 1.0;
    self.scrollView.maximumZoomScale = 8.0;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.isAccessibilityElement = YES;
    self.scrollView.accessibilityLabel = self.accessibilityLabel;
//    self.scrollView.accessibilityHint -
    [self.view addSubview:self.scrollView];
    
    CGRect referenceFrameInWindow = [self.imageInfo.referenceView convertRect:self.imageInfo.referenceRect toView:nil];
    CGRect referenceFrameInMyview = [self.view convertRect:referenceFrameInWindow fromView:nil];

    self.imageView = [[UIImageView alloc] initWithFrame:referenceFrameInMyview];
    self.imageView.layer.cornerRadius = self.imageInfo.referenceCornerRadius;
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
//    self.imageView.userInteractionEnabled = YES;
    self.imageView.isAccessibilityElement = NO;
    self.imageView.layer.allowsEdgeAntialiasing = YES;
    
    self.imageView.image = self.imageInfo.image;
    self.image = self.imageInfo.image;
    
    [self setupImageModeGestureRecognizers];
}

- (void)setupImageModeGestureRecognizers{
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imgDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.delegate = self;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imgLongTap:)];
    longPress.delegate = self;
    
    UITapGestureRecognizer *sigleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imgSingleTap:)];
    [sigleTap requireGestureRecognizerToFail:doubleTap];
    [sigleTap requireGestureRecognizerToFail:longPress];
    sigleTap.delegate = self;
    
    [self.view addGestureRecognizer:doubleTap];
    [self.view addGestureRecognizer:longPress];
    [self.view addGestureRecognizer:sigleTap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrollWithPanGesture:)];
    pan.maximumNumberOfTouches = 1;
    pan.delegate = self;
    [self.scrollView addGestureRecognizer:pan];
}

- (void)dismiss:(BOOL)animated{
    self.view.userInteractionEnabled = NO;
    
    CGFloat duration = 0.3;
    __weak ADImageViewController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CABasicAnimation *cornerRadiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        cornerRadiusAnimation.fromValue = @(0.0);
        cornerRadiusAnimation.toValue = @(weakSelf.imageInfo.referenceCornerRadius);
        cornerRadiusAnimation.duration = duration;
        [weakSelf.imageView.layer addAnimation:cornerRadiusAnimation forKey:@"cornerRadius"];
        weakSelf.imageView.layer.cornerRadius = weakSelf.imageInfo.referenceCornerRadius;
        
        [UIView
         animateKeyframesWithDuration:duration
         delay:0
         options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
         animations:^{
             CGRect referenceFrameInWindow = [self.imageInfo.referenceView convertRect:self.imageInfo.referenceRect toView:self.view];
             
             weakSelf.imageView.frame = referenceFrameInWindow;
             self.blackBackdrop.alpha = 0.0;
             self.blurredSnapshotView.alpha = 0.0;
             
         } completion:^(BOOL finished) {
             [self.presentingViewController dismissViewControllerAnimated:NO completion:^{
                 
             }];
        
        }];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark methods

- (CGFloat)appropriateAngularResistanceForView:(UIView *)view{
    CGFloat height = view.bounds.size.height;
    CGFloat width = view.bounds.size.width;
    CGFloat actualArea = height *width;
    CGFloat refernceArea = self.view.bounds.size.width *self.view.bounds.size.height;
    CGFloat factor = refernceArea / actualArea;
    
    CGFloat defaultResistance = 4.0f;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat resistance = defaultResistance * ((320.0 *480.0) / (screenWidth / screenHeight));
   
    return resistance *factor;
}

- (CGFloat)appropriateDensityForView:(UIView *)view{
    CGFloat height = view.bounds.size.height;
    CGFloat width = view.bounds.size.width;
    CGFloat actualArea = height *width;
    CGFloat refernceArea = self.view.bounds.size.width *self.view.bounds.size.height;
    CGFloat factor = refernceArea / actualArea;
    
    CGFloat defaultDensity = 0.5f;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat resistance = defaultDensity * ((320.0 *480.0) / (screenWidth / screenHeight));
    
    return resistance *factor;
}

- (void)startImageDragging:(CGPoint)panGestureLocationInview translationOffSet:(UIOffset)translationOffSet{
    
    self.imageDragStartingPoint = panGestureLocationInview;
    self.imageDragOffsetFromActualTranslation = translationOffSet;
    CGPoint anchor = self.imageDragStartingPoint;
    CGPoint imageCenter = self.imageView.center;
    UIOffset offset = UIOffsetMake(panGestureLocationInview.x - imageCenter.x, panGestureLocationInview.y - imageCenter.y);
    self.imageDragOffsetFromImageCenter = offset;
    
    self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.imageView attachedToAnchor:anchor];
    [self.animator addBehavior:self.attachmentBehavior];
    
    UIDynamicItemBehavior *modifier = [[UIDynamicItemBehavior alloc] initWithItems:@[self.imageView]];
    modifier.angularResistance = [self appropriateAngularResistanceForView:self.imageView];
    modifier.density = [self appropriateDensityForView:self.imageView];
    [self.animator addBehavior:modifier];
    
    
}
- (void)scrollWithPanGesture:(UIPanGestureRecognizer *)sender{
    CGPoint translation = [sender translationInView:sender.view];
    CGPoint locationInview = [sender locationInView:sender.view];
    CGPoint velocity = [sender velocityInView:sender.view];
    CGFloat vectorDistance = sqrtf(powf(velocity.x, 2) + powf(velocity.y, 2));

    _flags.isDraggingImage = NO;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        _flags.isDraggingImage = CGRectContainsPoint(self.imageView.frame, locationInview);
        if (_flags.isDraggingImage) {
            [self startImageDragging:locationInview translationOffSet:UIOffsetZero];
        }
        
    }else if (sender.state == UIGestureRecognizerStateChanged){
        
        if (_flags.isDraggingImage) {
            CGPoint newAnchor = self.imageDragStartingPoint;
            newAnchor.x += translation.x + self.imageDragOffsetFromActualTranslation.horizontal;
            newAnchor.y += translation.y + self.imageDragOffsetFromActualTranslation.vertical;
            self.attachmentBehavior.anchorPoint = newAnchor;
        }else{
            _flags.isDraggingImage = CGRectContainsPoint(self.imageView.frame, locationInview);
            if (_flags.isDraggingImage) {
                UIOffset translationOffset = UIOffsetMake(-1*translation.x, -1*translation.y);
                [self startImageDragging:locationInview translationOffSet:translationOffset];
            }
        }
        
    }else{
        if (vectorDistance > 800) {
            if (_flags.isDraggingImage) {
                
            }else{
                [self dismiss:YES];
            }
        }else{
            
        }
    }
    
}

- (void)imgDoubleTap:(UITapGestureRecognizer *)sender{
    NSLog(@"imgDoubleTap");
}

- (void)imgSingleTap:(UITapGestureRecognizer *)sender{
    NSLog(@"imgSingleTap");
    [self dismiss:YES];
}

- (void)imgLongTap:(UILongPressGestureRecognizer *)sender{
    NSLog(@"imgLongTap");
}

- (CGRect)resizedFrameForAutorotatingImgaeView:(CGSize)imageSize{
    CGRect frame = self.view.bounds;
    CGFloat screenWidth = frame.size.width;
    CGFloat screenHeight = frame.size.height;
    
    CGFloat targetHeight = screenHeight;
    CGFloat targetWidth = screenWidth;
    CGFloat nativeHeight = screenHeight;
    CGFloat nativeWidth = screenWidth;
    
    if (imageSize.width > 0 && imageSize.height > 0) {
        nativeHeight = (imageSize.height > 0) ? imageSize.height :screenHeight;
        nativeWidth = (imageSize.width > 0) ? imageSize.width :screenWidth;
    }
    
    if (nativeHeight > nativeWidth) {
        if (screenHeight / screenWidth < nativeHeight / nativeWidth) {
            targetWidth = screenHeight / (nativeHeight / nativeWidth);
        }else{
            targetHeight = screenWidth / (nativeWidth / nativeHeight);
        }
    }else{
        if (screenWidth / screenHeight < nativeWidth / nativeHeight) {
            targetHeight = screenWidth / (nativeWidth / nativeHeight);
        }else{
            targetWidth = screenHeight / (nativeHeight / nativeWidth);
        }
    }
    
    frame.size = CGSizeMake(targetWidth, targetHeight);
    frame.origin = CGPointMake(0, 0);
    return frame;
    
}

- (UIView *)blurredSnapshotFromParentmostViewController:(UIViewController *)viewController{
    UIViewController *presentVIewController = viewController.view.window.rootViewController;
    while (presentVIewController.presentedViewController) {
        presentVIewController = presentVIewController.presentedViewController;
    }
    
    //draw the presentViewcontroller'view into a context
    
    CGFloat outerBleed = 20.0f;
    CGFloat performanceDownScalingFactor = 0.25;
    CGFloat scaleOuterBleed = outerBleed * performanceDownScalingFactor;
    CGRect contextBounds = CGRectInset(presentVIewController.view.bounds, - outerBleed, - outerBleed);
    CGRect scaledBounds = contextBounds;
    scaledBounds.size.width *= performanceDownScalingFactor;
    scaledBounds.size.height *= performanceDownScalingFactor;
    CGRect scaleDrawingArea = presentVIewController.view.bounds;
    scaleDrawingArea.size.width *= performanceDownScalingFactor;
    scaleDrawingArea.size.height *= performanceDownScalingFactor;
    
    UIGraphicsBeginImageContextWithOptions(scaledBounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, CGAffineTransformMakeTranslation(scaleOuterBleed, scaleOuterBleed));
    [presentVIewController.view drawViewHierarchyInRect:scaleDrawingArea afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
//    if (image) {
//        NSString *path =  @"/Users/adu/Desktop/image.png";
//        [UIImagePNGRepresentation(image) writeToFile: path    atomically:YES]; // 保存成功会返回YES
//    }
    UIGraphicsEndImageContext();
    
    CGFloat blusRadius = 0.5;
    UIImage *blurredImage = [image AD_applyBlurWithRadius:blusRadius tintColor:nil saturationDeltaFactor:1.0f maskImage:nil];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:contextBounds];
    imageView.image = blurredImage;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.backgroundColor = [UIColor blackColor];
    
    
//    if (blurredImage) {
//        NSString *path =  @"/Users/adu/Desktop/blurredImage.png";
//        [UIImagePNGRepresentation(blurredImage) writeToFile: path    atomically:YES]; // 保存成功会返回YES
//    }
    
    return imageView;
    
}

- (UIView *)snapshotFromParentViewController:(UIViewController *)viewController{
    
    UIViewController *presentViewController = viewController.view.window.rootViewController;
    while (presentViewController.presentedViewController) {
        presentViewController = presentViewController.presentedViewController;
    }
    
    UIView *sanp = [presentViewController.view snapshotViewAfterScreenUpdates:YES];
    sanp.clipsToBounds = NO;
    
    return sanp;
}
@end
