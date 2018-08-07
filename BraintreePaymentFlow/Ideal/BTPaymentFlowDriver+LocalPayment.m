#import "BTPaymentFlowDriver+LocalPayment.h"
#import "BTConfiguration+LocalPayment.h"
#import "BTAPIClient_Internal.h"
#import "BTPaymentFlowDriver_Internal.h"
#import "BTLocalPaymentResult.h"

@implementation BTPaymentFlowDriver (LocalPayment)

- (void)checkStatus:(__unused NSString *)paymentId completion:(__unused void (^)(__unused BTPaymentFlowResult *result, __unused NSError *error))completionBlock {
    // TODO
}

@end
