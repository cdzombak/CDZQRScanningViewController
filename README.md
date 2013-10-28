# CDZQRScanningViewController

Easy QR code scanning on iOS 7.

## Installation

Add the dependency to your `Podfile`:

```ruby
platform :ios
pod 'CDZQRScanningViewController'
...
```

Run `pod install` to install the dependencies.

## Usage

`#import "CDZQRScanningViewController.h"`, then:

```objc
// assume this text field is defined elsewhere:
UITextField *field = self.someTextField;

[field becomeFirstResponder];

// create the scanning view controller and a navigation controller in which to present it:
CDZQRScanningViewController *scanningVC = [CDZQRScanningViewController new];
UINavigationController *scanningNavVC = [[UINavigationController alloc] initWithRootViewController:scanningVC];

// configure the scanning view controller:
scanningVC.resultBlock = ^(NSString *result) {
    field.text = result;
    [scanningNavVC dismissViewControllerAnimated:YES completion:nil];
};
scanningVC.cancelBlock = ^() {
    [scanningNavVC dismissViewControllerAnimated:YES completion:nil];
};
scanningVC.errorBlock = ^(NSError *error) {
    // todo: show a UIAlertView orNSLog the error
    [scanningNavVC dismissViewControllerAnimated:YES completion:nil];
};

// present the view controller full-screen on iPhone; in a form sheet on iPad:
scanningNavVC.modalPresentationStyle = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? UIModalPresentationFullScreen : UIModalPresentationFormSheet;
[self presentViewController:scanningNavVC animated:YES completion:nil];
```

If you don't want to present the scanner in its own modal `UIViewController`, [use view controller containment to embed it in your own view controller](https://github.com/cdzombak/CDZQRScannerThatDoesntSuck/blob/master/QRScanner/CDZRootViewController.m#L55), instead of presenting it inside a nav controller as in this example.

## Other features

Tap and hold on the live video view for 0.25 seconds to activate the device's flashlight for use in low-light.

## Why use this instead of ZBarSDK?

* smaller surface area
* easier to use
* less configuration
* less impact on your code
* much smaller, thanks to new APIs in iOS 7
* MIT license instead of GPL

## Requirements

`CDZQRScanningViewController` requires iOS 7+.

## License

MIT. See `LICENSE` included in this repo.

## Developer

Chris Dzombak

* [chris.dzombak.name](http://chris.dzombak.name/)
* chris@chrisdzombak.net
* [t@cdzombak](https://twitter.com/cdzombak)
* [a@dzombak](https://alpha.app.net/dzombak)
