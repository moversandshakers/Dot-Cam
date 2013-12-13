//
//  AboutViewController.h
//  PasadenaSeniorCenter
//
//  Created by jrichards on 8/25/13.
//  Copyright (c) 2013 MoversAndShakers.mobi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, retain) UIView  *webViewParent;
@property (nonatomic, retain) UIWebView  *webView;
@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) UIBarButtonItem *forwardButton;
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, strong) UIView *navBar;

-(IBAction)backButtonPressed:(id)sender;
-(IBAction)websiteButtonPressed:(id)sender;

-(IBAction)webBackPressed:(id)sender;
-(IBAction)webForwardPressed:(id)sender;

@end