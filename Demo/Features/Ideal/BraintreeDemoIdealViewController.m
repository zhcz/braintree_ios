#import "BraintreeDemoIdealViewController.h"
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#import <BraintreeUI/UIColor+BTUI.h>
#import "BraintreeDemoMerchantAPI.h"

@interface BraintreeDemoIdealViewController () <BTViewControllerPresentingDelegate, BTLocalPaymentRequestDelegate>
@property (nonatomic, strong) BTPaymentFlowDriver *paymentFlowDriver;
@property (nonatomic, weak) UILabel *paymentIDLabel;
@end

@implementation BraintreeDemoIdealViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progressBlock(@"Loading iDEAL Merchant Account...");
    self.paymentButton.hidden = YES;
    [self setUpPaymentIDField];
    [[BraintreeDemoMerchantAPI sharedService] fetchClientTokenWithMerchantAccountId:@"ideal_eur" completion:^(__unused NSString * clientToken, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            self.paymentButton.hidden = NO;
            self.progressBlock(@"Ready!");
            BTAPIClient *idealClient = [[BTAPIClient alloc] initWithAuthorization:@"sandbox_f252zhq7_hh4cpc39zq4rgjcg"];
            self.paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:idealClient];
            self.paymentFlowDriver.viewControllerPresentingDelegate = self;
        }
    }];
    
    self.title = NSLocalizedString(@"iDEAL", nil);
}

- (UIView *)createPaymentButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:NSLocalizedString(@"Pay With iDEAL", nil) forState:UIControlStateNormal];
    [button setTitleColor:[UIColor bt_colorFromHex:@"3D95CE" alpha:1.0f] forState:UIControlStateNormal];
    [button setTitleColor:[[UIColor bt_colorFromHex:@"3D95CE" alpha:1.0f] bt_adjustedBrightness:0.7] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(idealButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)setUpPaymentIDField {
    UILabel *paymentIDLabel = [[UILabel alloc] init];
    paymentIDLabel.translatesAutoresizingMaskIntoConstraints = NO;
    paymentIDLabel.numberOfLines = 0;
    [self.view addSubview:paymentIDLabel];
    [paymentIDLabel.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor constant:8.0].active = YES;
    [paymentIDLabel.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor constant:8.0].active = YES;
    [paymentIDLabel.topAnchor constraintEqualToAnchor:self.paymentButton.bottomAnchor constant:8.0].active = YES;
    [paymentIDLabel.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor constant:8.0].active = YES;
    self.paymentIDLabel = paymentIDLabel;
}

- (void)idealButtonTapped {
    self.paymentIDLabel.text = nil;
    [self startPaymentWithBank];
}

- (void)startPaymentWithBank {
    BTAPIClient *idealClient = [[BTAPIClient alloc] initWithAuthorization:@"sandbox_f252zhq7_hh4cpc39zq4rgjcg"];
    self.paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:idealClient];
    self.paymentFlowDriver.viewControllerPresentingDelegate = self;

    BTLocalPaymentRequest *request = [[BTLocalPaymentRequest alloc] init];
    request.currencyCode = @"EUR";
    request.amount = @"1.01";
    request.firstName = @"Linh";
    request.lastName = @"Ngo";
    request.phone = @"639847934";
    request.address = [BTPostalAddress new];
    request.address.countryCodeAlpha2 = @"NL";
    request.address.postalCode = @"2585 GJ";
    request.address.streetAddress = @"836486 of 22321 Park Lake";
    request.address.locality = @"Den Haag";
    request.email = @"lingo-buyer@paypal.com";

    request.localPaymentFlowDelegate = self;
    [self.paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * _Nonnull result, NSError * _Nonnull error) {
        if (error) {
            if (error.code == BTPaymentFlowDriverErrorTypeCanceled) {
                self.progressBlock(@"Cancelled🎲");
            } else {
                self.progressBlock([NSString stringWithFormat:@"Error: %@", error]);
            }
        } else if (result) {
            BTLocalPaymentResult *idealResult = (BTLocalPaymentResult *)result;
            NSLog(@"%@", idealResult);
            
//            [self.paymentFlowDriver pollForCompletionWithId:idealResult.idealId retries:7 delay:5000 completion:^(BTPaymentFlowResult * _Nullable result, NSError * _Nullable error) {
//                BTIdealResult *idealResult = (BTIdealResult *)result;
//                if (error) {
//                    // ERROR
//                    self.progressBlock([NSString stringWithFormat:@"Error: %@", error]);
//                } else {
//                    NSLog(@"Ideal Status: %@", idealResult.status);
//                    NSLog(@"Ideal ID: %@", idealResult.idealId);
//                    NSLog(@"Ideal Short ID: %@", idealResult.shortIdealId);
//                    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:idealResult.status message:idealResult.idealId preferredStyle:UIAlertControllerStyleActionSheet];
//                    [self presentViewController:actionSheet animated:YES completion:nil];
//                    [actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
//                        //noop
//                    }]];
//                    self.progressBlock([NSString stringWithFormat:@"iDEAL Status: %@", idealResult.status]);
//                }
//            }];
        }
    }];
}

#pragma mark BTAppSwitchDelegate

- (void)paymentDriver:(__unused id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(__unused id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark BTIdealRequestDelegate

- (void)localPaymentStarted:(BTLocalPaymentResult *)result {
    self.paymentIDLabel.text = [NSString stringWithFormat:@"LocalPayment ID: %@", [result idealId]];
}

@end
