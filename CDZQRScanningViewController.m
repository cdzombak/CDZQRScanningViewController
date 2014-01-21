//
//  CDZQRScanningViewController.m
//
//  Created by Chris Dzombak on 10/27/13.
//  Copyright (c) 2013 Chris Dzombak. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>

#import "CDZQRScanningViewController.h"

#ifndef CDZWeakSelf
#define CDZWeakSelf __weak __typeof__((__typeof__(self))self)
#endif

#ifndef CDZStrongSelf
#define CDZStrongSelf __typeof__(self)
#endif

static AVCaptureVideoOrientation CDZVideoOrientationFromInterfaceOrientation(UIInterfaceOrientation interfaceOrientation)
{
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            break;
    }
}

static const float CDZQRScanningTorchLevel = 0.25;
static const NSTimeInterval CDZQRScanningTorchActivationDelay = 0.25;

NSString * const CDZQRScanningErrorDomain = @"com.cdzombak.qrscanningviewcontroller";

@interface CDZQRScanningViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, copy) NSString *lastCapturedString;

@property (nonatomic, strong, readwrite) NSArray *metadataObjectTypes;

@end

@implementation CDZQRScanningViewController

- (instancetype)initWithMetadataObjectTypes:(NSArray *)metadataObjectTypes {
    self = [super init];
    if (!self) return nil;
    self.metadataObjectTypes = metadataObjectTypes;
    self.title = NSLocalizedString(@"Scan QR Code", nil);
    return self;
}

- (instancetype)init {
    return [self initWithMetadataObjectTypes:@[ AVMetadataObjectTypeQRCode ]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    UILongPressGestureRecognizer *torchGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTorchRecognizerTap:)];
    torchGestureRecognizer.minimumPressDuration = CDZQRScanningTorchActivationDelay;
    [self.view addGestureRecognizer:torchGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.cancelBlock) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemSelected:)];
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }

    self.lastCapturedString = nil;

    if (self.cancelBlock && !self.errorBlock) {
        CDZWeakSelf wSelf = self;
        self.errorBlock = ^(NSError *error) {
            CDZStrongSelf sSelf = wSelf;
            if (sSelf.cancelBlock) {
                sSelf.cancelBlock();
            }
        };
    }

    self.avSession = [[AVCaptureSession alloc] init];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([self.captureDevice isLowLightBoostSupported] && [self.captureDevice lockForConfiguration:nil]) {
            self.captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
            [self.captureDevice unlockForConfiguration];
        }

        [self.avSession beginConfiguration];

        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
        if (input) {
            [self.avSession addInput:input];
        } else {
            NSLog(@"QRScanningViewController: Error getting input device: %@", error);
            [self.avSession commitConfiguration];
            if (self.errorBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.errorBlock(error);
                });
            }
            return;
        }

        AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
        [self.avSession addOutput:output];
        for (NSString *type in self.metadataObjectTypes) {
            if (![output.availableMetadataObjectTypes containsObject:type]) {
                if (self.errorBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.errorBlock([NSError errorWithDomain:CDZQRScanningErrorDomain code:CDZQRScanningViewControllerErrorUnavailableMetadataObjectType userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unable to scan object of type %@", type]}]);
                    });
                }
                return;
            }
        }

        output.metadataObjectTypes = self.metadataObjectTypes;
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

        [self.avSession commitConfiguration];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.previewLayer.connection.isVideoOrientationSupported) {
                self.previewLayer.connection.videoOrientation = CDZVideoOrientationFromInterfaceOrientation(self.interfaceOrientation);
            }

            [self.avSession startRunning];
        });
    });

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.avSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = self.view.bounds;
    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = CDZVideoOrientationFromInterfaceOrientation(self.interfaceOrientation);
    }
    [self.view.layer addSublayer:self.previewLayer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
    [self.avSession stopRunning];
    self.avSession = nil;
    self.captureDevice = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = CDZVideoOrientationFromInterfaceOrientation(toInterfaceOrientation);
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect layerRect = self.view.bounds;
    self.previewLayer.bounds = layerRect;
    self.previewLayer.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
}

#pragma mark - UI Actions

- (void)cancelItemSelected:(id)sender {
    if (self.cancelBlock) self.cancelBlock();
}

- (void)handleTorchRecognizerTap:(UIGestureRecognizer *)sender {
    switch(sender.state) {
        case UIGestureRecognizerStateBegan:
            [self turnTorchOn];
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStatePossible:
            // no-op
            break;
        case UIGestureRecognizerStateRecognized: // also UIGestureRecognizerStateEnded
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            [self turnTorchOff];
            break;
    }
}

#pragma mark - Torch

- (void)turnTorchOn {
    if (self.captureDevice.hasTorch && self.captureDevice.torchAvailable && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOn] && [self.captureDevice lockForConfiguration:nil]) {
        [self.captureDevice setTorchModeOnWithLevel:CDZQRScanningTorchLevel error:nil];
        [self.captureDevice unlockForConfiguration];
    }
}

- (void)turnTorchOff {
    if (self.captureDevice.hasTorch && [self.captureDevice isTorchModeSupported:AVCaptureTorchModeOff] && [self.captureDevice lockForConfiguration:nil]) {
        self.captureDevice.torchMode = AVCaptureTorchModeOff;
        [self.captureDevice unlockForConfiguration];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *result;

    for (AVMetadataObject *metadata in metadataObjects) {
        if ([self.metadataObjectTypes containsObject:metadata.type]) {
            result = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            break;
        }
    }

    if (result && ![self.lastCapturedString isEqualToString:result]) {
        self.lastCapturedString = result;
        if (self.resultBlock) self.resultBlock(result);
    }
}

@end
