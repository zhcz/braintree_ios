#import "BraintreeDemoVisaCheckoutViewController.h"
#import <BraintreeVisaCheckout/BraintreeVisaCheckout.h>
#import <UIKit/UIKit.h>
#import <VisaCheckoutFramework/VisaCheckoutFramework.h>

@interface BraintreeDemoVisaCheckoutViewController () <BTViewControllerPresentingDelegate, VisaLibraryDelegate>
@property (nonatomic, strong) VisaPaymentInfo *paymentInfo;
@property (nonatomic, strong) BTVisaCheckoutClient *client;

@end

@implementation BraintreeDemoVisaCheckoutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Visa Checkout";
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    
    self.client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.apiClient];

    [self setUpPaymentInfo];
}

- (void)setUpPaymentInfo {
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    [paymentInfo setAmount:[NSDecimalNumber decimalNumberWithString:@"9.99"]];
    [paymentInfo setCurrency:VCurrencyCodeUS];
    paymentInfo.subtotal = [NSDecimalNumber decimalNumberWithString:@"0"];

    paymentInfo.merchantRequestId = @"a001";
    paymentInfo.shippingHandlingCharges =
    [NSDecimalNumber decimalNumberWithString:@"0"];
    paymentInfo.tax = [NSDecimalNumber decimalNumberWithString:@"0"];
    paymentInfo.discount = [NSDecimalNumber decimalNumberWithString:@"0"];
    paymentInfo.giftWrapCharges = [NSDecimalNumber decimalNumberWithString:@"0"];
    paymentInfo.miscCharges = [NSDecimalNumber decimalNumberWithString:@"0"];
    paymentInfo.paymentDescription = @"sample transcation";
    paymentInfo.orderId = @"111";
    paymentInfo.promoCode = @"freeCheckout";
    paymentInfo.isShippingAddressRequired = YES;

    // SUMMARY, FULL (includes account number), or NONE (only call ID)
    paymentInfo.datalevel = @"FULL";
    // Pass merchant information
    VisaMerchantInfo *merchantInfo = [[VisaMerchantInfo alloc] init];
    merchantInfo.userReviewAction = kVisaUserReviewActionContinue;
    merchantInfo.displayName = @"The Merchant App";
    merchantInfo.customReviewActionContinueMessage = @"Add custom message here";
    merchantInfo.canadianDebitCardSupport = VAcceptCanadianDebitCard;
    // Choose a preferred locale when SDK is launched
    merchantInfo.preferredLocale = VLocale_enUS;
    paymentInfo.merchantInfo = merchantInfo;
    // Set up Verified by Visa (3D-Secure)
    VisaThreeDSSetUp *threeDSSetUp = [VisaThreeDSSetUp new];
    threeDSSetUp.threeDSActive = VisaActivate3DS;
    paymentInfo.threeDSSetUp = threeDSSetUp;

    // Set accepted countries for shipping
    NSMutableArray *acceptedCountryList =
    [[NSMutableArray alloc] initWithObjects:@"US",@"CA", @"AU", nil];
    paymentInfo.acceptedShippingCountries = acceptedCountryList;
    // Set accepted countries for billing
    NSMutableArray *acceptedBillingCountryList =
    [[NSMutableArray alloc] initWithObjects:@"CA", @"US", @"AU" , nil];
    paymentInfo.acceptedBillingCountries = acceptedBillingCountryList;
    
    [self.client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        if (error) {
            self.progressBlock(@"Failed to populatePaymentInfo");
            return;
        }
        self.paymentInfo = paymentInfo;
        
        VisaCheckoutButton *checkoutButton = [[VisaCheckoutButton alloc] initWithFrame:CGRectMake(0, 0, 213, 47)];
        checkoutButton.delegate = self;
        [self.paymentButton addSubview:checkoutButton];
    }];
}

#pragma mark - Overrides

- (UIView *)createPaymentButton {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 213, 47)];
}

#pragma mark BTViewControllerPresentingDelegate

- (void)paymentDriver:(__unused id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(__unused id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark VisaLibraryDelegate
- (void)checkoutFailedWithError:(NSError *)error {
    self.progressBlock([NSString stringWithFormat:@"Error: %@", error.localizedDescription]);
}

- (void)checkoutSuccessWithSummary:(__unused VisaPaymentSummary *)paymentSummary {
    self.progressBlock(@"Tokenizing...");

    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.apiClient];
    [client tokenizeVisaPaymentSummary:paymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutPayment, NSError * _Nullable error) {
        if (error) {
            self.progressBlock([NSString stringWithFormat:@"Error tokenizing Visa Checkout card: %@", error.localizedDescription]);
            return;
        }
        self.completionBlock(tokenizedVisaCheckoutPayment);
    }];
}

- (void)checkoutCancelled {
    self.progressBlock(@"Cancelled Visa Checkout");
}

- (UIViewController *)baseViewControllerForSDKLaunch {
    return self;
}

- (VisaPaymentInfo *)paymentInfo {
    return _paymentInfo;
}

- (VisaServer)visaServer{
    return kVisaSandboxServer;
}

@end
