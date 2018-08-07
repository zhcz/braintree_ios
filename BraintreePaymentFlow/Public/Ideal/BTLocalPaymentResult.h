#import <Foundation/Foundation.h>
#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif
#import "BTPaymentFlowResult.h"

// TODO 
/**
 The result of an LocalPayment payment flow
 */
@interface BTLocalPaymentResult : BTPaymentFlowResult

/**
 The status of the LocalPayment payment. Possible values are [PENDING, COMPLETE, FAILED].
 */
@property (nonatomic, copy) NSString *status;

/**
 The identifier for the LocalPayment payment.
 */
@property (nonatomic, copy) NSString *idealId;

/**
 A shortened form of the identifier for the LocalPayment payment.
 */
@property (nonatomic, copy) NSString *shortIdealId;

@end
