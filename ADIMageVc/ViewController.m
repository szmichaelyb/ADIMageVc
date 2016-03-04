//
//  ViewController.m
//  ADIMageVc
//
//  Created by adu on 15/11/30.
//  Copyright © 2015年 adu. All rights reserved.
//

#import "ViewController.h"
#import "ADImageViewController.h"
#import "ADImageInfo.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *catImg;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.catImg.layer.cornerRadius = 80;
    self.catImg.layer.masksToBounds = YES;
    self.catImg.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imgOnClck:)];
    [self.catImg addGestureRecognizer:tap];
    
}

- (void)imgOnClck:(UITapGestureRecognizer *)sender{
    NSLog(@"让你点 = %@", NSStringFromCGRect(self.catImg.frame));
    
    
    
    ADImageInfo *imageinfo = [[ADImageInfo alloc] init];
    imageinfo.image = self.catImg.image;
    imageinfo.referenceRect = self.catImg.frame;
    imageinfo.referenceView = self.catImg.superview;
    imageinfo.referenceCornerRadius = self.catImg.layer.cornerRadius;
    
    ADImageViewController *imgVc = [[ADImageViewController alloc] initWithImgae:imageinfo mode:ADImageViewControllerMode_Image backgroundStyle:ADImageViewControllerBackgroundOptions_Blurred];
    [imgVc showWith:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
