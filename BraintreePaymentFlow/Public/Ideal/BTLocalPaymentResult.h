#import <Foundation/Foundation.h>
#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif
#import "BTPaymentFlowResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The result of an LocalPayment payment flow
 */
@interface BTLocalPaymentResult : BTPaymentFlowResult

/**
 Payer's email address
 */
@property (nonatomic, nullable, readonly, copy) NSString *email;

/**
 Payer's first name.
 */
@property (nonatomic, nullable, readonly, copy) NSString *firstName;

/**
 Payer's last name.
 */
@property (nonatomic, nullable, readonly, copy) NSString *lastName;

/**
 Payer's phone number.
 */
@property (nonatomic, nullable, readonly, copy) NSString *phone;

/**
 The billing address.
 */
@property (nonatomic, nullable, readonly, strong) BTPostalAddress *billingAddress;

/**
 The shipping address.
 */
@property (nonatomic, nullable, readonly, strong) BTPostalAddress *shippingAddress;

/**
 Client Metadata Id associated with this transaction.
 */
@property (nonatomic, nullable, readonly, copy) NSString *clientMetadataId;

/**
 Optional. Payer Id associated with this transaction.
 */
@property (nonatomic, nullable, readonly, copy) NSString *payerId;

/**
 The one-time use payment method nonce
 */
@property (nonatomic, readonly, copy) NSString *nonce;

/**
 A localized description of the payment info
 */
@property (nonatomic, readonly, copy) NSString *localizedDescription;

/**
 The type of the tokenized data, e.g. PayPal, Venmo, MasterCard, Visa, Amex
 */
@property (nonatomic, readonly, copy) NSString *type;

/**
 True if this nonce is the customer's default payment method, otherwise false.
 */
@property (nonatomic, readonly, assign) BOOL isDefault;

- (instancetype)initWithNonce:(NSString *)nonce
                  description:(NSString *)description
                        email:(NSString *)email
                    firstName:(NSString *)firstName
                     lastName:(NSString *)lastName
                        phone:(NSString *)phone
               billingAddress:(BTPostalAddress *)billingAddress
              shippingAddress:(BTPostalAddress *)shippingAddress
             clientMetadataId:(NSString *)clientMetadataId
                      payerId:(NSString *)payerId
                    isDefault:(BOOL)isDefault;

@end

NS_ASSUME_NONNULL_END
