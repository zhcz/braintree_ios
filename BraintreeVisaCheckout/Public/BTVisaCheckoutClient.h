#pragma message "⚠️ Braintree's Visa Checkout API for iOS is currently in beta and may change."

#import <PassKit/PassKit.h>
#if __has_include("BTAPIClient.h")
#import "BTAPIClient.h"
#else
#import <BraintreeCore/BTAPIClient.h>
#endif

#import "BTVisaCheckoutCardNonce.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BTVisaCheckoutErrorDomain;
typedef NS_ENUM(NSInteger, BTVisaCheckoutErrorType) {
    BTVisaCheckoutErrorTypeUnknown = 0,
    
    /// Visa Checkout is disabled in the Braintree Control Panel.
    BTVisaCheckoutErrorTypeUnsupported,
    
    /// Braintree SDK is integrated incorrectly.
    BTVisaCheckoutErrorTypeIntegration,
};

@interface BTVisaCheckoutClient : NSObject

/*!
 @brief Creates a Visa Checkout client.

 @param apiClient An API client.
 */
- (instancetype)initWithAPIClient:(BTAPIClient *)apiClient NS_DESIGNATED_INITIALIZER;


- (instancetype)init __attribute__((unavailable("Please use initWithAPIClient:")));

/*!
 @brief Tokenizes a `VisaPaymentSummary`.

 @note The `paymentSummary` parameter is declared as `id` type, but you must pass a `VisaPaymentSummary` instance.

 @param paymentSummary A `VisaPaymentSummary` instance.
 @param completion A completion block that is invoked when tokenization has completed. If tokenization succeeds,
        `tokenizedVisaCheckoutCard` will contain a nonce and `error` will be `nil`; if it fails,
        `tokenizedVisaCheckoutCard` will be `nil` and `error` will describe the failure.
 */
- (void)tokenizeVisaPaymentSummary:(id)paymentSummary
                         completion:(void (^)(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error))completion;

/*!
 @brief Populates the `VisaPaymentInfo` with the properties required for Braintree to process Visa Checkout payments.

 @note The `paymentSummary` parameter is declared as `id` type, but you must pass a `VisaPaymentSummary` instance.

 @param paymentInfo A `VisaPaymentInfo` instance.
 @param completion A completion block that is invoked when tokenization has completed.
         `error` indicates why Braintree could not add properties to the VisaPaymentInfo object.
 */
- (void)populatePaymentInfo:(id)paymentInfo completion:(void (^)(NSError * _Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
