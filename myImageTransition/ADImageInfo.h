//
//  ADImageInfo.h
//  ADIMageVc
//
//  Created by adu on 15/12/1.
//  Copyright © 2015年 adu. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface ADImageInfo : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, copy) NSURL *imageUrl;
@property (nonatomic, copy) NSURL *canonicalImageUrl;
@property (nonatomic, copy) NSString *altText;
@property (nonatomic, copy) NSString *title;

@property (nonatomic, assign) CGRect referenceRect;
@property (nonatomic, strong) UIView *referenceView;

@property (nonatomic, assign) CGFloat referenceCornerRadius;
@property (nonatomic, copy) NSMutableDictionary *userInfo;

- (NSString *) displayableTitlAltTextSummary;
- (NSString *) combinedTitleAndText;
- (CGPoint) referenceRectCenter;

@end
