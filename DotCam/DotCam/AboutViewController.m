//
//  AboutViewController.m
//  PasadenaSeniorCenter
//
//  Created by jrichards on 8/25/13.
//  Copyright (c) 2013 MoversAndShakers.mobi. All rights reserved.
//

#import "AboutViewController.h"

#define WEBVIEW_PARENT_VIEW_TAG 99
#define TOOLBAR_TAG 90
#define TIMERTAG                1
#define NAV_BAR_TAG 89

@interface AboutViewController ()

@end

@implementation AboutViewController

@synthesize webViewParent;
@synthesize webView;
@synthesize backButton;
@synthesize forwardButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.webView.delegate = self;
    
    self.toolbar = (UIToolbar *)[self.view viewWithTag:TOOLBAR_TAG];
    
    
    self.webViewParent = (UIButton *)[self.view viewWithTag:WEBVIEW_PARENT_VIEW_TAG];
    [self.webViewParent setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.webViewParent setAlpha:0.0];
    self.navBar = [self.view viewWithTag:NAV_BAR_TAG];

    float top  = self.navBar.frame.origin.y + self.navBar.frame.size.height;
    CGRect f = self.webView.frame;
    f.origin.y  = top;
    //f.size.height = 200;
    //self.webView.frame = f;
    self.webView.bounds = f;
    f = self.webViewParent.frame;
    f.size.height = 350;
    self.webViewParent.bounds = f;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)backButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)websiteButtonPressed:(id)sender
{
    //[self.webViewParent setAlpha:1.0];
    
    //Create a URL object.
    NSURL *thisURL = [NSURL URLWithString:@"http://moversandshakers.mobi"];
    
    //URL Requst Object
    NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:thisURL];
    
    
    //Load the request in the UIWebView.
    [self.webView loadRequest:requestObj];
    
    
    [UIView animateWithDuration:2.0 animations:^(void) {
        self.webViewParent.alpha = 1.0;
        self.webView.alpha = 1.0;
    }];
}

-(IBAction)webBackPressed:(id)sender
{
    [self.webView goBack];
}

-(IBAction)webForwardPressed:(id)sender
{
    [self.webView goForward];
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    // Adjust the indicator so it is up a few pixels from the bottom of the alert
    //indicator.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    CGRect indicatorRect = CGRectMake(self.view.frame.size.width/2-32, self.view.frame.size.height/2-32, 64, 64);
    //[indicator setBackgroundColor:[UIColor blackColor]];
    [indicator setColor:[UIColor blackColor]];
    //indicator.bounds = indicatorRect;
    indicator.frame = indicatorRect;
    [indicator startAnimating];
    indicator.tag = TIMERTAG;
    [self.view addSubview:indicator];
    
    [self.backButton setEnabled:[self.webView canGoBack]];
    [self.forwardButton setEnabled:[self.webView canGoForward]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //Remove the loading indicator if it is there.
    UIView *v = [self.view viewWithTag:TIMERTAG];
    if(v != nil)
        [v removeFromSuperview];
    
    
    [self.backButton setEnabled:[self.webView canGoBack]];
    [self.forwardButton setEnabled:[self.webView canGoForward]];
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //Remove the loading indicator if it is there.
    UIView *v = [self.view viewWithTag:TIMERTAG];
    if(v != nil)
        [v removeFromSuperview];
    
}

@end
