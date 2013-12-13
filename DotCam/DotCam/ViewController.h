//
//  ViewController.h
//  DotCam
//
//  Created by jrichards on 10/12/13.
//  Copyright (c) 2013 MoversAndShakers.mobi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    
}

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *takePicButton;
@property (nonatomic, strong) UILabel *takePicLabel;
@property (nonatomic, strong) UIImageView *takePicImageView;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UILabel *shareLabel;
@property (nonatomic, strong) UIImageView *shareImageView;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) UIButton *infoButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *lightButton;
@property (nonatomic, strong) UILabel *lightLabel;
@property (nonatomic, strong) UIImageView *lightImageView;
@property (nonatomic, strong) UILabel *editArrow;
@property (nonatomic, strong) UIButton *ditherButton;
@property (strong, nonatomic) IBOutlet UIPickerView *ditherPicker;

@property (nonatomic) CGSize vidSize;

-(void)handleDitherType;

-(IBAction)switchCamPressed:(id)sender;
-(IBAction)sharePressed:(id)sender;
-(UIImage *) imageFromBuf:(uint8_t *)rawImageData width:(int)width height:(int)height;
-(IBAction)infoButtonPressed:(id)sender;
-(IBAction)takePicButtonPressed:(id)sender;

@end
