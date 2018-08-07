#import "BTLocalPaymentRequest.h"
#import "BTConfiguration+LocalPayment.h"
#if __has_include("BTLogger_Internal.h")
#import "BTLogger_Internal.h"
#else
#import <BraintreeCore/BTLogger_Internal.h>
#endif
#if __has_include("BTAPIClient_Internal.h")
#import "BTAPIClient_Internal.h"
#else
#import <BraintreeCore/BTAPIClient_Internal.h>
#endif
#import "BTPaymentFlowDriver_Internal.h"
#import "BTLocalPaymentRequest.h"
#import "Braintree-Version.h"
#import <SafariServices/SafariServices.h>
#import "BTLocalPaymentResult.h"
#import "BTPaymentFlowDriver+LocalPayment_Internal.h"

@interface BTLocalPaymentRequest ()

@property (nonatomic, copy, nullable) NSString *paymentId;
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation BTLocalPaymentRequest

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    BTLocalPaymentRequest *localPaymentRequest = (BTLocalPaymentRequest *)request;
    [apiClient fetchOrReturnRemoteConfiguration:^(__unused BTConfiguration *configuration, NSError *configurationError) {
        if (configurationError) {
            [delegate onPaymentComplete:nil error:configurationError];
            return;
        }

        if ([self.paymentFlowDriverDelegate returnURLScheme] == nil || [[self.paymentFlowDriverDelegate returnURLScheme] isEqualToString:@""]) {
            [[BTLogger sharedLogger] critical:@"iDEAL requires a return URL scheme to be configured via [BTAppSwitch setReturnURLScheme:]"];
            NSError *error = [NSError errorWithDomain:BTPaymentFlowDriverErrorDomain
                                                 code:BTPaymentFlowDriverErrorTypeInvalidReturnURL
                                             userInfo:@{NSLocalizedDescriptionKey: @"UIApplication failed to perform app or browser switch."}];
            [delegate onPaymentComplete:nil error:error];
            return;
        } else if (localPaymentRequest.localPaymentFlowDelegate == nil) {
            [[BTLogger sharedLogger] critical:@"BTLocalPaymentRequest localPaymentFlowDelegate can not be nil."];
            NSError *error = [NSError errorWithDomain:BTPaymentFlowDriverErrorDomain
                                                 code:BTPaymentFlowDriverErrorTypeIntegration
                                             userInfo:@{NSLocalizedDescriptionKey: @"Failed to begin payment flow: BTLocalPaymentRequest localPaymentFlowDelegate can not be nil."}];
            [delegate onPaymentComplete:nil error:error];
            return;
        } else if (localPaymentRequest.amount == nil) {
            [[BTLogger sharedLogger] critical:@"BTLocalPaymentRequest amount can not be nil."];
            NSError *error = [NSError errorWithDomain:BTPaymentFlowDriverErrorDomain
                                                 code:BTPaymentFlowDriverErrorTypeIntegration
                                             userInfo:@{NSLocalizedDescriptionKey: @"Failed to begin payment flow: BTLocalPaymentRequest amount can not be nil."}];
            [delegate onPaymentComplete:nil error:error];
            return;
        }

        
        NSMutableDictionary *params = [@{
                                 @"amount": localPaymentRequest.amount,
                                 @"intent": @"sale"
                                 } mutableCopy];

        params[@"return_url"] = [NSString stringWithFormat:@"%@%@", [delegate returnURLScheme], @"://x-callback-url/braintree/local-payment/success"];
        params[@"cancel_url"] = [NSString stringWithFormat:@"%@%@", [delegate returnURLScheme], @"://x-callback-url/braintree/local-payment/cancel"];

        if (localPaymentRequest.address) {
            params[@"line1"] = localPaymentRequest.address.streetAddress;
            params[@"line2"] = localPaymentRequest.address.extendedAddress;
            params[@"city"] = localPaymentRequest.address.locality;
            params[@"state"] = localPaymentRequest.address.region;
            params[@"postal_code"] = localPaymentRequest.address.postalCode;
            params[@"country_code"] = localPaymentRequest.address.countryCodeAlpha2;
        }

        if (localPaymentRequest.paymentType) {
            params[@"funding_source"] = localPaymentRequest.paymentType;
        }

        if (localPaymentRequest.currencyCode) {
            params[@"currency_iso_code"] = localPaymentRequest.currencyCode;
        }

        if (localPaymentRequest.firstName) {
            params[@"first_name"] = localPaymentRequest.firstName;
        }

        if (localPaymentRequest.lastName) {
            params[@"last_name"] = localPaymentRequest.lastName;
        }

        if (localPaymentRequest.email) {
            params[@"payer_email"] = localPaymentRequest.email;
        }

        if (localPaymentRequest.phone) {
            params[@"phone"] = localPaymentRequest.phone;
        }

        [apiClient POST:@"v1/paypal_hermes/create_payment_resource"
                   parameters:params
                   completion:^(BTJSON *body, __unused NSHTTPURLResponse *response, NSError *error) {
             if (!error) {
                 self.paymentId = [body[@"paymentResource"][@"paymentToken"] asString];
                 NSString *approvalUrl = [body[@"paymentResource"][@"redirectUrl"] asString];
                 NSURL *url = [NSURL URLWithString:approvalUrl];
                 // TODO verify id and url are present?
                 if (self.localPaymentFlowDelegate) {
                     [self.localPaymentFlowDelegate localPaymentStarted:self paymentId:self.paymentId start:^{
                         [delegate onPaymentWithURL:url error:error];
                     }];
                 }
             } else {
                 [delegate onPaymentWithURL:nil error:error];
             }
         }];
    }];
}

- (void)handleOpenURL:(__unused NSURL *)url {
    // TODO parse return URL
    //[self.paymentFlowDriverDelegate onPaymentComplete:result error:error];
}

- (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/local-payment"];
}

- (NSString *)paymentFlowName {
    // TODO add in payment type?
    return @"local-payment";
}

@end
