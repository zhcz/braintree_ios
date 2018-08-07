#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif
#import "BTPaymentFlowDriver.h"

NS_ASSUME_NONNULL_BEGIN

@interface BTPaymentFlowDriver (LocalPayment_Internal)

- (void)checkStatus:(NSString *)paymentId completion:(void (^)(BTPaymentFlowResult * _Nullable result, NSError * _Nullable error))completionBlock;

@end

NS_ASSUME_NONNULL_END
