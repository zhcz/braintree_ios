#if __has_include("BraintreeCore.h")
#import "BTAPIClient_Internal.h"
#import "BTPaymentMethodNonce.h"
#import "BTPaymentMethodNonceParser.h"
#else
#import <BraintreeCore/BTAPIClient_Internal.h>
#import <BraintreeCore/BTPaymentMethodNonce.h>
#import <BraintreeCore/BTPaymentMethodNonceParser.h>
#endif
#import "BTConfiguration+VisaCheckout.h"
#import "BTVisaCheckoutClient_Internal.h"
#import "BTVisaCheckoutCardNonce.h"

NSString *const BTVisaCheckoutErrorDomain = @"com.braintreepayments.BTVisaCheckoutErrorDomain";

@interface BTVisaCheckoutClient ()
@end

@implementation BTVisaCheckoutClient

+ (void)load {
    if (self == [BTVisaCheckoutClient class]) {
        [[BTPaymentMethodNonceParser sharedParser] registerType:@"VisaCheckoutCard" withParsingBlock:^BTPaymentMethodNonce * _Nullable(BTJSON * _Nonnull visaCheckoutCard) {
            return [BTVisaCheckoutCardNonce visaCheckoutCardNonceWithJSON:visaCheckoutCard];
        }];
    }
}

- (instancetype)initWithAPIClient:(BTAPIClient *)apiClient {
    if (self = [super init]) {
        _apiClient = apiClient;
    }
    return self;
}

- (instancetype)init {
    return nil;
}

- (void)tokenizeVisaPaymentSummary:(id)paymentSummary completion:(void (^)(BTVisaCheckoutCardNonce * _Nullable, NSError * _Nullable))completion {
    if (!self.apiClient) {
        NSError *error = [NSError errorWithDomain:BTVisaCheckoutErrorDomain
                                             code:BTVisaCheckoutErrorTypeIntegration
                                         userInfo:@{NSLocalizedDescriptionKey: @"BTVisaCheckoutClient tokenization failed because BTAPIClient is nil."}];
        completion(nil, error);
        return;
    }

    if (!paymentSummary || ![NSStringFromClass([paymentSummary class])isEqualToString:@"VisaPaymentSummary"]) {
        NSError *error = [NSError errorWithDomain:BTVisaCheckoutErrorDomain
                                             code:BTVisaCheckoutErrorTypeIntegration
                                         userInfo:@{NSLocalizedDescriptionKey: @"A valid Visa payment summary is required."}];
        completion(nil, error);
        [self.apiClient sendAnalyticsEvent:@"ios.visa-checkout.error.invalid-payment"];
        return;
    }

    [self.apiClient sendAnalyticsEvent:@"ios.visa-checkout.start"];

    [self.apiClient fetchOrReturnRemoteConfiguration:^(BTConfiguration *configuration, NSError *error) {
        if (error) {
            [self.apiClient sendAnalyticsEvent:@"ios.visa-checkout.error.configuration"];
            completion(nil, error);
            return;
        }

        if (!configuration.isVisaCheckoutEnabled) {
            NSError *error = [NSError errorWithDomain:BTVisaCheckoutErrorDomain
                                                 code:BTVisaCheckoutErrorTypeUnsupported
                                             userInfo:@{ NSLocalizedDescriptionKey: @"Visa Checkout is not enabled for this merchant. Please ensure that Visa Checkout is enabled in the Braintree Control Panel and try again." }];
            completion(nil, error);
            [self.apiClient sendAnalyticsEvent:@"ios.visa-checkout.error.disabled"];
            return;
        }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        NSString *callId = [paymentSummary performSelector:@selector(callId)];
        NSString *encryptedKey = [paymentSummary performSelector:@selector(encKey)];
        NSString *encryptedPaymentData = [paymentSummary performSelector:@selector(encPaymentData)];
#pragma clang diagnostic pop

        NSMutableDictionary *parameters = [NSMutableDictionary new];
        parameters[@"visaCheckoutCard"] = @{
                                            @"callId" : callId,
                                            @"encryptedKey" : encryptedKey,
                                            @"encryptedPaymentData" : encryptedPaymentData
                                            };
        parameters[@"_meta"] = @{
                                 @"source" : self.apiClient.metadata.sourceString,
                                 @"integration" : self.apiClient.metadata.integrationString,
                                 @"sessionId" : self.apiClient.metadata.sessionId,
                                 };

        [self.apiClient POST:@"v1/payment_methods/visa_checkout_cards"
                  parameters:parameters
                  completion:^(BTJSON *body, __unused NSHTTPURLResponse *response, NSError *error) {
                      if (error) {
                          completion(nil, error);
                          [self.apiClient sendAnalyticsEvent:@"ios.visa-checkout.error.tokenization"];
                          return;
                      }

                      BTJSON *visaCheckoutCard = body[@"visaCheckoutCards"][0];
                      BTVisaCheckoutCardNonce *tokenizedVisaCheckoutCard = [BTVisaCheckoutCardNonce visaCheckoutCardNonceWithJSON:visaCheckoutCard];
                      completion(tokenizedVisaCheckoutCard, nil);
                      [self.apiClient sendAnalyticsEvent:@"ios.visa-checkout.success"];
                  }];
    }];
}


- (void)populatePaymentInfo:(id)paymentInfo completion:(void (^)(NSError * _Nullable error))completion {
    if (!paymentInfo || ![NSStringFromClass([paymentInfo class])isEqualToString:@"VisaPaymentInfo"]) {
        NSError *error = [NSError errorWithDomain:BTVisaCheckoutErrorDomain
                                             code:BTVisaCheckoutErrorTypeUnsupported
                                         userInfo:@{NSLocalizedDescriptionKey: @"A valid VisaPaymentInfo is required."}];
        completion(error);
        return;
    }
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id merchantInfo = [paymentInfo performSelector:@selector(merchantInfo)];

    if (!merchantInfo || ![NSStringFromClass([merchantInfo class])isEqualToString:@"VisaMerchantInfo"]) {
        NSError *error = [NSError errorWithDomain:BTVisaCheckoutErrorDomain
                                             code:BTVisaCheckoutErrorTypeUnsupported
                                         userInfo:@{NSLocalizedDescriptionKey: @"A valid VisaMerchantInfo is required to be set on the VisaPaymentInfo"}];
        completion(error);
        return;
    }
    
    [self.apiClient fetchOrReturnRemoteConfiguration:^(BTConfiguration * _Nullable configuration, NSError * _Nullable error) {
        if (error) {
            completion(error);
            return;
        }
        
        [paymentInfo setValue:@"FULL" forKey:@"datalevel"];

#pragma clang diagnostic ignored "-Wundeclared-selector"
        if (![merchantInfo performSelector:@selector(merchantAPIKey)]) {
            [merchantInfo setValue:[configuration visaCheckoutAPIKey] forKey:@"merchantAPIKey"];
        }
        
        if (![merchantInfo performSelector:@selector(externalClientId)]) {
            [merchantInfo setValue:[configuration visaCheckoutExternalClientId] forKey:@"externalClientId"];
        }
        
        [paymentInfo setValue:[configuration visaCheckoutSupportedNetworks] forKey:@"acceptedPaymentTypesAndBrands"];
    
        completion(nil);
    }];
}

@end
