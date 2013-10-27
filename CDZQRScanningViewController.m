//
//  CDZQRScanningViewController.m
//
//  Created by Chris Dzombak on 10/27/13.
//  Copyright (c) 2013 Chris Dzombak. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "CDZQRScanningViewController.h"

#ifndef CDZWeakSelf
#define CDZWeakSelf __weak __typeof__((__typeof__(self))self)
#endif

@interface CDZQRScanningViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, copy) NSString *lastCapturedString;

@end

@implementation CDZQRScanningViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Scan QR Code", nil);

    if (self.cancelBlock) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemSelected:)];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.lastCapturedString = nil;

    if (self.cancelBlock && !self.errorBlock) {
        CDZWeakSelf wSelf = self;
        self.errorBlock = ^(NSError *error) { wSelf.cancelBlock(); };
    }

    self.avSession = [[AVCaptureSession alloc] init];
    self.avSession.sessionPreset = AVCaptureSessionPreset1280x720;

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (input) {
        [self.avSession addInput:input];
    } else {
        NSLog(@"QRScanningViewController: Error getting input device: %@", error);
        if (self.errorBlock) self.errorBlock(error);
        return;
    }

    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [self.avSession addOutput:output];

    if (![output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        NSLog(@"QRScanningViewController Error: QR object type not available.");
        if (self.errorBlock) self.errorBlock(nil);
        return;
    }

    output.metadataObjectTypes = @[ AVMetadataObjectTypeQRCode ];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.avSession];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = self.view.bounds;
    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = self.interfaceOrientation;
    }
    [self.view.layer addSublayer:self.previewLayer];

    [self.avSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.avSession stopRunning];
    self.previewLayer = nil;
    self.avSession = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = toInterfaceOrientation;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect layerRect = self.view.bounds;
    self.previewLayer.bounds = layerRect;
    self.previewLayer.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));

    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - UI Actions

- (void)cancelItemSelected:(id)sender {
    if (self.cancelBlock) self.cancelBlock();
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *result;

    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
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
