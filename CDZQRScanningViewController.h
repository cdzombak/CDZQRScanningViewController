//
//  CDZQRScanningViewController.h
//
//  Created by Chris Dzombak on 10/27/13.
//  Copyright (c) 2013 Chris Dzombak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^CDZQRScanResultBlock)(NSString *scanResult);
typedef void (^CDZQRScanErrorBlock)(NSError *error);
typedef void (^CDZQRScanCancelBlock)();

@interface CDZQRScanningViewController : UIViewController

- (id)initWithMetadataObjectTypes:(NSArray *)metadataObjectTypes;

// Your blocks will be called on the main queue.
@property (nonatomic, copy) CDZQRScanResultBlock resultBlock;
@property (nonatomic, copy) CDZQRScanErrorBlock errorBlock;
@property (nonatomic, copy) CDZQRScanCancelBlock cancelBlock;

@property (nonatomic, strong) NSArray *metadataObjectTypes;

@end
