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
#if __has_include("PayPalDataCollector.h")
#import "PPDataCollector.h"
#else
#import <PayPalDataCollector/PPDataCollector.h>
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
@property (nonatomic, strong) NSString *correlationId;

@end

@implementation BTLocalPaymentRequest

- (id)copyWithZone:(__unused NSZone *)zone {
    BTLocalPaymentRequest *request = [[BTLocalPaymentRequest alloc] init];
    request.paymentType = self.paymentType;
    request.address = [self.address copy];
    request.amount = self.amount;
    request.currencyCode = self.currencyCode;
    request.email = self.email;
    request.firstName = self.firstName;
    request.lastName = self.lastName;
    request.phone = self.phone;
    request.localPaymentFlowDelegate = self.localPaymentFlowDelegate;
    return request;
}

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    BTLocalPaymentRequest *localPaymentRequest = (BTLocalPaymentRequest *)request;
    self.correlationId = [PPDataCollector clientMetadataID:nil];
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
    if ([url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/local-payment/cancel"]) {
        // canceled
        NSError *error = [NSError errorWithDomain:BTPaymentFlowDriverErrorDomain
                                             code:BTPaymentFlowDriverErrorTypeCanceled
                                         userInfo:@{}];
        [self.paymentFlowDriverDelegate onPaymentComplete:nil error:error];
    } else {
        // success
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"paypal_account"] = [@{} mutableCopy];
        parameters[@"paypal_account"][@"response"] = @{ @"webURL": url.absoluteString };
        parameters[@"paypal_account"][@"response_type"] = @"web";
        parameters[@"paypal_account"][@"options"] = @{ @"validate": @NO };
        parameters[@"paypal_account"][@"intent"] = @"sale";

        if (self.correlationId) {
            parameters[@"paypal_account"][@"correlation_id"] = self.correlationId;
        }

        BTClientMetadata *metadata =  self.paymentFlowDriverDelegate.apiClient.metadata;
        parameters[@"_meta"] = @{
                                 @"source" : metadata.sourceString,
                                 @"integration" : metadata.integrationString,
                                 @"sessionId" : metadata.sessionId,
                                 };

        [self.paymentFlowDriverDelegate.apiClient POST:@"/v1/payment_methods/paypal_accounts"
                  parameters:parameters
                  completion:^(__unused BTJSON *body, __unused NSHTTPURLResponse *response, NSError *error)
         {
             if (error) {
                 [self.paymentFlowDriverDelegate onPaymentComplete:nil error:error];
                 return;
             } else {
                 // TODO parse response into result
                 BTJSON *payPalAccount = body[@"paypalAccounts"][0];
                 NSString *nonce = [payPalAccount[@"nonce"] asString];
                 NSString *description = [payPalAccount[@"description"] asString];

                 BTJSON *details = payPalAccount[@"details"];

                 NSString *email = [details[@"email"] asString];
                 NSString *clientMetadataId = [details[@"correlationId"] asString];
                 // Allow email to be under payerInfo
                 if ([details[@"payerInfo"][@"email"] isString]) {
                     email = [details[@"payerInfo"][@"email"] asString];
                 }

                 NSString *firstName = [details[@"payerInfo"][@"firstName"] asString];
                 NSString *lastName = [details[@"payerInfo"][@"lastName"] asString];
                 NSString *phone = [details[@"payerInfo"][@"phone"] asString];
                 NSString *payerId = [details[@"payerInfo"][@"payerId"] asString];
                 BOOL isDefault = [payPalAccount[@"default"] isTrue];

                 BTPostalAddress *shippingAddress = [self.class shippingOrBillingAddressFromJSON:details[@"payerInfo"][@"shippingAddress"]];
                 BTPostalAddress *billingAddress = [self.class shippingOrBillingAddressFromJSON:details[@"payerInfo"][@"billingAddress"]];
                 if (!shippingAddress) {
                     shippingAddress = [self.class accountAddressFromJSON:details[@"payerInfo"][@"accountAddress"]];
                 }

                 // Braintree gateway has some inconsistent behavior depending on
                 // the type of nonce, and sometimes returns "PayPal" for description,
                 // and sometimes returns a real identifying string. The former is not
                 // desirable for display. The latter is.
                 // As a workaround, we ignore descriptions that look like "PayPal".
                 if ([description caseInsensitiveCompare:@"PayPal"] == NSOrderedSame) {
                     description = email;
                 }

                 BTLocalPaymentResult *tokenizedLocalPayment = [[BTLocalPaymentResult alloc] initWithNonce:nonce
                                                                                                description:description
                                                                                                      email:email
                                                                                                  firstName:firstName
                                                                                                   lastName:lastName
                                                                                                      phone:phone
                                                                                             billingAddress:billingAddress
                                                                                            shippingAddress:shippingAddress
                                                                                           clientMetadataId:clientMetadataId
                                                                                                    payerId:payerId
                                                                                                  isDefault:isDefault];
                 [self.paymentFlowDriverDelegate onPaymentComplete:tokenizedLocalPayment error:nil];
             }
         }];
    }
}

+ (BTPostalAddress *)accountAddressFromJSON:(BTJSON *)addressJSON {
    if (!addressJSON.isObject) {
        return nil;
    }

    BTPostalAddress *address = [[BTPostalAddress alloc] init];
    address.recipientName = [addressJSON[@"recipientName"] asString]; // Likely to be nil
    address.streetAddress = [addressJSON[@"street1"] asString];
    address.extendedAddress = [addressJSON[@"street2"] asString];
    address.locality = [addressJSON[@"city"] asString];
    address.region = [addressJSON[@"state"] asString];
    address.postalCode = [addressJSON[@"postalCode"] asString];
    address.countryCodeAlpha2 = [addressJSON[@"country"] asString];

    return address;
}

+ (BTPostalAddress *)shippingOrBillingAddressFromJSON:(BTJSON *)addressJSON {
    if (!addressJSON.isObject) {
        return nil;
    }

    BTPostalAddress *address = [[BTPostalAddress alloc] init];
    address.recipientName = [addressJSON[@"recipientName"] asString]; // Likely to be nil
    address.streetAddress = [addressJSON[@"line1"] asString];
    address.extendedAddress = [addressJSON[@"line2"] asString];
    address.locality = [addressJSON[@"city"] asString];
    address.region = [addressJSON[@"state"] asString];
    address.postalCode = [addressJSON[@"postalCode"] asString];
    address.countryCodeAlpha2 = [addressJSON[@"countryCode"] asString];

    return address;
}

- (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/local-payment"];
}

- (NSString *)paymentFlowName {
    // TODO add in payment type?
    return @"local-payment";
}

@end
