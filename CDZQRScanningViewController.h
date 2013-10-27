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

@property (nonatomic, copy) CDZQRScanResultBlock resultBlock;
@property (nonatomic, copy) CDZQRScanErrorBlock errorBlock;
@property (nonatomic, copy) CDZQRScanCancelBlock cancelBlock;

@end
