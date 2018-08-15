#import "BTLocalPaymentResult.h"
#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

@implementation BTLocalPaymentResult

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
                    isDefault:(BOOL)isDefault
{
    if (self = [super init]) {
        _nonce = nonce;
        _localizedDescription = description;
        _type = @"LocalPayment";
        _isDefault = isDefault;
        _email = email;
        _firstName = firstName;
        _lastName = lastName;
        _phone = phone;
        _billingAddress = [billingAddress copy];
        _shippingAddress = [shippingAddress copy];
        _clientMetadataId = clientMetadataId;
        _payerId = payerId;
    }
    return self;
}

@end
