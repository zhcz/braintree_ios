#import <Foundation/Foundation.h>
#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BTVisaCheckoutCardNonce : BTPaymentMethodNonce

/*!
 @brief The last two numbers on the payer's credit card.
 */
@property (nonatomic, nullable, readonly, copy) NSString *lastTwo;

/*!
 @brief First name for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressFirstName;

/*!
 @brief LastName for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressLastName;

/*!
 @brief Street address for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressStreetAddress;

/*!
 @brief Locality for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressLocality;

/*!
 @brief Region for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressRegion;

/*!
 @brief Postal code for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressPostalCode;

/*!
 @brief Country code for the shipping address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *shippingAddressCountryCode;

/*!
 @brief First name for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressFirstName;

/*!
 @brief LastName for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressLastName;

/*!
 @brief Street address for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressStreetAddress;

/*!
 @brief Locality for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressLocality;

/*!
 @brief Region for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressRegion;

/*!
 @brief Postal code for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressPostalCode;

/*!
 @brief Country code for the billing address.
 */
@property (nonatomic, nullable, readonly, copy) NSString *billingAddressCountryCode;


/*!
 @brief The user's first name.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userDataFirstName;

/*!
 @brief The user's last name.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userDataLastName;

/*!
 @brief The user's full name.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userDataFullName;

/*!
 @brief The user's username.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userDataName;

/*!
 @brief The user's email.
 */
@property (nonatomic, nullable, readonly, copy) NSString *userDataEmail;

/*!
 @brief Create a `BTVisaCheckoutCardNonce` object from JSON.
 */
+ (instancetype)visaCheckoutCardNonceWithJSON:(BTJSON *)visaCheckoutJSON;

@end

NS_ASSUME_NONNULL_END
