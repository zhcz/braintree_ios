#import "BTVisaCheckoutCardNonce.h"
#import "BTJSON.h"

@implementation BTVisaCheckoutCardNonce

- (instancetype)initWithNonce:(NSString *)nonce
                  description:(NSString *)description
                      lastTwo:(NSString *)lastTwo
                     cardType:(NSString *)type
                    isDefault:(BOOL)isDefault
     shippingAddressFirstName:(NSString *)shippingAddressFirstName
      shippingAddressLastName:(NSString *)shippingAddressLastName
 shippingAddressStreetAddress:(NSString *)shippingAddressStreetAddress
      shippingAddressLocality:(NSString *)shippingAddressLocality
        shippingAddressRegion:(NSString *)shippingAddressRegion
    shippingAddressPostalCode:(NSString *)shippingAddressPostalCode
   shippingAddressCountryCode:(NSString *)shippingAddressCountryCode
     billingAddressFirstName:(NSString *)billingAddressFirstName
      billingAddressLastName:(NSString *)billingAddressLastName
 billingAddressStreetAddress:(NSString *)billingAddressStreetAddress
      billingAddressLocality:(NSString *)billingAddressLocality
        billingAddressRegion:(NSString *)billingAddressRegion
    billingAddressPostalCode:(NSString *)billingAddressPostalCode
   billingAddressCountryCode:(NSString *)billingAddressCountryCode
            userDataFirstName:(NSString *)userDataFirstName
             userDataLastName:(NSString *)userDataLastName
             userDataFullName:(NSString *)userDataFullName
                 userDataName:(NSString *)userDataName
                userDataEmail:(NSString *)userDataEmail {
    if (self = [super initWithNonce:nonce
               localizedDescription:description
                               type:type
                          isDefault:isDefault]) {
        _lastTwo = lastTwo;
        _shippingAddressFirstName = shippingAddressFirstName;
        _shippingAddressLastName = shippingAddressLastName;
        _shippingAddressStreetAddress = shippingAddressStreetAddress;
        _shippingAddressLocality = shippingAddressLocality;
        _shippingAddressRegion = shippingAddressRegion;
        _shippingAddressPostalCode = shippingAddressPostalCode;
        _shippingAddressCountryCode = shippingAddressCountryCode;
        _billingAddressFirstName = billingAddressFirstName;
        _billingAddressLastName = billingAddressLastName;
        _billingAddressStreetAddress = billingAddressStreetAddress;
        _billingAddressLocality = billingAddressLocality;
        _billingAddressRegion = billingAddressRegion;
        _billingAddressPostalCode = billingAddressPostalCode;
        _billingAddressCountryCode = billingAddressCountryCode;
        _userDataFirstName = userDataFirstName;
        _userDataLastName = userDataLastName;
        _userDataFullName = userDataFullName;
        _userDataName = userDataName;
        _userDataEmail = userDataEmail;
    }
    return self;
}

+ (instancetype)visaCheckoutCardNonceWithJSON:(BTJSON *)visaCheckoutJSON {
    NSDictionary *details = [visaCheckoutJSON[@"details"] asDictionary];
    NSDictionary *shippingAddress = [visaCheckoutJSON[@"shippingAddress"] asDictionary];
    NSDictionary *billingAddress = [visaCheckoutJSON[@"billingAddress"] asDictionary];
    NSDictionary *userData = [visaCheckoutJSON[@"userData"] asDictionary];
    
    return [[[self class] alloc] initWithNonce:[visaCheckoutJSON[@"nonce"] asString]
                                   description:[visaCheckoutJSON[@"description"] asString]
                                       lastTwo:details[@"lastTwo"]
                                      cardType:details[@"cardType"]
                                     isDefault:[visaCheckoutJSON[@"default"] isTrue]
                      shippingAddressFirstName:shippingAddress[@"firstName"]
                       shippingAddressLastName:shippingAddress[@"lastName"]
                  shippingAddressStreetAddress:shippingAddress[@"streetAddress"]
                       shippingAddressLocality:shippingAddress[@"locality"]
                         shippingAddressRegion:shippingAddress[@"region"]
                     shippingAddressPostalCode:shippingAddress[@"postalCode"]
                    shippingAddressCountryCode:shippingAddress[@"countryCode"]
                      billingAddressFirstName:billingAddress[@"firstName"]
                       billingAddressLastName:billingAddress[@"lastName"]
                  billingAddressStreetAddress:billingAddress[@"streetAddress"]
                       billingAddressLocality:billingAddress[@"locality"]
                         billingAddressRegion:billingAddress[@"region"]
                     billingAddressPostalCode:billingAddress[@"postalCode"]
                    billingAddressCountryCode:billingAddress[@"countryCode"]
                             userDataFirstName:userData[@"userFirstName"]
                              userDataLastName:userData[@"userLastName"]
                              userDataFullName:userData[@"userFullName"]
                                  userDataName:userData[@"userName"]
                                 userDataEmail:userData[@"userEmail"]];
}

@end
