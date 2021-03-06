#if __has_include(<Braintree/BraintreeThreeDSecure.h>)
#import <Braintree/BTThreeDSecureRequest.h>
#else
#import <BraintreeThreeDSecure/BTThreeDSecureRequest.h>
#endif

@class BTConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface BTThreeDSecureRequest ()

/**
 Set the BTPaymentFlowDriverDelegate for handling the driver events.
 */
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

/**
 The dfReferenceId for the session. Exposed for testing.
 */
@property (nonatomic, strong) NSString *dfReferenceId;

/**
 Prepare for a 3DS 2.0 flow.

 @param apiClient The API client.
 @param completionBlock This completion will be invoked exactly once. If the error is nil then the preparation was successful.
 */
- (void)prepareLookup:(BTAPIClient *)apiClient completion:(void (^)(NSError * _Nullable))completionBlock;

/**
 Process the 3DS lookup result by presenting a challenge or returning the payment information.

 @param lookupResult The BTThreeDSecureResult from a lookup call.
 @param configuration A BTConfiguration used to process the lookup.
 */
- (void)processLookupResult:(BTThreeDSecureResult *)lookupResult configuration:(BTConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
