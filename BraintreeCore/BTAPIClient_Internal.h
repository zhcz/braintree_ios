#import "BTAnalyticsService.h"
#import "BTAPIClient.h"
#import "BTClientMetadata.h"
#import "BTClientToken.h"
#import "BTHTTP.h"
#import "BTAPIHTTP.h"
#import "BTGraphQLHTTP.h"
#import "BTJSON.h"
#import "BTPayPalIDToken.h"

NS_ASSUME_NONNULL_BEGIN

@class BTPaymentMethodNonce;

typedef NS_ENUM(NSInteger, BTAPIClientHTTPType) {
    /// Use the Gateway
    BTAPIClientHTTPTypeGateway = 0,

    /// Use the Braintree API
    BTAPIClientHTTPTypeBraintreeAPI,

    /// Use the GraphQL API
    BTAPIClientHTTPTypeGraphQLAPI,
};

typedef NS_ENUM(NSInteger, BTAPIClientAuthorizationType) {
    BTAPIClientAuthorizationTypeTokenizationKey = 0,
    BTAPIClientAuthorizationTypeClientToken,
    BTAPIClientAuthorizationTypePayPalIDToken,
};

@interface BTAPIClient ()

@property (nonatomic, copy, nullable) NSString *tokenizationKey;
@property (nonatomic, strong, nullable) BTClientToken *clientToken;
@property (nonatomic, strong, nullable) BTPayPalIDToken *payPalIDToken;
@property (nonatomic, strong) BTHTTP *http;
@property (nonatomic, strong) BTHTTP *configurationHTTP;
@property (nonatomic, strong) BTAPIHTTP *braintreeAPI;
@property (nonatomic, strong) BTGraphQLHTTP *graphQL;

/**
 Client metadata that is used for tracking the client session
*/
@property (nonatomic, readonly, strong) BTClientMetadata *metadata;

/**
 Exposed for testing analytics
*/
@property (nonatomic, strong) BTAnalyticsService *analyticsService;

/**
 True if the FPTI framework is present.
 */
@property (nonatomic, readonly, assign) BOOL isFPTIAvailable;

/**
 Tracks an event through Arachne. Use `queueAnalyticsEvent` for low priority Arachne events.
 @param eventName The event to track.
*/
- (void)sendAnalyticsEvent:(NSString *)eventName;

/**
 Tracks an event through the FPTI system.

 @param eventName The event to track.
 @param additionalData Additional data passed along with the event.
*/
- (void)sendFPTIEvent:(NSString *)eventName with:(NSDictionary<NSString *, id> *)additionalData;

/**
 Tracks an event through both FPTI and Arachne.

 @param eventName The event to track.
 @param additionalData Additional data passed along with the event.
*/
- (void)sendSDKEvent:(NSString *)eventName with:(NSDictionary *)additionalData;

/**
 Queues a low priority event through Arachne.
 @param eventName The event to track.
 */
- (void)queueAnalyticsEvent:(NSString *)eventName;

/**
 An internal initializer to toggle whether to send an analytics event during initialization.
 This prevents copyWithSource:integration: from sending a duplicate event. It can also be used to suppress excessive network chatter during testing.
*/
- (nullable instancetype)initWithAuthorization:(NSString *)authorization sendAnalyticsEvent:(BOOL)sendAnalyticsEvent;

- (void)GET:(NSString *)path
 parameters:(nullable NSDictionary <NSString *, NSString *> *)parameters
 httpType:(BTAPIClientHTTPType)httpType
 completion:(nullable void(^)(BTJSON * _Nullable body, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionBlock;

- (void)POST:(NSString *)path
  parameters:(nullable NSDictionary *)parameters
  httpType:(BTAPIClientHTTPType)httpType
  completion:(nullable void(^)(BTJSON * _Nullable body, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completionBlock;

/**
 Gets base GraphQL URL
*/
+ (nullable NSURL *)graphQLURLForEnvironment:(NSString *)environment;

/**
 Determines the BTAPIClientAuthorizationType of the given authorization string.  Exposed for testing.
 */
+ (BTAPIClientAuthorizationType)authorizationTypeForAuthorization:(NSString *)authorization;

@end

NS_ASSUME_NONNULL_END
