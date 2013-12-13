//
//  ViewController.m
//  DotCam
//
//  Created by jrichards on 10/12/13.
//  Copyright (c) 2013 MoversAndShakers.mobi. All rights reserved.
//

#import "ViewController.h"
#import "AboutViewController.h"
#import "R1PhotoEffectsSDK.h"
#import "R1PhotoEffectsEditingViewController.h"

#define LIGHT_LABEL_TAG 90
#define LIGHT_IMAGE_TAG 91
#define LIGHT_BUTTON_TAG 92

#define EDIT_BUTTON_TAG 93
#define INFO_BUTTON_TAG 94
#define SWITCH_BUTTON_TAG 95

#define TAKE_PIC_LABEL_TAG 97
#define TAKE_PIC_IMAGE_TAG 100
#define TAKE_PIC_BUTTON_TAG 98

#define NAV_BAR_TAG 99

#define SHARE_BUTTON_TAG 96
#define SHARE_IMAGE_TAG 101
#define SHARE_LABEL_TAG 102

#define EDIT_ARROW_TAG 103

#define DITHER_BUTTON_TAG 104

#define DITHER_TYPE_ATKINSONS 0
#define DITHER_TYPE_BW        1


@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL lightOn;
    BOOL picTaken;
    BOOL isUsingFrontFacingCamera;
    int centerPixValue;
    int ditherType;
}

@property (nonatomic, strong) CATransition *shutterAnimation;
@property (nonatomic, strong) CALayer *cameraShutter;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) CALayer *customPreviewLayer;

@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraDeviceInput;
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraDeviceInput;

@property (nonatomic, strong) AVCaptureStillImageOutput *snapper;

@property (nonatomic, strong) UIImageView *capturedImageView;


- (void)setupCameraSession;

+ (UIImage *)rotateImage:(UIImage *)image onDegrees:(float)degrees;
-(void)shutter:(CALayer *)layer bounds:(CGRect)bounds;
+(CGRect)calcCenter:(int)vw vh:(int)vh iw:(int)iw ih:(int)ih neverScaleUp:(BOOL)neverScaleUp;

@end


@implementation ViewController
{
    AVCaptureSession *_captureSession;
    AVCaptureVideoDataOutput *_dataOutput;
    
    CALayer *_customPreviewLayer;
    
    Pixel_8 *outBuffer;
    
    BOOL snapNextPic;
    BOOL shouldToggleTorch;
    
    UIImage *capturedImage;
}

@synthesize navBar;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    centerPixValue = 128;
    ditherType = DITHER_TYPE_ATKINSONS;
    
    self.infoButton = (UIButton *)[self.view viewWithTag:INFO_BUTTON_TAG];
    self.switchButton = (UIButton *)[self.view viewWithTag:SWITCH_BUTTON_TAG];
    self.lightButton =(UIButton *)[self.view viewWithTag:LIGHT_BUTTON_TAG];
    self.lightImageView =(UIImageView *)[self.view viewWithTag:LIGHT_IMAGE_TAG];
    self.lightLabel =(UILabel *)[self.view viewWithTag:LIGHT_LABEL_TAG];
    self.takePicImageView =(UIImageView *)[self.view viewWithTag:TAKE_PIC_IMAGE_TAG];
    self.takePicLabel =(UILabel *)[self.view viewWithTag:TAKE_PIC_LABEL_TAG];
    self.takePicButton = (UIButton *)[self.view viewWithTag:TAKE_PIC_BUTTON_TAG];
    
    self.shareButton =(UIButton *)[self.view viewWithTag:SHARE_BUTTON_TAG];
    self.shareImageView =(UIImageView *)[self.view viewWithTag:SHARE_IMAGE_TAG];
    self.shareLabel =(UILabel *)[self.view viewWithTag:SHARE_LABEL_TAG];
    
    self.editButton = (UIButton *)[self.view viewWithTag:EDIT_BUTTON_TAG];
    
    self.editArrow = (UILabel *)[self.view viewWithTag:EDIT_ARROW_TAG];
    
    self.navBar = [self.view viewWithTag:NAV_BAR_TAG];
    
    self.ditherButton =(UIButton *)[self.view viewWithTag:DITHER_BUTTON_TAG];
    
    
    [self setupCameraSession];
    
    //Light
    [self.view bringSubviewToFront:self.lightImageView];
    [self.lightImageView setHidden:NO];
    [self.view bringSubviewToFront:self.lightLabel];
    [self.lightLabel setHidden:NO];
    [self.view bringSubviewToFront:self.lightButton];
    [self.lightButton setHidden:NO];
    [self turnTorchOn:NO];
    
    //Take pic
    [self.view bringSubviewToFront:self.takePicImageView];
    [self.takePicImageView setHidden:NO];
    [self.view bringSubviewToFront:self.takePicLabel];
    [self.takePicLabel setHidden:NO];
    [self.view bringSubviewToFront:self.takePicButton];
    [self.takePicButton setHidden:NO];
    
    //Share
    [self.view bringSubviewToFront:self.shareImageView];
    [self.shareImageView setHidden:NO];
    [self.view bringSubviewToFront:self.shareLabel];
    [self.shareLabel setHidden:NO];
    [self.view bringSubviewToFront:self.shareButton];
    [self.shareButton setHidden:NO];
    [self.shareButton setAlpha:0.03];
    [self.shareLabel setAlpha:0.4];
    [self.shareImageView setAlpha:0.4];
    
    //Edit button
    [self.view bringSubviewToFront:self.editButton];
    [self.editButton setHidden:YES];

    //Nav bar
    [self.view bringSubviewToFront:self.navBar];
    
    //Edit Arrorw
    CGPoint editArrowPos = self.editButton.center;
    editArrowPos.x += 42;
    self.editArrow.center = editArrowPos;
    [self.view bringSubviewToFront:self.editArrow];
    [self.editArrow setHidden:YES];
    
    
    [self.view bringSubviewToFront:self.takePicButton];
    
    //dither button
    [self.view bringSubviewToFront:self.ditherButton];
    [self.ditherButton setHidden:NO];
    [self handleDitherType];
    
    [_captureSession startRunning];
}

/**
 * When the view dissapears, turn off the torch
 */
- (void) viewDidDisappear:(BOOL)animated
{
    [self turnTorchOn:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ditherButtonPressed:(id)sender
{
    CGRect f = self.view.frame;
    f.origin.x += 30;
    f.size.width -= 60;
    f.origin.y = self.view.center.y - 90;
    f.size.height = 180;
    self.ditherPicker = [[UIPickerView alloc] initWithFrame:f];
    self.ditherPicker.delegate = self;
    self.ditherPicker.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.ditherPicker];
    
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(40, 20, 200, 30)];
    lab.text = @"Select the dithering type";
    [self.ditherPicker addSubview:lab];
    
    [self.ditherPicker selectRow:ditherType inComponent:0 animated:YES];
}

- (IBAction)switchCamPressed:(id)sender

{
    CABasicAnimation *rotate =
    [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.toValue = @(M_PI*2);
    rotate.duration = 0.25;
    
    [_customPreviewLayer addAnimation:rotate
                               forKey:@"myRotationAnimation"];
    
    AVCaptureDevicePosition desiredPosition;
    
    if (isUsingFrontFacingCamera)
        
        desiredPosition = AVCaptureDevicePositionBack;
    
    else
        
        desiredPosition = AVCaptureDevicePositionFront;
    
    AVCaptureSession *session = _captureSession;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo])
    {
        
        if ([d position] == desiredPosition)
        {
            
            [session beginConfiguration];
            
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            
            for (AVCaptureInput *oldInput in [session inputs])
            {
                
                [session removeInput:oldInput];
                
            }
            
            [session addInput:input];
            
            [session commitConfiguration];
            
            break;
            
        }
        
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
    
    [[NSUserDefaults standardUserDefaults] setBool:isUsingFrontFacingCamera forKey:@"useFront"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self handleTorchState];
    
}

-(IBAction)sharePressed:(id)sender
{
    NSString *textToShare = @"[DotCam] - Cool Retro 1-bit camera! ";
    UIImage *imageToShare = capturedImage;
    NSURL *url = [NSURL URLWithString:@"http://moversandshakers.mobi"];
    NSArray *activityItems = [[NSArray alloc]  initWithObjects:textToShare, imageToShare,url,nil];
    
    UIActivity *activity = [[UIActivity alloc] init];
    
    NSArray *applicationActivities = [[NSArray alloc] initWithObjects:activity, nil];
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                      applicationActivities:applicationActivities];
    [self presentViewController:activityVC animated:YES completion:nil];

}

- (IBAction)editButtonPressed:(id)sender
{
    //pick an existing UIImage
    UIImage *pickedImage = capturedImage;
    
    //push the view controller
    UIViewController *vc = [[R1PhotoEffectsSDK sharedManager]
                            photoEffectsControllerForImage: pickedImage
                            delegate: (id<R1PhotoEffectsEditingViewControllerDelegate>)self
                            cropSupport: YES];
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self presentViewController:vc animated:NO completion:nil];
    
    //[self presentViewController:vc animated:YES completion:nil];

}

-(IBAction)takePicButtonPressed:(id)sender
{
    if(picTaken == NO)
    {
        picTaken = YES;
         [self turnTorchOn:NO];
    }
    else picTaken = NO;
    
    [self handleTakePicState];
}

-(IBAction)infoButtonPressed:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AboutViewController *c = (AboutViewController*)[storyboard instantiateViewControllerWithIdentifier: @"aboutViewController"];
    c.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:c animated:YES completion:nil];
}

- (IBAction)lightButtonPressed:(id)sender
{
    if([_captureSession isRunning] == YES)
        shouldToggleTorch = YES;
    else
        [self toggleTorch];
}

- (void)setupCameraSession
{
    //ICLog;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    // Session
    _captureSession = [AVCaptureSession new];
    
    //Get and set the presets value
    NSString *presets = [[NSUserDefaults standardUserDefaults] objectForKey:@"videoPresetString"];
    if(presets == nil) presets = AVCaptureSessionPreset352x288;
    
    presets = AVCaptureSessionPreset352x288;
    
    if([presets compare:AVCaptureSessionPreset352x288] == NSOrderedSame)
    {
        //self.vidSize = CGSizeMake(352, 288);
        self.vidSize = CGSizeMake(288, 352);
    }
    else if([presets compare:AVCaptureSessionPreset640x480] == NSOrderedSame)
    {
        self.vidSize = CGSizeMake(640, 480);
    }
    else if([presets compare:AVCaptureSessionPreset1280x720] == NSOrderedSame)
    {
        self.vidSize = CGSizeMake(1280, 720);
    }
    else if([presets compare:AVCaptureSessionPreset1920x1080] == NSOrderedSame)
    {
        self.vidSize = CGSizeMake(1920, 1080);
    }
    
    [_captureSession setSessionPreset:presets];
    

    outBuffer = (Pixel_8 *)calloc(self.vidSize.width * self.vidSize.height, sizeof(Pixel_8));
    NSLog(@"%@, %f %f\n", _captureSession.sessionPreset, self.vidSize.width,self.vidSize.height);
    
    isUsingFrontFacingCamera = [[NSUserDefaults standardUserDefaults] boolForKey:@"useFront"];
    [self addVideoInput:isUsingFrontFacingCamera];
    
    // Preview
    
    //Calc size
    _customPreviewLayer = [CALayer layer];
    _customPreviewLayer.borderColor = [UIColor blackColor].CGColor;
    _customPreviewLayer.borderWidth = 1.0;
    
    //Calc size
    float top  = self.editButton.frame.origin.y + self.editButton.frame.size.height;
    float bottom = screenSize.height - 70;
    float left = 0.0;
    float right = self.view.frame.size.width;
    _customPreviewLayer.bounds = [ViewController calcCenter:(int)(right-left) vh:(int)(bottom-top) iw:self.vidSize.width ih:self.vidSize.height neverScaleUp:NO];

    //Must be rotated!
    CGRect temp = CGRectMake(0,0, _customPreviewLayer.bounds.size.height-4, _customPreviewLayer.bounds.size.width-4);
    _customPreviewLayer.bounds = temp;
    _customPreviewLayer.position = CGPointMake(self.view.frame.size.width/2., (top + bottom) / 2.);
    _customPreviewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI/2);
    [self.view.layer addSublayer:_customPreviewLayer];
    
    //Create output
    self.snapper = [AVCaptureStillImageOutput new];
    self.snapper.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG, AVVideoQualityKey:@0.6};
    [_captureSession addOutput:self.snapper];
 
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                                                            forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [_dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    if ( [_captureSession canAddOutput:_dataOutput] )
        [_captureSession addOutput:_dataOutput];
    
    //Set the max frame rate to 15 per sec.
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:nil];
        [device setActiveVideoMaxFrameDuration:CMTimeMake(1, 15)];
        [device unlockForConfiguration];
    }

    
    [_captureSession commitConfiguration];
    
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [_dataOutput setSampleBufferDelegate:self queue:queue];
}

- (void)addVideoInput:(BOOL)front
{
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices)
    {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            
            if ([device position] == AVCaptureDevicePositionBack)
            {
                NSLog(@"Device position : back");
                self.backCamera = device;
            }
            else
            {
                NSLog(@"Device position : front");
                self.frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    [_captureSession beginConfiguration];
    
    
    if(self.frontCamera != nil)
    {
        self.backCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.frontCamera error:&error];
        if (!error && front == YES)
        {
            if ([[self captureSession] canAddInput:self.backCameraDeviceInput])
                [[self captureSession] addInput:self.backCameraDeviceInput];
            else
            {
                NSLog(@"Couldn't add front facing video input");
            }
        }
        else if(error)
            self.backCameraDeviceInput = nil;
    }
    if(self.backCamera != nil)
    {
        self.frontCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.backCamera error:&error];
        
        if (!error && front == NO)
        {
            if ( [_captureSession canAddInput:self.frontCameraDeviceInput] )
                [_captureSession addInput:self.frontCameraDeviceInput];
        }
        else if(error)
            self.frontCameraDeviceInput = nil;
    }
    
    [_captureSession commitConfiguration];
}

- (void)maxFromImage:(const vImage_Buffer)src toImage:(const vImage_Buffer)dst
{
    int kernelSize = 7;
    vImageMin_Planar8(&src, &dst, NULL, 0, 0, kernelSize, kernelSize, kvImageDoNotTile);
}

- (void)atkinsonDither:(const vImage_Buffer)src toImage:(const vImage_Buffer)dst
{
    uint8_t *srcData = (uint8_t *)src.data;
    uint8_t *dstData = (uint8_t *)dst.data;
    int x, y, w, h;
    float p, q, e;
    
    w = (int)src.width;
    h = (int)src.height;
    
    int centerPix = centerPixValue;
    
    memcpy(dstData, srcData, (w*h));
    
    
    for(y = 0; y < h; y++)
        for(x = 0; x < w; x++)
        {
            
            //int x2 = x;
            //int s = 1;
            
            p = dstData[y * w + x];
            //q = p < 0.5 ? 0. : 1.;
            //q = p < 128 ? 0. : 255.;
            q = p < centerPix ? 0. : 255.;
            dstData[y * w + x] = q;
            
            e = (p - q) / 8.;
            if(x < w - 1)
                dstData[y * w + x + 1] += e;
            if(x < w - 2)
                dstData[y * w + x + 2] += e;
            if(y < h - 1)
            {
                if(x > 0)
                    dstData[(y + 1) * w + x - 1] += e;
                dstData[(y + 1) * w + x] += e;
                if(x < w - 1)
                    dstData[(y + 1) * w + x + 1] += e;
            }
            if(y < h - 2)
            {
                dstData[(y + 2) * w + x] += e;
            }
            
        }
    
}

- (void)bwDither:(const vImage_Buffer)src toImage:(const vImage_Buffer)dst
{
    uint8_t *srcData = (uint8_t *)src.data;
    uint8_t *dstData = (uint8_t *)dst.data;
    int x, y, w, h;
    float q;
    
    w = (int)src.width;
    h = (int)src.height;
    
    int centerPix = centerPixValue;
    
    memcpy(dstData, srcData, (w*h));
    
    
    for(y = 0; y < h; y++)
        for(x = 0; x < w; x++)
        {

            q = dstData[y * w + x] < centerPix ? 0. : 255.;
            dstData[y * w + x] = q;
        }
    
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // For the iOS the luma is contained in full plane (8-bit)
    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    
    Pixel_8 *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    const vImage_Buffer inImage = { lumaBuffer, height, width, bytesPerRow };
    
    // Pixel_8 *outBuffer = (Pixel_8 *)calloc(width*height, sizeof(Pixel_8));
    const vImage_Buffer outImage = { outBuffer, height, width, bytesPerRow };
    //[self maxFromImage:inImage toImage:outImage];
    
    if(ditherType == DITHER_TYPE_ATKINSONS)
        [self atkinsonDither:inImage toImage:outImage];
    else if(ditherType == DITHER_TYPE_BW)
        [self bwDither:inImage toImage:outImage];
    
    if(snapNextPic == YES)
    {
        [_captureSession stopRunning];
        
        snapNextPic = NO;
        
        dispatch_sync(dispatch_get_main_queue(), ^{

            capturedImage = [self imageFromBuf:outBuffer width:(int)width height:(int)height];
            
            UIImage *rotIm = [ViewController rotateImage:capturedImage onDegrees:90.0];
            capturedImage = rotIm;
            
            _customPreviewLayer.hidden = YES;
            
            CGRect f = _customPreviewLayer.frame;
            f.origin.x += 5.0;
            f.origin.y += 5.0;
            f.size.width -= 10.0;
            f.size.height -= 10.0;
            
            self.capturedImageView = [[UIImageView alloc] initWithFrame:f];
            self.capturedImageView.image = rotIm;
            self.capturedImageView.layer.borderColor = [UIColor grayColor].CGColor;
            self.capturedImageView.layer.borderWidth = 5.0;
            [self.view addSubview:self.capturedImageView];
            [self.view bringSubviewToFront:self.capturedImageView];
            
            CABasicAnimation* anim3 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            [anim3 setToValue:[NSNumber numberWithFloat:1.0]];
            [anim3 setFromValue:[NSNumber numberWithFloat:0.6]]; // rotation angle
            [anim3 setDuration:0.5];
            //[anim2 setRepeatCount:1];
            [anim3 setAutoreverses:NO];
            [[self.capturedImageView layer] addAnimation:anim3 forKey:@"titleScale"];
            
            [self animateEditButton];
            

        });
  
    }

    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(outImage.data, width, height, 8,
                                                 bytesPerRow, grayColorSpace, (CGBitmapInfo)kCGImageAlphaNone);
    CGImageRef dstImageFilter = CGBitmapContextCreateImage(context);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        _customPreviewLayer.contents = (__bridge id)dstImageFilter;
    });
    
    CGImageRelease(dstImageFilter);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
    
    //Toggle the torch if necessary.
    if(shouldToggleTorch == YES)
    {
        shouldToggleTorch = NO;
        [self toggleTorch];
    }
    
}

-(void)animateEditButton
{
    [self.editArrow setAlpha:1.0];
    [self.editButton setAlpha:1.0];
    
    [self.editArrow setHidden:NO];
    [self.editButton setHidden:NO];
    
    CABasicAnimation* translationAnimation1;
    translationAnimation1 = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    translationAnimation1.fromValue = [NSNumber numberWithFloat:-222];
    translationAnimation1.toValue = [NSNumber numberWithFloat:0];
    translationAnimation1.duration = 1;
    translationAnimation1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    translationAnimation1.removedOnCompletion = NO;
    
    CABasicAnimation *alpha1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alpha1 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alpha1.fromValue = [NSNumber numberWithFloat:0.0];
    alpha1.toValue = [NSNumber numberWithFloat:1.0];
    alpha1.duration = 1;
    alpha1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    [self.editButton.layer addAnimation:translationAnimation1 forKey:nil];
    [self.editButton.layer addAnimation:alpha1 forKey:nil];
    
}

-(UIImage *) imageFromBuf:(uint8_t *)rawImageData width:(int)width height:(int)height
{
    //unsigned char *rawImageData = (unsigned char *)[self.imageData bytes];
    UIImage *newImage = nil;
    
    //int width = self.imageWidth  * self.scale;
    //int height = self.imageHeight * self.scale;
    int nrOfColorComponents = 1; //
    int bitsPerColorComponent = 8;
    int rawImageDataLength = width * height * nrOfColorComponents;
    BOOL interpolateAndSmoothPixels = NO;
    // CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;//kCGBitmapByteOrderDefault;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef dataProviderRef;
    CGColorSpaceRef colorSpaceRef;
    CGImageRef imageRef;
    
    // THIS IS TEST CODE TO RANDOMLY COLOUR THE NON TRANSPARENT AREAS OF THE IMAGE
#if 0
    // Randomly recolour the image
    int r=abs(arc4random()%256);
    int g=abs(arc4random()%256);
    int b=abs(arc4random()%256);
    
    for(int i=0;i<rawImageDataLength;i+=4)
    {
        if ((rawImageData[i+3] & 0xff) != 0)
        {
            rawImageData[i]=r;
            rawImageData[i+1]=g;
            rawImageData[i+2]=b;
        }
    }
#endif
    
    @try
    {
        GLubyte *rawImageDataBuffer = rawImageData;
        
        dataProviderRef = CGDataProviderCreateWithData(NULL, rawImageDataBuffer, rawImageDataLength, nil);
        colorSpaceRef = CGColorSpaceCreateDeviceGray();
        imageRef = CGImageCreate(width, height, bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents, colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent);
        newImage = [[UIImage alloc] initWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
        //newImage = [[UIImage alloc] initWithCGImage:imageRef];
    }
    @finally
    {
        CGDataProviderRelease(dataProviderRef);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(imageRef);
    }
    
    return newImage;
}

+ (UIImage *)rotateImage:(UIImage *)image onDegrees:(float)degrees
{
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    
    CGFloat boundHeight;
    
    boundHeight = bounds.size.height;
    bounds.size.height = bounds.size.width;
    bounds.size.width = boundHeight;
    transform = CGAffineTransformMakeScale(-1.0, 1.0);
    transform = CGAffineTransformRotate(transform, M_PI / 2.0); //use angle/360 *MPI
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;   
    
}

// Play the shutter sound and display the camera iris animation.
-(void)shutter:(CALayer *)layer bounds:(CGRect)bounds
{
    //Shutter
    self.shutterAnimation = [CATransition animation];
    [self.shutterAnimation setDelegate:self];
    [self.shutterAnimation setDuration:0.6];
    self.shutterAnimation.timingFunction = UIViewAnimationCurveEaseInOut;
    [self.shutterAnimation setType:@"cameraIris"];
    [self.shutterAnimation setValue:@"cameraIris" forKey:@"cameraIris"];
    self.cameraShutter = [[CALayer alloc]init];
    [self.cameraShutter setBounds:bounds];
    [layer addSublayer:self.cameraShutter];
    [layer addAnimation:self.shutterAnimation forKey:@"cameraIris"];
  
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [self.cameraShutter removeFromSuperlayer];
    [self.view.layer removeAnimationForKey:@"cameraIris"];
    //do what you need to do when animation ends...
}

+(CGRect)calcCenter:(int)vw vh:(int)vh iw:(int)iw ih:(int)ih neverScaleUp:(BOOL)neverScaleUp
{
    double scale = MIN ((double)vw/(double)iw, (double)vh/(double)ih );
    
    int h = (int)(!neverScaleUp || scale<1.0 ? scale * ih : ih);
    int w = (int)(!neverScaleUp || scale<1.0 ? scale * iw : iw);
    
    return CGRectMake(0, 0, w, h );
 
}

#pragma mark - Photo Effects

- (void)photoEffectsEditingViewController:(R1PhotoEffectsEditingViewController *)controller didFinishWithImage:(UIImage *)image
{
    //Do something with the resulting UIImage
    //For example:
    capturedImage = image;
    //Dismiss the editor
    [self.capturedImageView setContentMode:UIViewContentModeScaleAspectFit];
    self.capturedImageView.image = image;
    [self.capturedImageView sizeToFit];
    self.capturedImageView.layer.position = _customPreviewLayer.position;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)photoEffectsEditingViewControllerDidCancel:(R1PhotoEffectsEditingViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Image touch events

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   // UITouch *touch = [touches anyObject];
   // CGPoint p = [touch locationInView:self.view];
    //NSLog(@"TB:%f,%f\n", p.x, p.y);
    //[boxLayer setPosition:p];
    
    //CGRect f = _customPreviewLayer.frame;
    //NSLog(@"%f, %f, %f, %f\n", f.origin.x, f.origin.y, f.origin.x+f.size.width, f.origin.y+f.size.height);
    
    centerPixValue = 128;
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self.view];
    //NSLog(@"TM:%f,%f\n", p.x, p.y);
    
    CGRect f = _customPreviewLayer.frame;
    float pct = (p.y - f.origin.y)/f.size.height;
    if(pct < 0) pct = 0;
    else if (pct > 100.0) pct = 100.0;
    
    centerPixValue = (int)(255.0*pct);
    
}

#pragma mark - Torch control

- (void) toggleTorch
{
    //Front facing camera does not have a torch, causes freezing.
    if(isUsingFrontFacingCamera == YES)
    {
        [self.lightButton setEnabled:NO];
        [self.lightButton setAlpha:1.0];
        [self.lightLabel setEnabled:NO];
        [self.lightLabel setAlpha:0.4];
        [self.lightImageView setAlpha:0.4];
        self.lightImageView.image  = [UIImage imageNamed:@"bulb-on"];
        self.lightLabel.text = @"Turn Torch On";
        return;
    }
    
    BOOL isTorchAvailable = NO;
    AVCaptureTorchMode torchMode;
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if ([device hasTorch] && [device hasFlash])
        {
            isTorchAvailable = device.isTorchAvailable;
            torchMode = device.torchMode;
        }
    }
    
    if(isTorchAvailable == NO) return;
    else if (torchMode == AVCaptureTorchModeOff) [self turnTorchOn:YES];
    else [self turnTorchOn:NO];

}

- (void) turnTorchOn: (bool) on
{
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash])
        {
            
            
            [device lockForConfiguration:nil];
            if (on)
            {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];

            }
            else
            {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
   
            }
            [device unlockForConfiguration];
            
            [_captureSession commitConfiguration];
            
         
            //[_captureSession startRunning];
           
            
        }
        
        [self handleTorchState];
    
    }
    else
    {
        [self handleTorchState];
    }
}

/**
 * Detect the torch state and set the correct torch button image.
 */
-(void)handleTorchState
{

    BOOL isTorchAvailable = NO;
    AVCaptureTorchMode torchMode = AVCaptureTorchModeOn;
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //[device lockForConfiguration:nil];
        isTorchAvailable = device.isTorchAvailable;
        torchMode = device.torchMode;
        //[device unlockForConfiguration];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
    if(isTorchAvailable == NO || isUsingFrontFacingCamera)
    {
        [self.lightButton setEnabled:NO];
        [self.lightLabel setEnabled:NO];
        [self.lightButton setAlpha:0.0];
        [self.lightLabel setAlpha:0.6];
        [self.lightImageView setAlpha:0.2];
        if(isUsingFrontFacingCamera) self.lightLabel.text = @"No Front Torch";
        else
            self.lightLabel.text = @"No Torch";
        [self.lightButton setImage:[UIImage imageNamed:@"bulb-off"] forState:UIControlStateNormal];
    }
    else if(torchMode == AVCaptureTorchModeOn) //Need to turn off
    {
        [self.lightButton setEnabled:YES];
        [self.lightButton setAlpha:0.03];
        [self.lightLabel setEnabled:YES];
        [self.lightLabel setAlpha:1.0];
        [self.lightImageView setAlpha:1.0];
        self.lightImageView.image  = [UIImage imageNamed:@"bulb-off"];
        self.lightLabel.text = @"Turn Torch Off";
        [self.lightLabel setNeedsDisplay];

    }
    else //Need to turn on
    {
        [self.lightButton setEnabled:YES];
        [self.lightButton setAlpha:0.03];
        [self.lightLabel setEnabled:YES];
        [self.lightLabel setAlpha:1.0];
        [self.lightImageView setAlpha:1.0];
        self.lightImageView.image  = [UIImage imageNamed:@"bulb-on"];
        self.lightLabel.text = @"Turn Torch On";
        
        [self.lightLabel setNeedsDisplay];
        
    }
    });
    
}

#pragma mark - Take pic stste

-(void)handleTakePicState
{
    
    if(picTaken)
    {
        [self shutter:self.view.layer bounds:self.customPreviewLayer.bounds];
        
        snapNextPic = YES;
        
        [self.shareButton setEnabled:YES];
        [self.shareButton setAlpha:1.0];
        [self.switchButton setEnabled:NO];
        [self.switchButton setAlpha:0.4];
        [self.editButton setHidden:NO];
        [self.editArrow setHidden:NO];
        [self.ditherButton setHidden:YES];
        [self.ditherButton setHidden:YES];
        
        self.takePicImageView.image  = [UIImage imageNamed:@"play"];
        self.takePicLabel.text = @"Camera";
        
        [self.shareLabel setAlpha:1.0];
        [self.shareImageView setAlpha:1.0];
        
        //[_captureSession stopRunning];
    }
    else
    {
        centerPixValue = 128;
        
        [self.shareButton setEnabled:NO];
        [self.shareButton setAlpha:0.4];
        [self.switchButton setEnabled:YES];
        [self.switchButton setAlpha:1.0];
        [self.editButton setHidden:YES];
        [self.editArrow setHidden:YES];
        [self.ditherButton setHidden:NO];
        [self.ditherButton setHidden:NO];

        
        self.takePicImageView.image  = [UIImage imageNamed:@"take-pic-cam"];
        self.takePicLabel.text = @"Snap Pic";
        
        [self.shareLabel setAlpha:0.4];
        [self.shareImageView setAlpha:0.4];
        
        _customPreviewLayer.hidden = NO;
        if(self.capturedImageView != nil)
        {
            [self.capturedImageView removeFromSuperview];
            self.capturedImageView = nil;
        }
        [_captureSession startRunning];
    }
    
    [self handleTorchState];

    
}

-(void)handleDitherType
{
    if(ditherType == DITHER_TYPE_ATKINSONS)
    {
        [self.ditherButton setTitle:@"Dither: Atkinson" forState:UIControlStateNormal];
        [self.ditherButton setTitle:@"Select Dither..." forState:UIControlStateSelected];
    }
    else if(ditherType == DITHER_TYPE_BW)
    {
        [self.ditherButton setTitle:@"Dither: B&W" forState:UIControlStateNormal];
        [self.ditherButton setTitle:@"Select Dither..." forState:UIControlStateSelected];
    }
}


#pragma mark -
#pragma mark Dither Picker DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return 2;
}
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    if(row == 0) return @"Atkinson";
    else if(row == 1) return @"B & W";
    else return @"???";
}

#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    if(row == 0) ditherType = DITHER_TYPE_ATKINSONS;
    else if(row == 1) ditherType = DITHER_TYPE_BW;
    
    [self handleDitherType];
    
    [self.ditherPicker removeFromSuperview];
    
}



@end
